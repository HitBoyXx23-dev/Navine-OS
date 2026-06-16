param(
    [string]$BuildDir = "build"
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $scriptDir
$buildPath = Join-Path $root $BuildDir
$imgPath = Join-Path $buildPath "navine.img"
$isoPath = Join-Path $buildPath "Navine OS.iso"

if (-not (Test-Path $imgPath)) {
    throw "Missing $imgPath - run build.bat first"
}

Write-Host ""
Write-Host "Navine OS USB boot options:"
Write-Host ""
Write-Host "Option A (recommended): Write navine.img with Rufus"
Write-Host "  1. Download Rufus from https://rufus.ie/"
Write-Host "  2. Device: select your USB drive"
Write-Host "  3. Boot selection: DD Image -> $imgPath"
Write-Host "  4. Partition scheme: MBR, Target: BIOS or UEFI"
Write-Host "  5. Start"
Write-Host ""
Write-Host "Option B: Write Navine OS.iso with Rufus DD mode"
Write-Host "  Use Rufus DD Image mode with: $isoPath"
Write-Host ""
Write-Host "Option C: PowerShell (admin, replace X: with USB drive letter)"
Write-Host "  WARNING: destroys all data on the target drive"
Write-Host "  `$usb = Get-Disk | Where-Object { `$_.BusType -eq 'USB' -and `$_.Size -ge 32MB }"
Write-Host "  Clear-Disk -Number `$usb.Number -RemoveData -Confirm:`$false"
Write-Host "  `$stream = [IO.File]::OpenRead('$imgPath')"
Write-Host "  `$target = [IO.File]::OpenWrite('\\.\PhysicalDrive' + `$usb.Number)"
Write-Host "  `$stream.CopyTo(`$target); `$stream.Close(); `$target.Close()"
Write-Host ""
