param(
    [string]$BuildDir = "build",
    [string]$KernelName = "kernel.bin",
    [string]$OutputImg = "navine.img"
)

$ErrorActionPreference = "Stop"
$Sector = 512
$Stage2Sectors = 32
$KernelLba = 34
$DoomBinLba = 8192
$DoomWadLba = 9216
$NavAppLba = 30000
$WallpaperLba = 12800
$TotalSectors = 71680

function Read-PaddedFile([string]$Path, [int]$Size) {
    [byte[]]$data = [System.IO.File]::ReadAllBytes($Path)
    if ($data.Length -gt $Size) {
        throw "File $Path exceeds $Size bytes ($($data.Length) > $Size)"
    }
    if ($data.Length -lt $Size) {
        [byte[]]$padded = New-Object byte[] $Size
        [System.Array]::Copy($data, $padded, $data.Length)
        return $padded
    }
    return $data
}

function Set-MbrPartition([byte[]]$Sector0, [uint32]$TotalSectors) {
    if ($Sector0.Length -lt 512) {
        throw "MBR sector must be 512 bytes"
    }
    if ($Sector0[510] -ne 0x55 -or $Sector0[511] -ne 0xAA) {
        throw "Missing MBR boot signature 0xAA55"
    }

    $entryOffset = 446
    $entry = New-Object byte[] 16

    $entry[0] = 0x80
    $entry[1] = 0x00
    $entry[2] = 0x02
    $entry[3] = 0x00
    $entry[4] = 0x83
    $entry[5] = 0xFE
    $entry[6] = 0xFF
    $entry[7] = 0xFF

    $startLba = [uint32]1
    $count = [uint32]($TotalSectors - 1)
    [BitConverter]::GetBytes($startLba).CopyTo($entry, 8)
    [BitConverter]::GetBytes($count).CopyTo($entry, 12)

    [Array]::Copy($entry, 0, $Sector0, $entryOffset, 16)
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $scriptDir
$buildPath = Join-Path $root $BuildDir

$stage1Path = Join-Path $buildPath "stage1.bin"
$stage2Path = Join-Path $buildPath "stage2.bin"
$kernelPath = Join-Path $buildPath $KernelName

if (-not (Test-Path $stage1Path)) { throw "Missing $stage1Path" }
if (-not (Test-Path $stage2Path)) { throw "Missing $stage2Path" }
if (-not (Test-Path $kernelPath)) { throw "Missing $kernelPath" }

[byte[]]$stage1 = Read-PaddedFile $stage1Path $Sector
Set-MbrPartition $stage1 $TotalSectors

[byte[]]$stage2 = Read-PaddedFile $stage2Path ($Stage2Sectors * $Sector)
[byte[]]$kernel = [System.IO.File]::ReadAllBytes($kernelPath)

$img = New-Object System.Collections.Generic.List[byte]
foreach ($b in $stage1) { [void]$img.Add($b) }
foreach ($b in (New-Object byte[] $Sector)) { [void]$img.Add($b) }
foreach ($b in $stage2) { [void]$img.Add($b) }

$kernelOffset = $KernelLba * $Sector
while ($img.Count -lt $kernelOffset) {
    [void]$img.Add(0)
}
foreach ($b in $kernel) { [void]$img.Add($b) }

$doomBinPath = Join-Path $buildPath "doom.bin"
if (Test-Path $doomBinPath) {
    [byte[]]$doomBin = [System.IO.File]::ReadAllBytes($doomBinPath)
    $doomOffset = $DoomBinLba * $Sector
    while ($img.Count -lt $doomOffset) { [void]$img.Add(0) }
    foreach ($b in $doomBin) { [void]$img.Add($b) }
    Write-Host "Embedded DOOM binary at LBA $DoomBinLba ($($doomBin.Length) bytes)"
}

$wadPath = Join-Path $buildPath "doom1.wad"
if (Test-Path $wadPath) {
    [byte[]]$wad = [System.IO.File]::ReadAllBytes($wadPath)
    $wadOffset = $DoomWadLba * $Sector
    while ($img.Count -lt $wadOffset) { [void]$img.Add(0) }
    foreach ($b in $wad) { [void]$img.Add($b) }
    Write-Host "Embedded WAD at LBA $DoomWadLba ($($wad.Length) bytes)"
} else {
    Write-Host "No WAD on disk - run tools\fetch-doom-wad.ps1"
}

$wallpaperPath = Join-Path $buildPath "wallpaper.raw"
if (Test-Path $wallpaperPath) {
    [byte[]]$wallpaper = Read-PaddedFile $wallpaperPath (16200 * $Sector)
    $wallpaperOffset = $WallpaperLba * $Sector
    while ($img.Count -lt $wallpaperOffset) { [void]$img.Add(0) }
    foreach ($b in $wallpaper) { [void]$img.Add($b) }
    Write-Host "Embedded wallpaper at LBA $WallpaperLba ($($wallpaper.Length) bytes)"
}

$navAppPath = Join-Path $buildPath "system.bin"
if (Test-Path $navAppPath) {
    [byte[]]$navApp = Read-PaddedFile $navAppPath (256 * $Sector)
    $navAppOffset = $NavAppLba * $Sector
    while ($img.Count -lt $navAppOffset) { [void]$img.Add(0) }
    foreach ($b in $navApp) { [void]$img.Add($b) }
    Write-Host "Embedded C++ System app at LBA $NavAppLba ($($navApp.Length) bytes)"
}

while ($img.Count -lt ($TotalSectors * $Sector)) {
    [void]$img.Add(0)
}

$imgPath = Join-Path $buildPath $OutputImg
[System.IO.File]::WriteAllBytes($imgPath, $img.ToArray())
Write-Host "Created $imgPath ($($img.Count) bytes, x86-64 bootable MBR)"
