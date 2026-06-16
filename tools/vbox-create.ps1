param(
    [string]$BuildDir = "build",
    [string]$VmName = "Navine OS"
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $scriptDir
$buildPath = Join-Path $root $BuildDir
$imgPath = (Resolve-Path (Join-Path $buildPath "navine.img")).Path
$vdiPath = Join-Path $buildPath "navine.vdi"

$vboxManage = $null
foreach ($candidate in @(
    "${env:ProgramFiles}\Oracle\VirtualBox\VBoxManage.exe",
    "${env:ProgramFiles(x86)}\Oracle\VirtualBox\VBoxManage.exe"
)) {
    if (Test-Path $candidate) { $vboxManage = $candidate; break }
}

if ($null -eq $vboxManage) {
    Write-Host "VirtualBox not found. Install from https://www.virtualbox.org/"
    exit 0
}

if (-not (Test-Path $imgPath)) {
    throw "Missing $imgPath - run build.bat first"
}

$vboxDir = Split-Path -Parent $vboxManage
$hostDates = @()
foreach ($name in @("VMMR0.r0", "VBoxDD.dll")) {
    $f = Join-Path $vboxDir $name
    if (Test-Path $f) { $hostDates += (Get-Item $f).LastWriteTime.Date }
}
$driverDates = Get-ChildItem "C:\Windows\System32\drivers\VBox*.sys" -ErrorAction SilentlyContinue |
    ForEach-Object { $_.LastWriteTime.Date }
$allDates = ($hostDates + $driverDates) | Sort-Object -Unique
$driversBroken = $allDates.Count -gt 1

if ($driversBroken) {
    Write-Host "WARNING: VirtualBox drivers mismatched - reinstall VirtualBox if VM fails to start."
    Write-Host "  powershell -File tools\vbox-repair.ps1"
    Write-Host ""
}

$prevEap = $ErrorActionPreference
$ErrorActionPreference = 'SilentlyContinue'
& $vboxManage controlvm $VmName poweroff 2>&1 | Out-Null
& $vboxManage unregistervm $VmName --delete 2>&1 | Out-Null
$ErrorActionPreference = $prevEap

$vmFolder = Join-Path $env:USERPROFILE "VirtualBox VMs\$VmName"
if (Test-Path $vmFolder) {
    Remove-Item -LiteralPath $vmFolder -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "Creating VirtualBox disk from navine.img..."
if (Test-Path $vdiPath) { Remove-Item -LiteralPath $vdiPath -Force }
& $vboxManage convertfromraw $imgPath $vdiPath --format VDI --variant Fixed
if ($LASTEXITCODE -ne 0) { throw "VBoxManage convertfromraw failed (exit $LASTEXITCODE)" }
for ($i = 0; $i -lt 20; $i++) {
    if ((Test-Path -LiteralPath $vdiPath) -and ((Get-Item -LiteralPath $vdiPath).Length -gt 1MB)) { break }
    Start-Sleep -Milliseconds 250
}
if (-not (Test-Path -LiteralPath $vdiPath)) { throw "VDI was not created: $vdiPath" }
Write-Host "  $vdiPath ($((Get-Item -LiteralPath $vdiPath).Length) bytes)"

Write-Host "Creating VM: $VmName"
& $vboxManage createvm --name $VmName --ostype Other_64 --register
if ($LASTEXITCODE -ne 0) { throw "createvm failed" }

& $vboxManage modifyvm $VmName --memory 512 --vram 128 --graphicscontroller vboxvga --firmware bios --chipset piix3 --ioapic on --pae on --longmode on --hwvirtex on --nestedpaging on --rtcuseutc on --mouse ps2 --boot1 disk --boot2 none --boot3 none --boot4 none --audio-driver none --accelerate3d off | Out-Null

& $vboxManage storagectl $VmName --name "IDE" --add ide --controller PIIX4 --portcount 2 --bootable on
if ($LASTEXITCODE -ne 0) { throw "storagectl failed" }

Write-Host "Attaching disk: $vdiPath"
& $vboxManage storageattach $VmName --storagectl "IDE" --port 0 --device 0 --type hdd --medium $vdiPath
if ($LASTEXITCODE -ne 0) { throw "storageattach failed" }

& $vboxManage setextradata $VmName "GUI/ScaleFactor" "1" 2>$null | Out-Null
& $vboxManage setextradata $VmName "GUI/LastGuestSizeHint" "1920,1080" 2>$null | Out-Null
& $vboxManage setextradata $VmName "GUI/LastNormalWindowPosition" "0,0,1936,1157" 2>$null | Out-Null

$info = & $vboxManage showvminfo $VmName --machinereadable 2>&1 | Out-String
if ($info -notmatch "navine\.vdi") {
    throw "Disk attachment verification failed - navine.vdi not found in VM config"
}

Write-Host ""
Write-Host "VirtualBox VM ready: $VmName"
Write-Host "  Boot: IDE port 0 -> $vdiPath"
Write-Host "  Start: run-vbox.bat"
Write-Host ""

if ($driversBroken) { exit 2 }
exit 0
