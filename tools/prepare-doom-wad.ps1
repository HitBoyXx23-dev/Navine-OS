param(
    [string]$BuildDir = "build"
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $scriptDir
$buildPath = Join-Path $root $BuildDir
$includePath = Join-Path $root "include\doom_wad.inc"

$wadSources = @(
    (Join-Path $root "apps\doom\wads\doom1.wad"),
    (Join-Path $buildPath "doom1.wad"),
    (Join-Path $root "apps\doom\doom1.wad")
)

$wadPath = $null
foreach ($p in $wadSources) {
    if (Test-Path $p) { $wadPath = $p; break }
}

if (-not $wadPath) {
    @"
%ifndef DOOM_WAD_INC
%define DOOM_WAD_INC
%define DOOM_WAD_SECTORS     0
%define DOOM_WAD_BYTES       0
%endif
"@ | Set-Content -Path $includePath -Encoding ASCII
    Write-Host "No WAD embedded (run fetch-doom-wad or add apps\doom\wads\doom1.wad)"
    exit 0
}

$bytes = (Get-Item $wadPath).Length
$sectors = [int][Math]::Ceiling($bytes / 512.0)
$dest = Join-Path $buildPath "doom1.wad"
Copy-Item -Force $wadPath $dest

@"
%ifndef DOOM_WAD_INC
%define DOOM_WAD_INC
%define DOOM_WAD_SECTORS     $sectors
%define DOOM_WAD_BYTES       $bytes
%endif
"@ | Set-Content -Path $includePath -Encoding ASCII

Write-Host "Prepared $dest ($bytes bytes, $sectors sectors)"
