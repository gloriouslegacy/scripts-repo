# Windows 전원 설정 복원 스크립트
# 관리자 권한으로 실행하세요

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "  전원 설정 복원 스크립트" -ForegroundColor Cyan
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

Write-Host "기본 전원 설정으로 복원합니다." -ForegroundColor Yellow
Write-Host ""

# 현재 전원 구성표 GUID 가져오기
$currentScheme = (powercfg /getactivescheme).Split()[3]

Write-Host "[1/3] 일반적인 전원 설정으로 복원 중..." -ForegroundColor Green

# AC 전원 (콘센트 연결)
powercfg /change monitor-timeout-ac 10      # 10분 후 모니터 끄기
powercfg /change standby-timeout-ac 30      # 30분 후 절전모드
powercfg /change hibernate-timeout-ac 0     # 최대 절전모드 사용 안 함
powercfg /change disk-timeout-ac 20         # 20분 후 디스크 끄기

# 배터리 모드
powercfg /change monitor-timeout-dc 5       # 5분 후 모니터 끄기
powercfg /change standby-timeout-dc 15      # 15분 후 절전모드
powercfg /change hibernate-timeout-dc 0     # 최대 절전모드 사용 안 함
powercfg /change disk-timeout-dc 10         # 10분 후 디스크 끄기

Write-Host "   완료" -ForegroundColor Gray
Write-Host ""

Write-Host "[2/3] 네트워크 어댑터 절전 설정 복원 중..." -ForegroundColor Green

# 네트워크 어댑터의 절전 모드 활성화
$adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }

foreach ($adapter in $adapters) {
    $adapterName = $adapter.Name
    try {
        $powerMgmt = Get-CimInstance -ClassName MSPower_DeviceEnable -Namespace root/wmi |
                     Where-Object { $_.InstanceName -like "*$($adapter.InterfaceGuid)*" }

        if ($powerMgmt) {
            # 절전 모드 활성화
            $powerMgmt | Set-CimInstance -Property @{Enable = $true}
            Write-Host "   - $adapterName : 절전모드 활성화됨" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "   - $adapterName : 설정 건너뜀" -ForegroundColor DarkGray
    }
}

Write-Host ""

Write-Host "[3/3] 고급 전원 설정 복원 중..." -ForegroundColor Green

# USB 선택적 절전 모드 활성화
powercfg /setacvalueindex $currentScheme 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 1
powercfg /setdcvalueindex $currentScheme 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 1

# PCI Express 링크 상태 전원 관리 켜기 (보통 수준)
powercfg /setacvalueindex $currentScheme 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 1
powercfg /setdcvalueindex $currentScheme 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 1

# 설정 적용
powercfg /setactive $currentScheme

Write-Host "   완료" -ForegroundColor Gray
Write-Host ""

Write-Host "=====================================" -ForegroundColor Green
Write-Host "  전원 설정이 복원되었습니다!" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""
Write-Host "복원된 설정 (AC 전원):" -ForegroundColor Yellow
Write-Host "  - 모니터 끄기: 10분" -ForegroundColor White
Write-Host "  - 절전모드: 30분" -ForegroundColor White
Write-Host "  - 디스크 끄기: 20분" -ForegroundColor White
Write-Host ""
Write-Host "복원된 설정 (배터리):" -ForegroundColor Yellow
Write-Host "  - 모니터 끄기: 5분" -ForegroundColor White
Write-Host "  - 절전모드: 15분" -ForegroundColor White
Write-Host "  - 디스크 끄기: 10분" -ForegroundColor White
Write-Host ""
Read-Host "종료하려면 Enter를 누르세요"
