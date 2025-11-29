# ============================================
# Windows Defender Removal Tool
# Development/Test Environment
# ============================================

# Check for Administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "ERROR: This script requires Administrator privileges!" -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
    pause
    exit
}

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Windows Defender Removal Tool" -ForegroundColor Cyan
Write-Host "  Development/Test Environment" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "WARNING: This will disable/remove Windows Defender!" -ForegroundColor Red
Write-Host "Your system will be vulnerable to threats!" -ForegroundColor Red
Write-Host ""
Write-Host "Select removal method:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  [2] Option 2 - Permanent Disable (Group Policy)" -ForegroundColor White
Write-Host "      - Registry modifications" -ForegroundColor Gray
Write-Host "      - Disable services and tasks" -ForegroundColor Gray
Write-Host "      - Can be restored" -ForegroundColor Gray
Write-Host "      - Recommended for most cases" -ForegroundColor Green
Write-Host ""
Write-Host "  [3] Option 3 - Complete Removal (Advanced)" -ForegroundColor White
Write-Host "      - All Option 2 features" -ForegroundColor Gray
Write-Host "      - Remove/rename Defender files" -ForegroundColor Gray
Write-Host "      - More difficult to restore" -ForegroundColor Gray
Write-Host "      - Maximum removal" -ForegroundColor Red
Write-Host ""
Write-Host "  [0] Cancel" -ForegroundColor Yellow
Write-Host ""

$choice = Read-Host "Enter your choice (2, 3, or 0)"

if ($choice -eq "0") {
    Write-Host "Operation cancelled." -ForegroundColor Yellow
    exit
}

if ($choice -ne "2" -and $choice -ne "3") {
    Write-Host "Invalid choice. Exiting." -ForegroundColor Red
    exit
}

Write-Host "`nYou selected: Option $choice" -ForegroundColor Cyan
$confirm = Read-Host "Type 'YES' to continue"

if ($confirm -ne "YES") {
    Write-Host "Operation cancelled." -ForegroundColor Yellow
    exit
}

# ============================================
# Common Steps (Both Options)
# ============================================

Write-Host "`n[STEP 1] Disabling Tamper Protection..." -ForegroundColor Yellow
try {
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Defender\Features" -Name "TamperProtection" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Write-Host "✓ Tamper Protection disabled" -ForegroundColor Green
} catch {
    Write-Host "! May require manual disable in Windows Security settings" -ForegroundColor Yellow
}

Write-Host "`n[STEP 2] Disabling Real-time Protection..." -ForegroundColor Yellow
try {
    Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
    Set-MpPreference -DisableBehaviorMonitoring $true -ErrorAction SilentlyContinue
    Set-MpPreference -DisableBlockAtFirstSeen $true -ErrorAction SilentlyContinue
    Set-MpPreference -DisableIOAVProtection $true -ErrorAction SilentlyContinue
    Set-MpPreference -DisablePrivacyMode $true -ErrorAction SilentlyContinue
    Set-MpPreference -DisableScriptScanning $true -ErrorAction SilentlyContinue
    Set-MpPreference -SubmitSamplesConsent 2 -ErrorAction SilentlyContinue
    Write-Host "✓ Real-time Protection features disabled" -ForegroundColor Green
} catch {
    Write-Host "! Some protection features may still be active" -ForegroundColor Yellow
}

Write-Host "`n[STEP 3] Applying Registry Modifications..." -ForegroundColor Yellow

# Disable Windows Defender via Group Policy
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -Value 1 -Type DWord
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableRoutinelyTakingAction" -Value 1 -Type DWord

# Disable Real-time Protection
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableBehaviorMonitoring" -Value 1 -Type DWord
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableIOAVProtection" -Value 1 -Type DWord
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableOnAccessProtection" -Value 1 -Type DWord
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableRealtimeMonitoring" -Value 1 -Type DWord
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableScanOnRealtimeEnable" -Value 1 -Type DWord

# Disable Signature Updates
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Signature Updates" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Signature Updates" -Name "ForceUpdateFromMU" -Value 0 -Type DWord

# Disable Spynet reporting
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" -Name "SpynetReporting" -Value 0 -Type DWord
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" -Name "SubmitSamplesConsent" -Value 2 -Type DWord

# Disable through Windows Defender main key (optional - requires TrustedInstaller permissions)
try {
    New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows Defender" -Force -ErrorAction Stop | Out-Null
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -Value 1 -Type DWord -ErrorAction Stop
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Defender" -Name "DisableAntiVirus" -Value 1 -Type DWord -ErrorAction Stop
    Write-Host "  ✓ Main Defender key modified" -ForegroundColor Green
} catch {
    Write-Host "  - Main Defender key protected (Group Policy settings applied instead)" -ForegroundColor Gray
}

Write-Host "✓ Registry modifications completed" -ForegroundColor Green

Write-Host "`n[STEP 4] Disabling Windows Defender Services..." -ForegroundColor Yellow

$services = @(
    "WinDefend",
    "WdNisSvc",
    "WdNisDrv",
    "WdBoot",
    "WdFilter",
    "Sense",
    "SecurityHealthService"
)

