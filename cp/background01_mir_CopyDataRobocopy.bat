@echo off

set "SCRIPT_DIR=%~dp0"
set "FULL_SCRIPT_PATH=%SCRIPT_DIR%mir_CopyDataRobocopy.ps1"

REM 매개변수 설정 (이전과 동일)
set "SOURCE_DIR=C:\Users\bigboss01"
set "DEST_DIR=F:\testps1"
set "EXCLUDE_FILES=*.tmp *.log *.bak"
set "EXCLUDE_DIRS=Temp Cache Old"

REM Start-Process를 사용하여 PowerShell 스크립트를 숨겨진 창으로 실행합니다.
powershell.exe -ExecutionPolicy Bypass -Command "Start-Process -FilePath 'powershell.exe' -ArgumentList '-ExecutionPolicy Bypass -File \"%FULL_SCRIPT_PATH%\" -SourcePath \"%SOURCE_DIR%\" -DestinationPath \"%DEST_DIR%\" -ExcludeFile %EXCLUDE_FILES% -ExcludeDir %EXCLUDE_DIRS%' -WindowStyle Hidden"

echo 백그라운드 작업이 시작되었습니다.
echo 자세한 내용은 스크립트 디렉토리에 생성되는 로그 파일을 확인하십시오.

pause