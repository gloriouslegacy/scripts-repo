@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul 2>&1
echo ========================================
echo Windows Defender Control EXE 빌드
echo ========================================
echo.

REM Python 설치 확인
python --version >nul 2>&1
if !errorLevel! neq 0 (
    echo [오류] Python이 설치되어 있지 않습니다.
    echo Python을 먼저 설치해주세요: https://www.python.com/downloads/
    echo.
    pause
    exit /b 1
)

echo [확인] Python 설치됨
python --version
echo.

REM PyInstaller 설치 확인 및 설치
echo PyInstaller 확인 중...
pip show pyinstaller >nul 2>&1
if !errorLevel! neq 0 (
    echo PyInstaller가 설치되어 있지 않습니다.
    echo PyInstaller를 설치합니다...
    pip install pyinstaller
    if !errorLevel! neq 0 (
        echo [오류] PyInstaller 설치 실패
        pause
        exit /b 1
    )
)

echo [확인] PyInstaller 설치됨
echo.

REM 기존 빌드 폴더 삭제
if exist build rmdir /s /q build
if exist dist rmdir /s /q dist
if exist winDefenderControl.spec del /q winDefenderControl.spec
echo 이전 빌드 폴더 정리 완료
echo.

REM 아이콘 파일 확인 및 경로 설정
set ICON_FILE=
set ADD_DATA=
set VERSION_FILE=

if exist "icon\winDefender.ico" (
    set ICON_FILE=--icon="icon\winDefender.ico"
    REM ADD_DATA 옵션은 따옴표로 감싸진 채 변수에 저장됩니다.
    set ADD_DATA=--add-data "icon\winDefender.ico;icon" --add-data "icon\winDefender.png;icon"
    echo [확인] 아이콘 파일 발견
) else (
    echo [경고] 아이콘 파일이 없어 EXE 아이콘이 기본값으로 설정됩니다.
)

if exist "version_info.txt" (
    set VERSION_FILE=--version-file "version_info.txt"
    echo [확인] 버전 정보 파일 발견
) else (
    echo [경고] version_info.txt 파일이 없어 버전 정보 없이 빌드됩니다.
)
echo.

REM EXE 빌드
echo ========================================
echo EXE 파일 빌드 시작...
echo ========================================
echo.

REM **최종 수정**: !VERSION_FILE!과 !ADD_DATA! 변수를 감싼 큰따옴표를 제거합니다.
pyinstaller --onefile --windowed --name "winDefenderControl" --clean --uac-admin !VERSION_FILE! !ICON_FILE! !ADD_DATA! winDefenderControl.py

if %ERRORLEVEL% neq 0 (
    echo.
    echo [오류] 빌드 실패
    echo.
    pause
    exit /b 1
)

echo.
echo ========================================
echo 빌드 완료!
echo ========================================
echo.

REM 빌드 결과물 확인
if exist "dist\winDefenderControl.exe" (
    echo [성공] EXE 파일이 생성되었습니다!
    echo.
    echo 생성된 파일 위치: dist\winDefenderControl.exe
    echo.
    for %%A in ("dist\winDefenderControl.exe") do (
        echo 파일 크기: %%~zA bytes
    )
    echo.
) else (
    echo [오류] EXE 파일을 찾을 수 없습니다.
    echo dist 폴더를 확인해주세요.
)

echo.
pause