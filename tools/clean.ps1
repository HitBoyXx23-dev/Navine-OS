param(
    [string]$BuildDir = "build"
)

$ErrorActionPreference = "SilentlyContinue"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $scriptDir
$buildPath = Join-Path $root $BuildDir

if (-not (Test-Path $buildPath)) { exit 0 }

$keep = @(
    "navine.img",
    "navine-desktop.img",
    "navine-cli.img",
    "navine.vdi",
    "Navine OS.iso",
    "Navine OS Desktop.iso",
    "Navine OS CLI.iso",
    "Navine OS Linux Desktop.iso",
    "Navine OS Linux CLI.iso",
    "Navine OS Linux.iso",
    "wallpaper.raw",
    "doom1.wad"
)

Get-ChildItem $buildPath -File | Where-Object { $keep -notcontains $_.Name } | Remove-Item -Force
Get-ChildItem $buildPath -Directory | Remove-Item -Recurse -Force

Write-Host "Cleaned intermediate build files in $buildPath"
