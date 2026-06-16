param(
    [string]$BuildDir = "build"
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $scriptDir
$buildPath = Join-Path $root $BuildDir
$imgPath = Join-Path $buildPath "navine.img"

if (-not (Test-Path $imgPath)) {
    throw "Missing $imgPath - run build.bat first"
}

$python = Get-Command python -ErrorAction SilentlyContinue
if ($null -eq $python) {
    $python = Get-Command python3 -ErrorAction SilentlyContinue
}
if ($null -eq $python) {
    throw "Python required for ISO build"
}

& $python.Source (Join-Path $scriptDir "mkiso_eltorito.py") $BuildDir
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& $python.Source (Join-Path $scriptDir "verify_iso.py") $BuildDir
exit $LASTEXITCODE
