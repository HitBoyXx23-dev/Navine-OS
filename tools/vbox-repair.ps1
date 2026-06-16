param(
    [switch]$FixDrivers
)

$ErrorActionPreference = "Continue"

Write-Host "Navine OS - VirtualBox host diagnostics"
Write-Host "======================================="
Write-Host ""

$vboxDir = "${env:ProgramFiles}\Oracle\VirtualBox"
$vboxManage = Join-Path $vboxDir "VBoxManage.exe"

if (-not (Test-Path $vboxManage)) {
    Write-Host "FAIL: VirtualBox not found at $vboxDir"
    Write-Host "Install from https://www.virtualbox.org/wiki/Downloads"
    exit 1
}

$vboxVersion = & $vboxManage --version
Write-Host "VirtualBox version: $vboxVersion"

$hostFiles = @(
    (Join-Path $vboxDir "VMMR0.r0"),
    (Join-Path $vboxDir "VBoxDD.dll")
)

$driverFiles = Get-ChildItem "C:\Windows\System32\drivers\VBox*.sys" -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "Host modules:"
foreach ($f in $hostFiles) {
    if (Test-Path $f) {
        $item = Get-Item $f
        Write-Host ("  {0,-24} {1}" -f $item.Name, $item.LastWriteTime.ToString("yyyy-MM-dd HH:mm"))
    }
}

Write-Host ""
Write-Host "Kernel drivers:"
foreach ($d in $driverFiles) {
    Write-Host ("  {0,-24} {1}" -f $d.Name, $d.LastWriteTime.ToString("yyyy-MM-dd HH:mm"))
}

$dates = @()
foreach ($f in $hostFiles) {
    if (Test-Path $f) { $dates += (Get-Item $f).LastWriteTime.Date }
}
foreach ($d in $driverFiles) {
    $dates += $d.LastWriteTime.Date
}

$uniqueDates = $dates | Sort-Object -Unique
$mismatch = $uniqueDates.Count -gt 1

Write-Host ""
if ($mismatch) {
    Write-Host "PROBLEM: VirtualBox host files and drivers have different dates."
    Write-Host "This causes: VERR_LDR_IMPORTED_SYMBOL_NOT_FOUND / VMMR0.r0 load failure"
    Write-Host ""
    Write-Host "Fix (recommended):"
    Write-Host "  1. Close VirtualBox completely"
    Write-Host "  2. Settings -> Apps -> Uninstall Oracle VirtualBox"
    Write-Host "  3. Reboot Windows"
    Write-Host "  4. Install latest VirtualBox from virtualbox.org"
    Write-Host "  5. Reboot again"
    Write-Host "  6. Re-run build.bat (step 8 recreates the Navine OS VM)"
    Write-Host ""
    Write-Host "Also check:"
    Write-Host "  - Windows Security -> Device security -> Core isolation"
    Write-Host "    Turn OFF Memory integrity, reboot (if reinstall alone fails)"
    Write-Host "  - Disable Hyper-V / Virtual Machine Platform if you only use VirtualBox"
    Write-Host ""
    Write-Host "Boot Navine OS without VirtualBox (while repairing):"
    Write-Host "  USB: Rufus DD mode with build\navine.img"
} else {
    Write-Host "OK: VirtualBox file dates look consistent."
}

Write-Host ""
Write-Host "Driver services:"
foreach ($name in @("VBoxSup", "VBoxUSBMon", "VBoxNetLwf", "VBoxNetAdp6", "VBoxDrv")) {
    $result = sc.exe query $name 2>&1 | Out-String
    if ($result -match "RUNNING") {
        Write-Host "  $name : RUNNING"
    } elseif ($result -match "1060") {
        Write-Host "  $name : not installed"
    } else {
        Write-Host "  $name : $result".Trim()
    }
}

if ($FixDrivers) {
    Write-Host ""
    Write-Host "Attempting driver reload (requires Administrator)..."
    foreach ($name in @("VBoxUSBMon", "VBoxSup", "VBoxNetLwf", "VBoxNetAdp6")) {
        sc.exe stop $name 2>$null | Out-Null
    }
    Start-Sleep -Seconds 2
    foreach ($name in @("VBoxSup", "VBoxUSBMon", "VBoxNetLwf", "VBoxNetAdp6")) {
        sc.exe start $name 2>$null | Out-Null
    }
    Write-Host "Drivers restarted. Try starting the VM again."
    Write-Host "If it still fails, do a full VirtualBox reinstall + reboot."
}

if ($mismatch) { exit 2 }
exit 0
