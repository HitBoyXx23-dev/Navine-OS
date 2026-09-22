param(
    [Parameter(Mandatory = $true)][string]$Tag,
    [string]$Repo = "HitBoyXx23-dev/Navine-OS",
    [string]$BuildDir = "build",
    [string]$Title = ""
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
if (-not $Title) { $Title = "Navine OS $Tag" }

$buildPath = Join-Path $root $BuildDir
$upload = @(
    ((Join-Path $buildPath "Navine OS Linux Desktop.iso") + "#Navine-OS-Linux-Desktop.iso"),
    ((Join-Path $buildPath "Navine OS Linux CLI.iso") + "#Navine-OS-Linux-CLI.iso"),
    ((Join-Path $buildPath "Navine OS Desktop.iso") + "#Navine-OS-Desktop.iso"),
    ((Join-Path $buildPath "Navine OS CLI.iso") + "#Navine-OS-CLI.iso")
)

foreach ($entry in $upload) {
    $path = ($entry -split '#')[0]
    if (-not (Test-Path $path)) { throw "Missing $path" }
    Write-Host "Ready: $entry ($([math]::Round((Get-Item $path).Length/1MB,1)) MB)"
}

$notes = Join-Path $root "RELEASE_NOTES.md"
$ErrorActionPreference = "Continue"
gh release view $Tag -R $Repo 2>$null | Out-Null
$viewExit = $LASTEXITCODE
$ErrorActionPreference = "Stop"
if ($viewExit -eq 0) {
    Write-Host "Release $Tag exists; uploading assets..."
    gh release upload $Tag @upload -R $Repo --clobber
} else {
    gh release create $Tag @upload -R $Repo --title $Title --notes-file $notes
}

Write-Host "Done: https://github.com/$Repo/releases/tag/$Tag"
