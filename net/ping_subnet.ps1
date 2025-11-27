# 스크립트 실행 정책에 따라 실행이 안 될 경우, 관리자 권한으로 다음 명령어 실행:
# Set-ExecutionPolicy RemoteSigned

# 로그 설정
# 1. 로그 파일 경로 정의 (%userprofile%\Desktop 경로 사용)
$logFilePath = "$env:USERPROFILE\Desktop\ping_test_log_ps1.txt"

# 2. 로그 파일 초기화 (스크립트 실행 시 기존 내용 삭제)
function Initialize-Log {
    $currentDateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $initialLogContent = "--- 핑 테스트 시작 ($currentDateTime) ---`n"
    $initialLogContent | Set-Content -Path $logFilePath
}
# 로그 초기화 실행
Initialize-Log

# ----------------------------------------------------
# --- 함수 정의 (메인 로직보다 상단에 위치) ---
# ----------------------------------------------------

function SubnetScan {
    Clear-Host # 화면을 깨끗하게 정리합니다.
    # 네트워크 접두사 입력 받기
    $subnet = Read-Host "핑 테스트할 네트워크 접두사(예: 192.168.0)를 입력하세요"

    Write-Host "`n$subnet.1부터 $subnet.254까지 핑 테스트를 시작합니다..."
    Add-Content -Path $logFilePath -Value "`n[서브넷 스캔 시작]: $subnet.1 - $subnet.254"

    # 4. 1부터 254까지 반복
    foreach ($i in 1..254) {
        $ipAddress = "$subnet.$i"
        
        # Test-Connection cmdlet을 사용하여 핑 테스트 (-Count 1: 패킷 1개, -Quiet: True/False만 반환)
        $result = Test-Connection -ComputerName $ipAddress -Count 1 -Quiet -ErrorAction SilentlyContinue
        
        $logEntry = ""
        
        # 5. 결과에 따라 색상 출력 및 로그 기록
        if ($result -eq $true) {
            # 연결 성공 (활성 호스트) 시, 녹색으로 출력
            $logEntry = "🟢 활성 호스트 발견: $ipAddress"
            Write-Host $logEntry -ForegroundColor Green
        } else {
            # 연결 실패 (비활성 호스트) 시, 빨간색으로 출력
            $logEntry = "🔴 비활성 호스트: $ipAddress"
            Write-Host $logEntry -ForegroundColor Red
        }
        
        # 로그 파일에 내용 추가 (콘솔 출력 내용과 동일)
        Add-Content -Path $logFilePath -Value $logEntry
    }
    
    # 핑 테스트 완료 및 메뉴 복귀 메시지
    Write-Host "`n===================================="
    Write-Host "핑 테스트가 완료되었습니다."
    Write-Host "로그 파일이 다음 경로에 저장되었습니다: $logFilePath"
    Write-Host "===================================="
    # 실행 일시 정지 (사용자가 Enter를 누를 때까지 대기)
    Read-Host "메뉴로 돌아가려면 Enter 키를 누르세요..." | Out-Null
    # 함수 종료 후 메뉴 루프로 자동 복귀
}

function SingleIPTest {
    Clear-Host # 화면을 깨끗하게 정리합니다.
    $targetIP = Read-Host "핑 테스트할 특정 IP 주소(예: 8.8.8.8)를 입력하세요"
    Write-Host "`n$targetIP 핑 테스트를 시작합니다..."
    
    # 1. Test-Connection 결과를 변수에 저장하고 콘솔에 출력 (Out-String 사용)
    $testOutput = Test-Connection -ComputerName $targetIP -Count 4 -ErrorAction SilentlyContinue | Out-String
    Write-Host $testOutput # 콘솔에 상세 테이블 출력
    
    # 2. 로그 파일에 상세 테이블 내용 추가
    Add-Content -Path $logFilePath -Value "`n[개별 IP 테스트 시작]: $targetIP"
    Add-Content -Path $logFilePath -Value $testOutput

    # 3. 최종 성공/실패 결과 메시지 정의 및 출력/기록
    $result = Test-Connection -ComputerName $targetIP -Count 1 -Quiet -ErrorAction SilentlyContinue
    
    $logEntry = ""

    if ($result -eq $true) {
        $logEntry = "🟢 [개별 핑 결과] 성공적으로 응답 받음: $targetIP"
        Write-Host $logEntry -ForegroundColor Green
    } else {
        $logEntry = "🔴 [개별 핑 결과] 응답 없음 (시간 초과): $targetIP"
        Write-Host $logEntry -ForegroundColor Red
    }
    
    # 최종 메시지 로그 파일에 추가
    Add-Content -Path $logFilePath -Value $logEntry
    
    # 핑 테스트 완료 및 메뉴 복귀 메시지
    Write-Host "`n===================================="
    Write-Host "핑 테스트가 완료되었습니다."
    Write-Host "로그 파일이 다음 경로에 저장되었습니다: $logFilePath"
    Write-Host "===================================="
    # 실행 일시 정지 (사용자가 Enter를 누를 때까지 대기)
    Read-Host "메뉴로 돌아가려면 Enter 키를 누르세요..." | Out-Null
    # 함수 종료 후 메뉴 루프로 자동 복귀
}


# ----------------------------------------------------
# --- 메인 로직(메뉴) 시작: 무한 루프를 통해 메뉴 복귀 보장 ---
# ----------------------------------------------------

while ($true) {
    Clear-Host # 메뉴를 표시할 때마다 화면을 지웁니다.
    Write-Host "`n===================================="
    Write-Host "== 핑 테스트 메뉴 =="
    Write-Host "===================================="
    Write-Host "1. 서브넷 전체 스캔 (예: 192.168.0.1 ~ .254)"
    Write-Host "2. 특정 IP 주소 핑 테스트 (개별)"
    Write-Host "3. 종료"
    Write-Host "===================================="
    $selection = Read-Host "선택할 메뉴 번호를 입력하세요"

    switch ($selection) {
        "1" { SubnetScan; break } # SubnetScan 실행 후 break로 switch를 나가면, while 루프가 재시작되어 메뉴로 복귀합니다.
        "2" { SingleIPTest; break } # SingleIPTest 실행 후 break로 switch를 나가면, while 루프가 재시작되어 메뉴로 복귀합니다.
        "3" { Exit }
        default { 
            Write-Host "[오류] 잘못된 메뉴 선택입니다. 다시 입력해주세요." -ForegroundColor Red 
            Read-Host "계속하려면 Enter 키를 누르세요..." | Out-Null
        }
    }
}