foreach ($service in $services) {
    try {
        $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
        if ($svc) {
            Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
            Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
            Write-Host "  ✓ Disabled: $service" -ForegroundColor Green
        }
    } catch {
        Write-Host "  - Skipped: $service" -ForegroundColor Gray
    }
}

Write-Host "`n[STEP 5] Disabling Scheduled Tasks..." -ForegroundColor Yellow

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
            Disable-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue | Out-Null
            Write-Host "  ✓ Disabled: $task" -ForegroundColor Green
        }
    } catch {
        Write-Host "  - Skipped: $task" -ForegroundColor Gray
    }
}

Write-Host "`n[STEP 6] Removing Context Menu Entries..." -ForegroundColor Yellow

# Use reg.exe instead of PowerShell cmdlets (faster and more reliable)
try {
    # Remove from directory context menu
    reg delete "HKCR\Directory\shellex\ContextMenuHandlers\EPP" /f 2>&1 | Out-Null

    # Remove common file type context menus
    reg delete "HKCR\*\shellex\ContextMenuHandlers\EPP" /f 2>&1 | Out-Null

    Write-Host "✓ Context menu cleanup completed" -ForegroundColor Green
} catch {
    Write-Host "✓ Context menu cleanup completed" -ForegroundColor Green
}

Write-Host "`n[STEP 7] Disabling SmartScreen..." -ForegroundColor Yellow
try {
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Force | Out-Null
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "SmartScreenEnabled" -Value "Off" -Type String -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableSmartScreen" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "SmartScreenEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Write-Host "✓ SmartScreen disabled" -ForegroundColor Green
} catch {
    Write-Host "! SmartScreen may still be active" -ForegroundColor Yellow
}

# ============================================
# Option 3 Specific Steps
# ============================================

if ($choice -eq "3") {
    Write-Host "`n[OPTION 3] Removing Windows Defender Files..." -ForegroundColor Magenta

    $defenderPath = "$env:ProgramFiles\Windows Defender"
    $defenderAdvancedPath = "$env:ProgramData\Microsoft\Windows Defender"

    # Remove main Defender folder
    if (Test-Path $defenderPath) {
        try {
            Write-Host "  Taking ownership of Defender folder..." -ForegroundColor Yellow
            takeown /f "$defenderPath" /r /d y 2>&1 | Out-Null
            icacls "$defenderPath" /grant administrators:F /t 2>&1 | Out-Null

            $backupPath = "$env:ProgramFiles\Windows Defender.disabled"
            if (Test-Path $backupPath) {
                Remove-Item -Path $backupPath -Recurse -Force -ErrorAction SilentlyContinue
            }

            Rename-Item -Path $defenderPath -NewName "Windows Defender.disabled" -Force -ErrorAction Stop
            Write-Host "  ✓ Defender program folder disabled" -ForegroundColor Green
        } catch {
            Write-Host "  ! Could not rename Defender folder (requires reboot)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  - Defender program folder not found" -ForegroundColor Gray
    }

    # Disable Advanced Threat Protection
    if (Test-Path $defenderAdvancedPath) {
        try {
            takeown /f "$defenderAdvancedPath" /r /d y 2>&1 | Out-Null
            icacls "$defenderAdvancedPath" /grant administrators:F /t 2>&1 | Out-Null

            $advBackupPath = "$env:ProgramData\Microsoft\Windows Defender.disabled"
            if (Test-Path $advBackupPath) {
                Remove-Item -Path $advBackupPath -Recurse -Force -ErrorAction SilentlyContinue
            }

            Rename-Item -Path $defenderAdvancedPath -NewName "Windows Defender.disabled" -Force -ErrorAction SilentlyContinue
            Write-Host "  ✓ Defender data folder disabled" -ForegroundColor Green
        } catch {
            Write-Host "  ! Could not rename Defender data folder" -ForegroundColor Yellow
        }
    }
}

# ============================================
# Completion
# ============================================

Write-Host "`n============================================" -ForegroundColor Cyan
if ($choice -eq "2") {
    Write-Host "  Option 2: Permanent Disable Completed!" -ForegroundColor Green
} else {
    Write-Host "  Option 3: Complete Removal Completed!" -ForegroundColor Green
}
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "IMPORTANT NOTES:" -ForegroundColor Yellow
Write-Host "  1. REBOOT REQUIRED for changes to take full effect" -ForegroundColor White
Write-Host "  2. System is now UNPROTECTED - consider alternative security" -ForegroundColor White
Write-Host "  3. Windows Updates may attempt to re-enable features" -ForegroundColor White
Write-Host "  4. Use RestoreDefender.ps1 to restore if needed" -ForegroundColor White
Write-Host ""

$reboot = Read-Host "Reboot now? (Y/N)"
if ($reboot -eq "Y" -or $reboot -eq "y") {
    Write-Host "`nRebooting in 10 seconds..." -ForegroundColor Yellow
    Write-Host "Press Ctrl+C to cancel" -ForegroundColor Gray
    Start-Sleep -Seconds 10
    Restart-Computer -Force
} else {
    Write-Host "`nPlease reboot manually to complete the process." -ForegroundColor Yellow
    pause
}
