#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Windows 10/11 시스템 최적화 스크립트
.DESCRIPTION
    Windows 자동 업데이트, Edge/Chrome 업데이트 차단, Sysmain 비활성화, OneDrive/Cortana 제거
.NOTES
    관리자 권한 필요
#>

# UAC 권한 체크
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Administrator)) {
    Write-Host "이 스크립트는 관리자 권한이 필요합니다." -ForegroundColor Red
    Write-Host "관리자 권한으로 다시 실행합니다..." -ForegroundColor Yellow

    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    Start-Process powershell.exe -ArgumentList $arguments -Verb RunAs
    exit
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Windows 10/11 시스템 최적화 스크립트" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 로그 함수
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

# 1. Windows 자동 업데이트 차단
function Disable-WindowsUpdate {
    Write-Log "Windows 자동 업데이트 차단 중..." "INFO"

    try {
        # Windows Update 서비스 중지 및 비활성화
        Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
        Set-Service -Name wuauserv -StartupType Disabled -ErrorAction Stop

        # 레지스트리 설정
        $regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
        if (-not (Test-Path $regPath)) {
            New-Item -Path $regPath -Force | Out-Null
        }

        Set-ItemProperty -Path $regPath -Name "NoAutoUpdate" -Value 1 -Type DWord
        Set-ItemProperty -Path $regPath -Name "AUOptions" -Value 2 -Type DWord
        Set-ItemProperty -Path $regPath -Name "ScheduledInstallDay" -Value 0 -Type DWord
        Set-ItemProperty -Path $regPath -Name "ScheduledInstallTime" -Value 3 -Type DWord

        # Windows Update Medic Service 비활성화 (Windows 10 1903 이상)
        Stop-Service -Name WaaSMedicSvc -Force -ErrorAction SilentlyContinue

        # 작업 스케줄러에서 Windows Update 관련 작업 비활성화
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
                # 작업이 없으면 무시
            }
        }

        Write-Log "Windows 자동 업데이트 차단 완료" "SUCCESS"
    } catch {
        Write-Log "Windows 자동 업데이트 차단 실패: $_" "ERROR"
    }
}

# 2. Microsoft Edge 자동 업데이트 차단
function Disable-EdgeUpdate {
    Write-Log "Microsoft Edge 자동 업데이트 차단 중..." "INFO"

    try {
        # Edge Update 서비스 중지 및 비활성화
        $edgeServices = @("edgeupdate", "edgeupdatem", "MicrosoftEdgeElevationService")
        foreach ($service in $edgeServices) {
            if (Get-Service -Name $service -ErrorAction SilentlyContinue) {
                Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
                Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
            }
        }

        # 레지스트리 설정
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

        # 작업 스케줄러에서 Edge Update 작업 비활성화
        $edgeTasks = Get-ScheduledTask | Where-Object { $_.TaskName -like "*MicrosoftEdgeUpdate*" }
        foreach ($task in $edgeTasks) {
            Disable-ScheduledTask -TaskName $task.TaskName -ErrorAction SilentlyContinue | Out-Null
        }

        Write-Log "Microsoft Edge 자동 업데이트 차단 완료" "SUCCESS"
    } catch {
        Write-Log "Microsoft Edge 자동 업데이트 차단 실패: $_" "ERROR"
    }
}

# 3. Google Chrome 자동 업데이트 차단
function Disable-ChromeUpdate {
    Write-Log "Google Chrome 자동 업데이트 차단 중..." "INFO"

    try {
        # Chrome Update 서비스 중지 및 비활성화
        $chromeServices = @("gupdate", "gupdatem", "GoogleChromeElevationService")
        foreach ($service in $chromeServices) {
            if (Get-Service -Name $service -ErrorAction SilentlyContinue) {
                Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
                Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
            }
        }

        # 레지스트리 설정
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

        # 작업 스케줄러에서 Chrome Update 작업 비활성화
        $chromeTasks = Get-ScheduledTask | Where-Object { $_.TaskName -like "*GoogleUpdate*" }
        foreach ($task in $chromeTasks) {
            Disable-ScheduledTask -TaskName $task.TaskName -ErrorAction SilentlyContinue | Out-Null
        }

        Write-Log "Google Chrome 자동 업데이트 차단 완료" "SUCCESS"
    } catch {
        Write-Log "Google Chrome 자동 업데이트 차단 실패: $_" "ERROR"
    }
}

