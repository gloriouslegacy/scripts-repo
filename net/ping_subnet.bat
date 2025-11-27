@echo off
rem 지연된 환경 변수 확장을 활성화합니다.
setlocal enabledelayedexpansion
COLOR 0A

rem --- 로그 설정 ---
rem 1. 로그 파일 경로 정의
set "logFilePath=%USERPROFILE%\Desktop\ping_test_log_bat.txt"

rem 2. 로그 파일 초기화 및 시작 시간 기록
echo --- 핑 테스트 시작 (%%DATE%% %%TIME%%) --- > "%logFilePath%"


:Menu
cls
echo.
echo ====================================
echo == 핑 테스트 메뉴 ==
echo ====================================
echo 1. 서브넷 전체 스캔 (예: 192.168.0.1 ~ .254)
echo 2. 특정 IP 주소 핑 테스트 (개별)
echo 3. 종료
echo ====================================
echo.
set /p selection="선택할 메뉴 번호를 입력하세요: "

if "%selection%"=="1" goto SubnetScan
if "%selection%"=="2" goto SingleIPTest
if "%selection%"=="3" goto End
goto MenuError

:MenuError
echo.
echo [오류] 잘못된 메뉴 선택입니다. 다시 입력해주세요.
pause >nul
goto Menu

:SubnetScan
echo.
set /p subnet="핑 테스트할 네트워크 접두사(예: 192.168.0)를 입력하세요: "

echo.
echo %subnet%.1부터 %subnet%.254까지 핑 테스트를 시작합니다...
echo.

rem 로그 파일에 서브넷 스캔 시작 기록
echo 서브넷 스캔 시작: %subnet%.1부터 %subnet%.254까지 >> "%logFilePath%"

for /L %%z in (1,1,254) do (
    set "ipAddress=%subnet%.%%z"
    
    rem 핑 명령 실행: -w 50 (응답 대기 시간 50ms), -n 1 (패킷 1개)
    ping !ipAddress! -w 50 -n 1 | find "TTL=" > nul
    
    rem 결과에 따라 출력 및 로그 기록
    if not errorlevel 1 (
      
        rem 연결 성공 (활성 호스트)
        set "logEntry=[활성] 호스트 발견: !ipAddress!"
        echo !logEntry!
        echo !logEntry! >> "%logFilePath%"
    ) else (
        rem 연결 실패 (비활성 호스트)
        set "logEntry=[비활성] 호스트: !ipAddress!"
        echo !logEntry!
        rem 로그 파일에 비활성 호스트 기록
        echo !logEntry! >> "%logFilePath%"
    )
)

rem --- 서브넷 스캔 완료 후 메뉴 복귀 ---
echo.
echo ====================================
echo 핑 테스트가 완료되었습니다.
echo 로그 파일이 다음 경로에 저장되었습니다: %logFilePath%
echo ====================================
pause
goto Menu


:SingleIPTest
echo.
set /p targetIP="핑 테스트할 특정 IP 주소(예: 8.8.8.8)를 입력하세요: "
echo.
echo %targetIP% 핑 테스트를 시작합니다...

rem ----------------------------------------------------
rem 특정 IP 테스트 로그 상세 기록
rem ----------------------------------------------------

rem 로그 파일에 시작 메시지 기록
echo. >> "%logFilePath%"
echo ---------------------------------------- >> "%logFilePath%"
echo 개별 IP 테스트 시작: %targetIP% >> "%logFilePath%"
echo ---------------------------------------- >> "%logFilePath%"

rem 핑 명령 실행 및 콘솔 출력
ping %targetIP% -w 1000 -n 4 

rem 핑 명령 다시 실행 및 로그 파일에 상세 기록
ping %targetIP% -w 1000 -n 4 >> "%logFilePath%"

rem 최종 성공/실패만 콘솔 및 로그 기록
ping %targetIP% -w 500 -n 1 | find "TTL=" > nul
if not errorlevel 1 (
    echo [개별 핑 결과] 성공적으로 응답 받음: %targetIP%
    echo [개별 핑 결과] 성공적으로 응답 받음: %targetIP% >> "%logFilePath%"
) else (
    echo [개별 핑 결과] 응답 없음 (시간 초과): %targetIP%
    echo [개별 핑 결과] 응답 없음 (시간 초과): %logFilePath% >> "%logFilePath%"
)

rem --- 특정 IP 테스트 완료 후 메뉴 복귀 ---
echo.
echo ====================================
echo 핑 테스트가 완료되었습니다.
echo 로그 파일이 다음 경로에 저장되었습니다: %logFilePath%
echo ====================================

goto Menu


:End