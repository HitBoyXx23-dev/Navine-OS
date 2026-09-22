param(
    [string]$Iso = "",
    [string]$DiskImage = "",
    [Parameter(Mandatory = $true)][string]$OutPng,
    [int]$BootSeconds = 30,
    [int]$MemoryMB = 512,
    [int]$MonitorPort = 55832,
    [string]$SerialLog = ""
)

$ErrorActionPreference = "Stop"

$qemu = Join-Path $env:USERPROFILE "scoop\apps\qemu\current\qemu-system-x86_64.exe"
if (-not (Test-Path $qemu)) { throw "QEMU not found at $qemu" }
if (-not $Iso -and -not $DiskImage) { throw "Provide either -Iso or -DiskImage" }

$bootLabel = ""
if ($Iso) {
    if (-not (Test-Path $Iso)) { throw "ISO not found: $Iso" }
    $Iso = (Resolve-Path $Iso).Path
    $bootLabel = Split-Path $Iso -Leaf
}
if ($DiskImage) {
    if (-not (Test-Path $DiskImage)) { throw "Disk image not found: $DiskImage" }
    $DiskImage = (Resolve-Path $DiskImage).Path
    $bootLabel = Split-Path $DiskImage -Leaf
}

$OutPng = [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $OutPng))
if ($SerialLog) { $SerialLog = [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $SerialLog)) }

$ppm = [System.IO.Path]::ChangeExtension($OutPng, ".ppm")
foreach ($f in @($ppm, $OutPng, $SerialLog)) {
    if ($f -and (Test-Path $f)) { Remove-Item $f -Force }
}

$qemuArgs = @(
    "-m", "$MemoryMB",
    "-vga", "std",
    "-display", "none",
    "-monitor", "tcp:127.0.0.1:$MonitorPort,server,nowait",
    "-no-reboot"
)
if ($Iso)       { $qemuArgs += @("-cdrom", "`"$Iso`"", "-boot", "d") }
if ($DiskImage) { $qemuArgs += @("-drive", "file=`"$DiskImage`",format=raw,if=ide", "-boot", "c") }
if ($SerialLog) { $qemuArgs += @("-serial", "file:`"$SerialLog`"") }

Write-Host "Booting $bootLabel, capturing after $BootSeconds seconds..."

$proc = Start-Process -FilePath $qemu -ArgumentList $qemuArgs -PassThru -WindowStyle Hidden
Start-Sleep -Seconds $BootSeconds

if ($proc.HasExited) {
    throw "QEMU exited early with code $($proc.ExitCode)"
}

function Invoke-Monitor([string]$Command, [int]$Port) {
    $client = New-Object System.Net.Sockets.TcpClient
    $client.Connect("127.0.0.1", $Port)
    $stream = $client.GetStream()
    $writer = New-Object System.IO.StreamWriter($stream)
    $writer.AutoFlush = $true
    Start-Sleep -Milliseconds 500
    $writer.WriteLine($Command)
    Start-Sleep -Seconds 3
    $writer.WriteLine("quit")
    Start-Sleep -Milliseconds 500
    $writer.Dispose()
    $client.Close()
}

Invoke-Monitor -Command "screendump `"$($ppm.Replace('\','/'))`"" -Port $MonitorPort

if (-not $proc.WaitForExit(20000)) { $proc.Kill() }

if (-not (Test-Path $ppm)) { throw "Screendump failed; no framebuffer captured" }

$ffmpeg = Join-Path $env:USERPROFILE "scoop\shims\ffmpeg.exe"
if (Test-Path $ffmpeg) {
    & $ffmpeg -loglevel error -y -i $ppm $OutPng
    Remove-Item $ppm -Force
    Write-Host "Screenshot: $OutPng"
} else {
    Write-Host "Screenshot (PPM, ffmpeg unavailable): $ppm"
}

if ($SerialLog -and (Test-Path $SerialLog)) {
    Write-Host "--- serial console (tail) ---"
    Get-Content $SerialLog -Tail 30
}
