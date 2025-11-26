@echo off
setlocal

:: =========================================================
:: 1. 관리자 권한 확인 및 요청 (UAC Prompt)
:: =========================================================
if not "%~1"==":admin" (
    ECHO 요청된 작업을 수행하려면 관리자 권한이 필요합니다.
    PowerShell -Command "Start-Process -FilePath '%~dpnx0' -ArgumentList ':admin' -Verb RunAs"
    exit /b
)

:admin
ECHO.
echo Windows Defender SmartScreen 광범위 비활성화 작업 시작

:: =========================================================
:: 2. IE '신뢰할 수 있는 사이트' SmartScreen 설정 변경 (HKCU - 사용자별)
:: Zone 2 = 신뢰할 수 있는 사이트
:: 3 = 사용 안 함
:: =========================================================
echo.
echo [1/3] Internet Explorer/Edge (IE 모드) SmartScreen 레지스트리 설정 시도 (키 2601)
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" /v 2601 /t REG_DWORD /d 3 /f

echo [2/3] Internet Explorer/Edge (IE 모드) SmartScreen 레지스트리 설정 시도 (키 2301)
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" /v 2301 /t REG_DWORD /d 3 /f

:: =========================================================
:: 3. Windows Explorer SmartScreen 설정 변경 (HKLM - 시스템 전체)
:: 관리자 권한이 필수적입니다. 이 설정은 앱 및 파일 실행 전 검사를 제어합니다.
:: =========================================================
echo.
REM echo [3/3] Windows Explorer SmartScreen 시스템 설정 비활성화 시도 (HKLM)
:: HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\System
:: EnableSmartScreen = 0 (비활성화)
:: REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v EnableSmartScreen /t REG_DWORD /d 0 /f

echo.
echo ----------------------------------------------------
IF %ERRORLEVEL% EQU 0 (
    echo 모든 설정이 성공적으로 적용되었습니다.
    echo (적용 확인을 위해 인터넷 옵션 창을 닫았다가 다시 여세요.)
REM    echo 시스템 전체 SmartScreen을 비활성화했을 수 있습니다.
    echo.
REM    echo 변경 사항 적용을 위해 컴퓨터를 **재부팅**하는 것이 좋습니다.
) ELSE (
REM    echo 일부 설정을 적용하는 데 오류가 발생했습니다.
)
echo ----------------------------------------------------

echo 종료하려면 아무키나 누르면 됩니다.
pause > nul