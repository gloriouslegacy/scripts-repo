@echo off
setlocal enabledelayedexpansion

:: UAC 관리자 권한 요청
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo 관리자 권한을 요청합니다...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )
    pushd "%CD%"
    CD /D "%~dp0"

echo ============================================
echo KakaoTalk 관리자 권한 바로가기 생성 스크립트
echo ============================================
echo.

:: KakaoTalk.exe 경로 찾기
set "KAKAO_PATH="

if exist "C:\Program Files (x86)\Kakao\KakaoTalk\KakaoTalk.exe" (
    set "KAKAO_PATH=C:\Program Files (x86)\Kakao\KakaoTalk"
) else if exist "C:\Program Files\Kakao\KakaoTalk\KakaoTalk.exe" (
    set "KAKAO_PATH=C:\Program Files\Kakao\KakaoTalk"
)

if not defined KAKAO_PATH (
    echo [오류] KakaoTalk.exe를 찾을 수 없습니다.
    pause
    exit /B 1
)

echo [정보] KakaoTalk 경로: %KAKAO_PATH%
echo.

:: kaTalk.exe로 복사
echo [1/4] KakaoTalk.exe를 kaTalk.exe로 복사 중...
copy /Y "%KAKAO_PATH%\KakaoTalk.exe" "%KAKAO_PATH%\kaTalk.exe" >nul
if %errorlevel% NEQ 0 (
    echo [오류] 파일 복사 실패
    pause
    exit /B 1
)
echo       완료

:: 바탕화면에 관리자 권한 바로가기 생성
echo [2/4] 바탕화면에 관리자 권한 바로가기 생성 중...
set "DESKTOP=%USERPROFILE%\Desktop"

:: VBScript로 관리자 권한 바로가기 생성
echo Set oWS = WScript.CreateObject("WScript.Shell") > "%temp%\CreateShortcut.vbs"
echo sLinkFile = "%DESKTOP%\kaTalk.lnk" >> "%temp%\CreateShortcut.vbs"
echo Set oLink = oWS.CreateShortcut(sLinkFile) >> "%temp%\CreateShortcut.vbs"
echo oLink.TargetPath = "%KAKAO_PATH%\kaTalk.exe" >> "%temp%\CreateShortcut.vbs"
echo oLink.WorkingDirectory = "%KAKAO_PATH%" >> "%temp%\CreateShortcut.vbs"
echo oLink.Save >> "%temp%\CreateShortcut.vbs"
cscript //nologo "%temp%\CreateShortcut.vbs"
del "%temp%\CreateShortcut.vbs"

:: 관리자 권한 설정 (ShellLinkObject 사용)
powershell -Command "$s=(New-Object -ComObject WScript.Shell).CreateShortcut('%DESKTOP%\kaTalk.lnk');$s.Save();$bytes=[System.IO.File]::ReadAllBytes('%DESKTOP%\kaTalk.lnk');$bytes[0x15]=$bytes[0x15]-bor 0x20;[System.IO.File]::WriteAllBytes('%DESKTOP%\kaTalk.lnk',$bytes)"
echo       완료

:: 시작프로그램에 바로가기 복사
echo [3/4] 시작프로그램에 바로가기 등록 중...
set "STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
copy /Y "%DESKTOP%\kaTalk.lnk" "%STARTUP%\kaTalk.lnk" >nul
echo       완료

:: 시작앱에서 KakaoTalk 제거
echo [0/4] 시작앱에서 KakaoTalk 제거 중...
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "KakaoTalk" /f 2>nul
if %errorlevel% EQU 0 (
    echo       현재 사용자 시작앱에서 삭제 완료
) else (
    echo       현재 사용자 시작앱에 등록된 항목 없음
)
reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" /v "KakaoTalk" /f 2>nul
if %errorlevel% EQU 0 (
    echo       모든 사용자 시작앱에서 삭제 완료
) else (
    echo       모든 사용자 시작앱에 등록된 항목 없음
)
echo.

echo.
echo ============================================
echo [완료] 모든 작업이 완료되었습니다.
echo.
echo - 시작앱에서 KakaoTalk 제거됨
echo - kaTalk.exe 위치: %KAKAO_PATH%\kaTalk.exe
echo - 바탕화면 바로가기: %DESKTOP%\kaTalk.lnk
echo - 시작프로그램: %STARTUP%\kaTalk.lnk
echo ============================================
echo.
pause