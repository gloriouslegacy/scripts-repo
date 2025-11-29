# This script creates Windows_Optimize.ps1 with proper UTF-8 BOM encoding
$scriptContent = @'
#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Windows 10/11 System Optimization Script
.DESCRIPTION
    Disable Windows Update, Edge/Chrome Update, Sysmain, Windows Defender/OneDrive/Cortana
.NOTES
    Requires Administrator privileges
#>

# UAC Permission Check
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Administrator)) {
    Write-Host "This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Restarting with Administrator privileges..." -ForegroundColor Yellow

    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    Start-Process powershell.exe -ArgumentList $arguments -Verb RunAs
    exit
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Windows 10/11 System Optimization" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Logging function
function Write-Log {
    param([string]$Message, [string]$Type = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Type) {
        "SUCCESS" { "Green" }
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        default { "White" }
    }
    Write-Host "[$timestamp] [$Type] $Message" -ForegroundColor $color
}

# 1. Disable Windows Update
function Disable-WindowsUpdate {
    Write-Log "Disabling Windows Update..." "INFO"

    try {
        # Stop and disable Windows Update service
        Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
        Set-Service -Name wuauserv -StartupType Disabled -ErrorAction Stop

        # Registry settings
        $regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
        if (-not (Test-Path $regPath)) {
            New-Item -Path $regPath -Force | Out-Null
        }

        Set-ItemProperty -Path $regPath -Name "NoAutoUpdate" -Value 1 -Type DWord
        Set-ItemProperty -Path $regPath -Name "AUOptions" -Value 2 -Type DWord
        Set-ItemProperty -Path $regPath -Name "ScheduledInstallDay" -Value 0 -Type DWord
        Set-ItemProperty -Path $regPath -Name "ScheduledInstallTime" -Value 3 -Type DWord

        # Disable Windows Update Medic Service (Windows 10 1903+)
        Stop-Service -Name WaaSMedicSvc -Force -ErrorAction SilentlyContinue

        # Disable Windows Update scheduled tasks
        $tasks = @(
            "\Microsoft\Windows\WindowsUpdate\Automatic App Update",
            "\Microsoft\Windows\WindowsUpdate\Scheduled Start",
            "\Microsoft\Windows\WindowsUpdate\sih",
            "\Microsoft\Windows\WindowsUpdate\sihboot"
        )

        foreach ($task in $tasks) {
            try {
                Disable-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue | Out-Null
            } catch {
                # Ignore if task doesn't exist
            }
        }

        Write-Log "Windows Update disabled successfully" "SUCCESS"
    } catch {
        Write-Log "Failed to disable Windows Update: $_" "ERROR"
    }
}

# 2. Disable Microsoft Edge Update
function Disable-EdgeUpdate {
    Write-Log "Disabling Microsoft Edge Update..." "INFO"

    try {
        # Stop and disable Edge Update services
        $edgeServices = @("edgeupdate", "edgeupdatem", "MicrosoftEdgeElevationService")
        foreach ($service in $edgeServices) {
            if (Get-Service -Name $service -ErrorAction SilentlyContinue) {
                Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
                Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
            }
        }

        # Registry settings
        $regPaths = @(
            "HKLM:\SOFTWARE\Policies\Microsoft\Edge",
            "HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate"
        )

        foreach ($path in $regPaths) {
            if (-not (Test-Path $path)) {
                New-Item -Path $path -Force | Out-Null
            }
        }

        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate" -Name "AutoUpdateCheckPeriodMinutes" -Value 0 -Type DWord
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate" -Name "UpdateDefault" -Value 0 -Type DWord
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate" -Name "Update{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}" -Value 0 -Type DWord

        # Disable Edge Update scheduled tasks
        $edgeTasks = Get-ScheduledTask | Where-Object { $_.TaskName -like "*MicrosoftEdgeUpdate*" }
        foreach ($task in $edgeTasks) {
            Disable-ScheduledTask -TaskName $task.TaskName -ErrorAction SilentlyContinue | Out-Null
        }

        Write-Log "Microsoft Edge Update disabled successfully" "SUCCESS"
    } catch {
        Write-Log "Failed to disable Microsoft Edge Update: $_" "ERROR"
    }
}

# 3. Disable Google Chrome Update
function Disable-ChromeUpdate {
    Write-Log "Disabling Google Chrome Update..." "INFO"

    try {
        # Stop and disable Chrome Update services
        $chromeServices = @("gupdate", "gupdatem", "GoogleChromeElevationService")
        foreach ($service in $chromeServices) {
            if (Get-Service -Name $service -ErrorAction SilentlyContinue) {
                Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
                Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
            }
        }

        # Registry settings
        $regPaths = @(
            "HKLM:\SOFTWARE\Policies\Google\Update",
            "HKLM:\SOFTWARE\Policies\Google\Chrome"
        )

        foreach ($path in $regPaths) {
            if (-not (Test-Path $path)) {
                New-Item -Path $path -Force | Out-Null
            }
        }

        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Google\Update" -Name "AutoUpdateCheckPeriodMinutes" -Value 0 -Type DWord
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Google\Update" -Name "UpdateDefault" -Value 0 -Type DWord
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Google\Update" -Name "DisableAutoUpdateChecksCheckboxValue" -Value 1 -Type DWord

        # Disable Chrome Update scheduled tasks
        $chromeTasks = Get-ScheduledTask | Where-Object { $_.TaskName -like "*GoogleUpdate*" }
        foreach ($task in $chromeTasks) {
            Disable-ScheduledTask -TaskName $task.TaskName -ErrorAction SilentlyContinue | Out-Null
        }

        Write-Log "Google Chrome Update disabled successfully" "SUCCESS"
    } catch {
        Write-Log "Failed to disable Google Chrome Update: $_" "ERROR"
    }
}

# 4. Disable SysMain (Superfetch) Service
function Disable-SysMain {
    Write-Log "Disabling SysMain service..." "INFO"

    try {
        if (Get-Service -Name SysMain -ErrorAction SilentlyContinue) {
            Stop-Service -Name SysMain -Force -ErrorAction Stop
            Set-Service -Name SysMain -StartupType Disabled -ErrorAction Stop
            Write-Log "SysMain service disabled successfully" "SUCCESS"
        } else {
            Write-Log "SysMain service not found" "WARNING"
        }
    } catch {
        Write-Log "Failed to disable SysMain service: $_" "ERROR"
    }
}

# 5. Disable Windows Defender
function Disable-WindowsDefender {
    Write-Log "Disabling Windows Defender..." "INFO"

    try {
        # Stop and disable Windows Defender services
        $defenderServices = @("WinDefend", "SecurityHealthService", "WdNisSvc", "Sense")
        foreach ($service in $defenderServices) {
            if (Get-Service -Name $service -ErrorAction SilentlyContinue) {
                Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
                Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
            }
        }

        # Disable real-time protection
        Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue

        # Registry settings
        $defenderRegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
        if (-not (Test-Path $defenderRegPath)) {
            New-Item -Path $defenderRegPath -Force | Out-Null
        }

        Set-ItemProperty -Path $defenderRegPath -Name "DisableAntiSpyware" -Value 1 -Type DWord
        Set-ItemProperty -Path $defenderRegPath -Name "DisableAntiVirus" -Value 1 -Type DWord

        # Real-time protection registry settings
        $realtimeRegPath = "$defenderRegPath\Real-Time Protection"
        if (-not (Test-Path $realtimeRegPath)) {
            New-Item -Path $realtimeRegPath -Force | Out-Null
        }

        Set-ItemProperty -Path $realtimeRegPath -Name "DisableBehaviorMonitoring" -Value 1 -Type DWord
        Set-ItemProperty -Path $realtimeRegPath -Name "DisableOnAccessProtection" -Value 1 -Type DWord
        Set-ItemProperty -Path $realtimeRegPath -Name "DisableScanOnRealtimeEnable" -Value 1 -Type DWord

        # Disable Windows Defender scheduled tasks
        $defenderTasks = Get-ScheduledTask | Where-Object { $_.TaskPath -like "*Windows Defender*" }
        foreach ($task in $defenderTasks) {
            Disable-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath -ErrorAction SilentlyContinue | Out-Null
        }

        Write-Log "Windows Defender disabled successfully (reboot required)" "SUCCESS"
        Write-Log "For complete removal, use additional tools" "WARNING"
    } catch {
        Write-Log "Failed to disable Windows Defender: $_" "ERROR"
    }
}

# 6. Remove OneDrive
function Remove-OneDrive {
    Write-Log "Removing OneDrive..." "INFO"

    try {
        # Kill OneDrive process
        taskkill /f /im OneDrive.exe 2>$null
        Start-Sleep -Seconds 2

        # Uninstall OneDrive
        $oneDrivePath = "$env:SystemRoot\System32\OneDriveSetup.exe"
        if (-not (Test-Path $oneDrivePath)) {
            $oneDrivePath = "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"
        }

        if (Test-Path $oneDrivePath) {
            Start-Process -FilePath $oneDrivePath -ArgumentList "/uninstall" -Wait -NoNewWindow
            Start-Sleep -Seconds 3
        }

        # Remove OneDrive folders
        $oneDriveFolders = @(
            "$env:LOCALAPPDATA\Microsoft\OneDrive",
            "$env:ProgramData\Microsoft OneDrive",
            "$env:USERPROFILE\OneDrive"
        )

        foreach ($folder in $oneDriveFolders) {
            if (Test-Path $folder) {
                Remove-Item -Path $folder -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        # Registry settings
        $oneDriveRegPaths = @(
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive",
            "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}",
            "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
        )

        # Disable OneDrive
        if (-not (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive")) {
            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Force | Out-Null
        }
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Name "DisableFileSyncNGSC" -Value 1 -Type DWord

        # Remove OneDrive from Explorer
        foreach ($regPath in $oneDriveRegPaths[1..2]) {
            if (Test-Path $regPath) {
                Set-ItemProperty -Path $regPath -Name "System.IsPinnedToNameSpaceTree" -Value 0 -Type DWord -ErrorAction SilentlyContinue
            }
        }

        Write-Log "OneDrive removed successfully" "SUCCESS"
    } catch {
        Write-Log "Failed to remove OneDrive: $_" "ERROR"
    }
}

# 7. Disable Cortana
function Disable-Cortana {
    Write-Log "Disabling Cortana..." "INFO"

    try {
        # Cortana registry settings
        $cortanaRegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
        if (-not (Test-Path $cortanaRegPath)) {
            New-Item -Path $cortanaRegPath -Force | Out-Null
        }

        Set-ItemProperty -Path $cortanaRegPath -Name "AllowCortana" -Value 0 -Type DWord
        Set-ItemProperty -Path $cortanaRegPath -Name "AllowSearchToUseLocation" -Value 0 -Type DWord
        Set-ItemProperty -Path $cortanaRegPath -Name "DisableWebSearch" -Value 1 -Type DWord
        Set-ItemProperty -Path $cortanaRegPath -Name "ConnectedSearchUseWeb" -Value 0 -Type DWord

        # Remove Cortana app (Windows 11)
        Get-AppxPackage -allusers *Microsoft.549981C3F5F10* | Remove-AppxPackage -ErrorAction SilentlyContinue

        Write-Log "Cortana disabled successfully" "SUCCESS"
    } catch {
        Write-Log "Failed to disable Cortana: $_" "ERROR"
    }
}

# Main execution
Write-Host ""
Write-Log "Starting system optimization..." "INFO"
Write-Host ""

Disable-WindowsUpdate
Write-Host ""

Disable-EdgeUpdate
Write-Host ""

Disable-ChromeUpdate
Write-Host ""

Disable-SysMain
Write-Host ""

Disable-WindowsDefender
Write-Host ""

Remove-OneDrive
Write-Host ""

Disable-Cortana
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Log "All optimization tasks completed!" "SUCCESS"
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Log "Please reboot to apply all changes." "WARNING"
Write-Host ""

$reboot = Read-Host "Reboot now? (Y/N)"
if ($reboot -eq 'Y' -or $reboot -eq 'y') {
    Write-Log "Rebooting in 5 seconds..." "INFO"
    Start-Sleep -Seconds 5
    Restart-Computer -Force
} else {
    Write-Log "Please reboot manually later." "INFO"
}
'@

# Save with UTF-8 BOM encoding
$utf8BOM = New-Object System.Text.UTF8Encoding $true
$outputPath = Join-Path $PSScriptRoot "Windows_Optimize.ps1"
[System.IO.File]::WriteAllText($outputPath, $scriptContent, $utf8BOM)

Write-Host "Windows_Optimize.ps1 has been created successfully!" -ForegroundColor Green
Write-Host "Location: $outputPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "To run the script:" -ForegroundColor Yellow
Write-Host "1. Right-click Windows_Optimize.ps1" -ForegroundColor White
Write-Host "2. Select 'Run with PowerShell'" -ForegroundColor White
Write-Host ""
Write-Host "Or run from PowerShell:" -ForegroundColor Yellow
Write-Host "Set-ExecutionPolicy Bypass -Scope Process -Force" -ForegroundColor White
Write-Host ".\Windows_Optimize.ps1" -ForegroundColor White