# 4. SysMain (Superfetch) 서비스 비활성화
function Disable-SysMain {
    Write-Log "SysMain 서비스 비활성화 중..." "INFO"

    try {
        if (Get-Service -Name SysMain -ErrorAction SilentlyContinue) {
            Stop-Service -Name SysMain -Force -ErrorAction Stop
            Set-Service -Name SysMain -StartupType Disabled -ErrorAction Stop
            Write-Log "SysMain 서비스 비활성화 완료" "SUCCESS"
        } else {
            Write-Log "SysMain 서비스를 찾을 수 없습니다" "WARNING"
        }
    } catch {
        Write-Log "SysMain 서비스 비활성화 실패: $_" "ERROR"
    }
}

# 5. OneDrive 제거
function Remove-OneDrive {
    Write-Log "OneDrive 제거 중..." "INFO"

    try {
        # OneDrive 프로세스 종료
        taskkill /f /im OneDrive.exe 2>$null
        Start-Sleep -Seconds 2

        # OneDrive 언인스톨
        $oneDrivePath = "$env:SystemRoot\System32\OneDriveSetup.exe"
        if (-not (Test-Path $oneDrivePath)) {
            $oneDrivePath = "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"
        }

        if (Test-Path $oneDrivePath) {
            Start-Process -FilePath $oneDrivePath -ArgumentList "/uninstall" -Wait -NoNewWindow
            Start-Sleep -Seconds 3
        }

        # OneDrive 폴더 제거
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

        # 레지스트리 설정
        $oneDriveRegPaths = @(
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive",
            "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}",
            "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
        )

        # OneDrive 비활성화
        if (-not (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive")) {
            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Force | Out-Null
        }
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Name "DisableFileSyncNGSC" -Value 1 -Type DWord

        # 탐색기에서 OneDrive 제거
        foreach ($regPath in $oneDriveRegPaths[1..2]) {
            if (Test-Path $regPath) {
                Set-ItemProperty -Path $regPath -Name "System.IsPinnedToNameSpaceTree" -Value 0 -Type DWord -ErrorAction SilentlyContinue
            }
        }

        Write-Log "OneDrive 제거 완료" "SUCCESS"
    } catch {
        Write-Log "OneDrive 제거 실패: $_" "ERROR"
    }
}

# 6. Cortana 제거/비활성화
function Disable-Cortana {
    Write-Log "Cortana 비활성화 중..." "INFO"

    try {
        # Cortana 레지스트리 설정
        $cortanaRegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
        if (-not (Test-Path $cortanaRegPath)) {
            New-Item -Path $cortanaRegPath -Force | Out-Null
        }

        Set-ItemProperty -Path $cortanaRegPath -Name "AllowCortana" -Value 0 -Type DWord
        Set-ItemProperty -Path $cortanaRegPath -Name "AllowSearchToUseLocation" -Value 0 -Type DWord
        Set-ItemProperty -Path $cortanaRegPath -Name "DisableWebSearch" -Value 1 -Type DWord
        Set-ItemProperty -Path $cortanaRegPath -Name "ConnectedSearchUseWeb" -Value 0 -Type DWord

        # Cortana 앱 제거 (Windows 11)
        Get-AppxPackage -allusers *Microsoft.549981C3F5F10* | Remove-AppxPackage -ErrorAction SilentlyContinue

        Write-Log "Cortana 비활성화 완료" "SUCCESS"
    } catch {
        Write-Log "Cortana 비활성화 실패: $_" "ERROR"
    }
}

# 메인 실행
Write-Host ""
Write-Log "시스템 최적화를 시작합니다..." "INFO"
Write-Host ""

Disable-WindowsUpdate
Write-Host ""

Disable-EdgeUpdate
Write-Host ""

Disable-ChromeUpdate
Write-Host ""

Disable-SysMain
Write-Host ""

Remove-OneDrive
Write-Host ""

Disable-Cortana
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Log "모든 최적화 작업이 완료되었습니다!" "SUCCESS"
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Log "변경사항을 완전히 적용하려면 시스템을 재부팅하세요." "WARNING"
Write-Host ""

$reboot = Read-Host "지금 재부팅하시겠습니까? (Y/N)"
if ($reboot -eq 'Y' -or $reboot -eq 'y') {
    Write-Log "5초 후 재부팅합니다..." "INFO"
    Start-Sleep -Seconds 5
    Restart-Computer -Force
} else {
    Write-Log "나중에 수동으로 재부팅하세요." "INFO"
}
