# ============================================
# Windows Defender Restore Tool
# Emergency Recovery Script
# ============================================

# Check for Administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "ERROR: This script requires Administrator privileges!" -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
    pause
    exit
}

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Windows Defender Restore Tool" -ForegroundColor Cyan
Write-Host "  Emergency Recovery" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This will restore Windows Defender to normal operation." -ForegroundColor Green
Write-Host ""

$confirm = Read-Host "Type 'YES' to continue"

if ($confirm -ne "YES") {
    Write-Host "Operation cancelled." -ForegroundColor Yellow
    exit
}

Write-Host "`n[STEP 1] Enabling Tamper Protection..." -ForegroundColor Yellow
try {
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Defender\Features" -Name "TamperProtection" -Value 1 -Type DWord -ErrorAction SilentlyContinue
    Write-Host "✓ Tamper Protection enabled" -ForegroundColor Green
} catch {
    Write-Host "! Run Windows Security app to manually enable" -ForegroundColor Yellow
}

Write-Host "`n[STEP 2] Restoring Registry Settings..." -ForegroundColor Yellow

# Remove Group Policy restrictions
try {
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableRoutinelyTakingAction" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Defender" -Name "DisableAntiVirus" -ErrorAction SilentlyContinue
} catch {}

# Remove Real-time Protection restrictions
try {
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableBehaviorMonitoring" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableIOAVProtection" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableOnAccessProtection" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableRealtimeMonitoring" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableScanOnRealtimeEnable" -ErrorAction SilentlyContinue
} catch {}

# Remove Spynet restrictions
try {
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" -Name "SpynetReporting" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" -Name "SubmitSamplesConsent" -ErrorAction SilentlyContinue
} catch {}

Write-Host "✓ Registry settings restored" -ForegroundColor Green

Write-Host "`n[STEP 3] Re-enabling Windows Defender Services..." -ForegroundColor Yellow

$services = @(
    "WinDefend",
    "WdNisSvc",
    "SecurityHealthService"
)

foreach ($service in $services) {
    try {
        $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
        if ($svc) {
            Set-Service -Name $service -StartupType Automatic -ErrorAction SilentlyContinue
            Start-Service -Name $service -ErrorAction SilentlyContinue
            Write-Host "  ✓ Enabled: $service" -ForegroundColor Green
        }
    } catch {
        Write-Host "  ! Could not start: $service" -ForegroundColor Yellow
    }
}

Write-Host "`n[STEP 4] Re-enabling Scheduled Tasks..." -ForegroundColor Yellow

$tasks = @(
    "\Microsoft\Windows\Windows Defender\Windows Defender Cache Maintenance",
    "\Microsoft\Windows\Windows Defender\Windows Defender Cleanup",
    "\Microsoft\Windows\Windows Defender\Windows Defender Scheduled Scan",
    "\Microsoft\Windows\Windows Defender\Windows Defender Verification"
)

foreach ($task in $tasks) {
    try {
        $scheduledTask = Get-ScheduledTask -TaskName $task.Split('\')[-1] -ErrorAction SilentlyContinue
        if ($scheduledTask) {
            Enable-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue | Out-Null
            Write-Host "  ✓ Enabled: $task" -ForegroundColor Green
        }
    } catch {
        Write-Host "  - Skipped: $task" -ForegroundColor Gray
    }
}

Write-Host "`n[STEP 5] Restoring SmartScreen..." -ForegroundColor Yellow
try {
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "SmartScreenEnabled" -Value "Warn" -Type String -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableSmartScreen" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "SmartScreenEnabled" -ErrorAction SilentlyContinue
    Write-Host "✓ SmartScreen restored" -ForegroundColor Green
} catch {
    Write-Host "! SmartScreen may require manual restore" -ForegroundColor Yellow
}

Write-Host "`n[STEP 6] Restoring Defender Files..." -ForegroundColor Yellow

# Restore main Defender folder
$backupPath = "$env:ProgramFiles\Windows Defender.disabled"
$defenderPath = "$env:ProgramFiles\Windows Defender"

if (Test-Path $backupPath) {
    try {
        if (Test-Path $defenderPath) {
            Remove-Item -Path $defenderPath -Recurse -Force -ErrorAction Stop
        }
        Rename-Item -Path $backupPath -NewName "Windows Defender" -Force -ErrorAction Stop
        Write-Host "  ✓ Main Defender folder restored" -ForegroundColor Green
    } catch {
        Write-Host "  ! Could not restore Defender folder (may require reboot)" -ForegroundColor Yellow
    }
} else {
    Write-Host "  - No backup folder found" -ForegroundColor Gray
}

# Restore Advanced Threat Protection folder
$advBackupPath = "$env:ProgramData\Microsoft\Windows Defender.disabled"
$advDefenderPath = "$env:ProgramData\Microsoft\Windows Defender"

if (Test-Path $advBackupPath) {
    try {
        if (Test-Path $advDefenderPath) {
            Remove-Item -Path $advDefenderPath -Recurse -Force -ErrorAction Stop
        }
        Rename-Item -Path $advBackupPath -NewName "Windows Defender" -Force -ErrorAction Stop
        Write-Host "  ✓ Defender data folder restored" -ForegroundColor Green
    } catch {
        Write-Host "  ! Could not restore Defender data folder" -ForegroundColor Yellow
    }
} else {
    Write-Host "  - No data backup folder found" -ForegroundColor Gray
}

Write-Host "`n[STEP 7] Enabling Real-time Protection..." -ForegroundColor Yellow
try {
    Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue
    Set-MpPreference -DisableBehaviorMonitoring $false -ErrorAction SilentlyContinue
    Set-MpPreference -DisableBlockAtFirstSeen $false -ErrorAction SilentlyContinue
    Set-MpPreference -DisableIOAVProtection $false -ErrorAction SilentlyContinue
    Set-MpPreference -DisableScriptScanning $false -ErrorAction SilentlyContinue
    Write-Host "✓ Real-time Protection enabled" -ForegroundColor Green
} catch {
    Write-Host "! May require manual activation through Windows Security" -ForegroundColor Yellow
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "  Windows Defender Restore Completed!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "NEXT STEPS:" -ForegroundColor Yellow
Write-Host "  1. REBOOT your system" -ForegroundColor White
Write-Host "  2. Open Windows Security app" -ForegroundColor White
Write-Host "  3. Verify all protection features are active" -ForegroundColor White
Write-Host "  4. Update virus definitions" -ForegroundColor White
Write-Host ""

$reboot = Read-Host "Reboot now? (Y/N)"
if ($reboot -eq "Y" -or $reboot -eq "y") {
    Write-Host "`nRebooting in 10 seconds..." -ForegroundColor Yellow
    Write-Host "Press Ctrl+C to cancel" -ForegroundColor Gray
    Start-Sleep -Seconds 10
    Restart-Computer -Force
} else {
    Write-Host "`nPlease reboot manually to complete the restore process." -ForegroundColor Yellow
    pause
}
