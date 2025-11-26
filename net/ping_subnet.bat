@echo off
setlocal enabledelayedexpansion
COLOR 0A

rem --- 로그 설정 ---
rem 1. 로그 파일 경로 정의
set "logFilePath=%USERPROFILE%\Desktop\ping_test_log_bat.txt"

rem 2. 로그 파일 초기화 및 시작 시간 기록
echo --- 핑 테스트 시작 (%DATE% %TIME%) --- > "%logFilePath%"


set /p subnet="핑 테스트할 네트워크 접두사(예: 192.168.0)를 입력하세요: "

echo.
echo %subnet%.1부터 %subnet%.254까지 핑 테스트를 시작합니다...
echo.

:Loop
for /L %%z in (1,1,254) do (
    set "ipAddress=%subnet%.%%z"
    
    rem 핑 명령 실행: -w 50 (응답 대기 시간 50ms), -n 1 (패킷 1개)
    rem find "TTL=" > nul: TTL 문자열을 찾아 출력을 숨김. 응답이 있으면 errorlevel은 0, 없으면 1.
    ping !ipAddress! -w 50 -n 1 | find "TTL=" > nul
    
    rem 3. 결과에 따라 출력 및 로그 기록
    if not errorlevel 1 (
        rem 연결 성공 (활성 호스트)
        echo [활성] 호스트 발견: !ipAddress!
        echo [활성] 호스트 발견: !ipAddress! >> "%logFilePath%"
    ) else (
        rem 연결 실패 (비활성 호스트)
        rem 비활성 호스트도 콘솔에 표시하려면 아래 'rem'을 제거하세요.
        rem echo [비활성] 호스트: !ipAddress!

        rem 로그 파일에는 비활성 호스트도 기록
        echo [비활성] 호스트: !ipAddress! >> "%logFilePath%"
    )
)

echo.
echo 핑 테스트가 완료되었습니다.
echo 로그 파일이 다음 경로에 저장되었습니다: %logFilePath%
pause