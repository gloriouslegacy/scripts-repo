# 스크립트 실행 정책에 따라 실행이 안 될 경우, 관리자 권한으로 다음 명령어 실행:
# Set-ExecutionPolicy RemoteSigned

# 로그 설정
# 1. 로그 파일 경로 정의 (%userprofile%\Desktop 경로 사용)
$logFilePath = "$env:USERPROFILE\Desktop\ping_test_log_ps1.txt"

# 2. 로그 파일 초기화 (스크립트 실행 시 기존 내용 삭제)
# 실행 시간을 로그에 기록
$currentDateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$initialLogContent = "--- 핑 테스트 시작 ($currentDateTime) ---`n"
$initialLogContent | Set-Content -Path $logFilePath

# 

# 3. 네트워크 접두사 입력 받기
$subnet = Read-Host "핑 테스트할 네트워크 접두사(예: 192.168.0)를 입력하세요"

Write-Host "`n$subnet.1부터 $subnet.254까지 핑 테스트를 시작합니다..."

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
    }
    # else {
        # 연결 실패 (비활성 호스트) 시, 빨간색으로 출력(비활성화 호스트 출력하려면 else문 주석 제거)
    #    $logEntry = "🔴 비활성 호스트: $ipAddress"
    #    Write-Host $logEntry -ForegroundColor Red
    #}
    
    # 로그 파일에 내용 추가
    Add-Content -Path $logFilePath -Value $logEntry
}

Write-Host "`n핑 테스트가 완료되었습니다."
Write-Host "로그 파일이 다음 경로에 저장되었습니다: $logFilePath"
#