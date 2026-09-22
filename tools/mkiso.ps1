param(
    [string]$BuildDir = "build",
    [string]$DiskImage = "navine.img",
    [string]$IsoName = "Navine OS Desktop.iso"
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $scriptDir
$buildPath = Join-Path $root $BuildDir
$imgPath = Join-Path $buildPath $DiskImage

if (-not (Test-Path $imgPath)) {
    throw "Missing $imgPath - run mkdisk.ps1 first"
}

$python = Get-Command python -ErrorAction SilentlyContinue
if ($null -eq $python) {
    $python = Get-Command python3 -ErrorAction SilentlyContinue
}
if ($null -eq $python) {
    throw "Python required for ISO build"
}

& $python.Source (Join-Path $scriptDir "mkiso_eltorito.py") $BuildDir $DiskImage $IsoName
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& $python.Source (Join-Path $scriptDir "verify_iso.py") $BuildDir $IsoName $DiskImage
exit $LASTEXITCODE
