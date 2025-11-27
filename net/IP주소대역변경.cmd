@echo off
color 1F
title IP 3번째 대역 변경
mode con cols=80 lines=40

REM ----- :: COPY START :: -----
:Admin_Check
cd /d "%~dp0" && ( if exist "%temp%\getadmin.vbs" del "%temp%\getadmin.vbs" ) && fsutil dirty query %systemdrive% 1>nul 2>nul || (cmd /u /c echo Set UAC = CreateObject^("Shell.Application"^) : UAC.ShellExecute "cmd.exe", "/k cd ""%~dp0"" && ""%~0"" %params%", "", "runas", 1 > "%temp%\getadmin.vbs" && "%temp%\getadmin.vbs" && exit /B )
REM ----- :: COPY END :: -----

cls
setLocal enableDelayedExpansion
netsh interface ipv4 show interface
set /p startupqueryinterval=IP를 변경 할 '색인' 값을 입력해주세요 :
set RAN_NAME=%startupqueryinterval%
echo.
REM Step 1: "이더넷"으로부터 IP 정보를 가져옵니다.
for /f "tokens=2 delims=:" %%a in ('netsh interface ipv4 show address "%RAN_NAME%" ^| findstr /c:"IP 주소"') do (
    set "IPAddress=%%a"
)

REM Step 2: IP 주소와 기본 게이트웨이를 화면에 출력합니다.
echo IP 주소: %IPAddress%
for /f "tokens=2 delims=:" %%b in ('netsh interface ipv4 show address "%RAN_NAME%" ^| findstr /c:"기본 게이트웨이"') do (
    echo 기본 게이트웨이: %%b
)

REM Step 3, 4: A,B,D 값은 이미 위에서 가져온 값을 사용합니다.
for /f "tokens=1-4 delims=." %%c in ("%IPAddress%") do (
    set "A=%%c"
    set "B=%%d"
    set "C=%%e"
    set "D=%%f"
)
echo.
REM Step 5: 사용자로부터 C 값을 입력 받습니다.
set /p C="변경할 세번째 IP 값 입력: "

REM Step 6: 새로운 IP 주소를 구성하여 설정합니다.
set "NewIPAddress=!A!.!B!.!C!.!D!"
set "SNNum=255.255.255.0"
set "GWNum=!A!.!B!.!C!.1"
netsh interface ipv4 set address name="%RAN_NAME%" static !NewIPAddress! !SNNum! !GWNum!

REM 변경된 IP 주소 출력
echo 새로운 IP 주소: !NewIPAddress!
echo 새로운 게이트웨이: !GWNum!

endlocal

@pause
