param(
    [string]$BuildDir = "build",
    [string]$Profile = ""
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $scriptDir
$wadsDir = Join-Path $root "apps\doom\wads"
$configPath = Join-Path $root "apps\doom\wad.config"

if (-not (Test-Path $wadsDir)) {
    New-Item -ItemType Directory -Path $wadsDir | Out-Null
}

if (-not $Profile -and (Test-Path $configPath)) {
    $Profile = (Get-Content $configPath -Raw).Trim()
}
if (-not $Profile) { $Profile = "squashware" }

$squashwareAssets = @{
    "squashware"       = @{ Zip = "squashware-1.3.zip";       Wad = "newdoom1.wad" }
    "squashware-1lev"  = @{ Zip = "squashware-1lev-1.3.zip";  Wad = "newdoom1_1lev.wad" }
    "squashware-silent"= @{ Zip = "squashware-silent-1.3.zip"; Wad = "newdoom1_silent.wad" }
}

function Copy-AsDoom1([string]$SourcePath) {
    $dest = Join-Path $wadsDir "doom1.wad"
    Copy-Item -Force $SourcePath $dest
    $size = (Get-Item $dest).Length
    Write-Host "WAD ready: $dest ($size bytes)"
    return $dest
}

if ($Profile -eq "custom") {
    $custom = @(
        (Join-Path $wadsDir "doom1.wad"),
        (Join-Path $wadsDir "DOOM.WAD"),
        (Join-Path $wadsDir "doom2.wad"),
        (Join-Path $wadsDir "DOOM2.WAD"),
        (Join-Path $root "apps\doom\doom1.wad")
    )
    foreach ($p in $custom) {
        if (Test-Path $p) {
            if ($p -notlike "*\doom1.wad") {
                Copy-AsDoom1 $p | Out-Null
            } else {
                Write-Host "WAD ready: $p ($((Get-Item $p).Length) bytes)"
            }
            exit 0
        }
    }
    Write-Host "wad.config is 'custom' but no WAD found in apps\doom\wads\"
    Write-Host "Place doom1.wad, DOOM.WAD, or doom2.wad there (you must own the game)."
    exit 1
}

if ($squashwareAssets.ContainsKey($Profile)) {
    $asset = $squashwareAssets[$Profile]
    $cached = Join-Path $wadsDir $asset.Wad
    if (Test-Path $cached) {
        Copy-AsDoom1 $cached | Out-Null
        exit 0
    }

    $releaseUrl = "https://github.com/fragglet/squashware/releases/download/squashware-1.3/$($asset.Zip)"
    $zipPath = Join-Path $wadsDir $asset.Zip
    Write-Host "Downloading Squashware WAD ($Profile) from fragglet/squashware..."
    Invoke-WebRequest -Uri $releaseUrl -OutFile $zipPath -UseBasicParsing

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $extractDir = Join-Path $wadsDir "_extract"
    if (Test-Path $extractDir) { Remove-Item -Recurse -Force $extractDir }
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $extractDir)

    $found = Get-ChildItem -Path $extractDir -Filter $asset.Wad -Recurse | Select-Object -First 1
    if (-not $found) {
        throw "Expected $($asset.Wad) inside $releaseUrl"
    }
    Copy-Item -Force $found.FullName $cached
    Remove-Item -Recurse -Force $extractDir
    Copy-AsDoom1 $cached | Out-Null
    exit 0
}

Write-Host "Unknown wad.config profile: $Profile"
Write-Host "Valid: squashware, squashware-1lev, squashware-silent, custom"
exit 1
