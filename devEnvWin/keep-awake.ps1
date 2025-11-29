# Windows 절전모드 및 화면 꺼짐 방지 스크립트
# 관리자 권한으로 실행하세요

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "  절전모드 비활성화 스크립트" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# 관리자 권한 확인
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "경고: 이 스크립트는 관리자 권한이 필요합니다." -ForegroundColor Yellow
    Write-Host "PowerShell을 관리자 권한으로 실행한 후 다시 시도하세요." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "종료하려면 Enter를 누르세요"
    exit
}

Write-Host "[1/4] 현재 전원 설정 백업 중..." -ForegroundColor Green

# 현재 전원 구성표 GUID 가져오기
$currentScheme = (powercfg /getactivescheme).Split()[3]

# 백업 파일 생성
$backupFile = "power-settings-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
$backupPath = Join-Path $PSScriptRoot $backupFile

# 현재 설정 백업
@"
전원 설정 백업 - $(Get-Date)
활성 구성표: $currentScheme

=== 현재 설정 ===
"@ | Out-File -FilePath $backupPath -Encoding UTF8

powercfg /query $currentScheme | Out-File -FilePath $backupPath -Append -Encoding UTF8

Write-Host "   백업 완료: $backupFile" -ForegroundColor Gray
Write-Host ""

Write-Host "[2/4] 절전모드 및 화면 꺼짐 비활성화 중..." -ForegroundColor Green

# AC 전원(콘센트) 및 배터리 모드 모두 설정
# 모니터 꺼짐 시간: 0 = 끄지 않음
powercfg /change monitor-timeout-ac 0
powercfg /change monitor-timeout-dc 0

# 절전모드 시간: 0 = 사용 안 함
powercfg /change standby-timeout-ac 0
powercfg /change standby-timeout-dc 0

# 최대 절전모드 시간: 0 = 사용 안 함
powercfg /change hibernate-timeout-ac 0
powercfg /change hibernate-timeout-dc 0

# 디스크 끄기 시간: 0 = 끄지 않음
powercfg /change disk-timeout-ac 0
powercfg /change disk-timeout-dc 0

Write-Host "   완료" -ForegroundColor Gray
Write-Host ""

Write-Host "[3/4] 네트워크 어댑터 절전 설정 비활성화 중..." -ForegroundColor Green

# 네트워크 어댑터의 절전 모드 비활성화
$adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }

foreach ($adapter in $adapters) {
    $adapterName = $adapter.Name
    try {
        # PnP 장치의 절전 모드 설정 가져오기
        $powerMgmt = Get-CimInstance -ClassName MSPower_DeviceEnable -Namespace root/wmi |
                     Where-Object { $_.InstanceName -like "*$($adapter.InterfaceGuid)*" }

        if ($powerMgmt) {
            # 절전 모드 비활성화
            $powerMgmt | Set-CimInstance -Property @{Enable = $false}
            Write-Host "   - $adapterName : 절전모드 비활성화됨" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "   - $adapterName : 설정 건너뜀 (권한 필요 또는 지원하지 않음)" -ForegroundColor DarkGray
    }
}

Write-Host ""

Write-Host "[4/4] 고급 전원 설정 구성 중..." -ForegroundColor Green

# USB 절전 모드 비활성화
powercfg /setacvalueindex $currentScheme 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
powercfg /setdcvalueindex $currentScheme 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0

# PCI Express 링크 상태 전원 관리 끄기
powercfg /setacvalueindex $currentScheme 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 0
powercfg /setdcvalueindex $currentScheme 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 0

# 설정 적용
powercfg /setactive $currentScheme

Write-Host "   완료" -ForegroundColor Gray
Write-Host ""

Write-Host "=====================================" -ForegroundColor Green
Write-Host "  모든 설정이 완료되었습니다!" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""
Write-Host "적용된 설정:" -ForegroundColor Yellow
Write-Host "  - 모니터 꺼짐: 사용 안 함" -ForegroundColor White
Write-Host "  - 절전모드: 사용 안 함" -ForegroundColor White
Write-Host "  - 최대 절전모드: 사용 안 함" -ForegroundColor White
Write-Host "  - 네트워크 어댑터: 절전모드 비활성화" -ForegroundColor White
Write-Host "  - USB 절전모드: 비활성화" -ForegroundColor White
Write-Host ""
Write-Host "원래 설정으로 복구하려면 'restore-power-settings.ps1'을 실행하세요." -ForegroundColor Cyan
Write-Host ""
Read-Host "종료하려면 Enter를 누르세요"
