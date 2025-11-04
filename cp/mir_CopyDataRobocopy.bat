@echo off
REM ##########################################################################
REM # .bat 파일을 사용하여 Robocopy PowerShell 스크립트 실행
REM # Robocopy 스크립트 파일명: CopyDataRobocopy.ps1
REM ##########################################################################

REM 스크립트가 현재 .bat 파일과 같은 폴더에 있다고 가정합니다.
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_NAME=CopyDataRobocopy.ps1"
set "FULL_SCRIPT_PATH=%SCRIPT_DIR%%SCRIPT_NAME%"

REM 실행에 필요한 매개변수 설정
REM 원본 경로 설정
set "SOURCE_DIR=C:\YourDataFolder"
REM 대상 경로 설정
set "DEST_DIR=D:\YourBackupLocation"
REM 제외할 파일 패턴 (쉼표로 구분)
set "EXCLUDE_FILES=*.tmp", "*.log", "*.bak"
REM 제외할 폴더 이름 (쉼표로 구분)
set "EXCLUDE_DIRS=Temp", "Cache", "Old"

REM PowerShell 실행 정책을 우회하여 스크립트를 실행합니다.
REM -ExecutionPolicy Bypass: 현재 세션에만 적용되는 실행 정책 우회
REM -File: 실행할 스크립트 파일 지정
REM -- (매개변수): 스크립트에 전달할 매개변수 시작
powershell.exe -ExecutionPolicy Bypass -File "%FULL_SCRIPT_PATH%" ^
    -SourcePath "%SOURCE_DIR%" ^
    -DestinationPath "%DEST_DIR%" ^
    -ExcludeFile "%EXCLUDE_FILES%" ^
    -ExcludeDir "%EXCLUDE_DIRS%"

if errorlevel 0 (
    echo.
    echo ✅ 데이터 복사 스크립트가 성공적으로 완료되었거나 Robocopy에서 경고가 발생했습니다 (종료 코드 0-7).
    echo.
) else (
    echo.
    echo ❌ 오류: 데이터 복사 스크립트 실행 또는 Robocopy에서 심각한 오류가 발생했습니다 (종료 코드 8 이상).
    echo Robocopy 로그 파일을 확인하십시오.
    echo.
)

pause