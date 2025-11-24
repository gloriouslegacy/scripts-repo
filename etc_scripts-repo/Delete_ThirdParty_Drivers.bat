@echo off
setlocal

:: =========================================================
:: 1. 관리자 권한 확인 및 UAC 프롬프트 요청
:: =========================================================
NET SESSION >NUL 2>&1
IF %ERRORLEVEL% NEQ 0 (
    ECHO 관리자 권한으로 재실행 중...
    GOTO RERUN_ADMIN
)
GOTO EXECUTE_SCRIPT

:RERUN_ADMIN
    ECHO Set UAC = CreateObject("WScript.Shell") > "%temp%\getadmin.vbs"
    ECHO UAC.Run "cmd /k ""%~s0""", 0, True >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    DEL "%temp%\getadmin.vbs"
EXIT

:EXECUTE_SCRIPT
    CLS
    ECHO ------------------------------------------------------------------
    ECHO  경고: 모든 타사 드라이버 패키지 제거 스크립트가 실행됩니다.
    ECHO          이 작업은 시스템을 불안정하게 만들 수 있습니다.
    ECHO ------------------------------------------------------------------

    ECHO.
    ECHO 계속 진행하시려면 'Y'를 입력하세요: 
    SET /P CONFIRM="> "

    IF /I NOT "%CONFIRM%"=="Y" (
        ECHO 작업이 취소되었습니다.
        GOTO :END
    )

    ECHO.
    ECHO 제거할 타사 드라이버 목록을 생성 중...

    :: =========================================================
    :: 2. 타사 드라이버 목록 추출 (Published Name)
    :: =========================================================
    :: 임시 파일에 pnputil의 출력 중 "Published name : oem"으로 시작하는 라인만 저장
    pnputil /enum-drivers | findstr /i /c:"Published name : oem" > "%temp%\driver_list.txt"

    ECHO.
    ECHO 제거 작업 시작...
    SET REMOVED_COUNT=0

    :: =========================================================
    :: 3. 드라이버 제거 반복 실행
    :: =========================================================
    :: 파일에서 "Published name : oemXX.inf" 부분만 파싱하여 제거 명령 실행
    FOR /F "tokens=1,2,3,4,5* delims= " %%A IN ('type "%temp%\driver_list.txt"') DO (
        :: %%E는 oemXX.inf 드라이버 파일 이름입니다.
        IF "%%D"=="name" IF "%%E"==":" (
            SET DRIVER_INF=%%F
            
            ECHO 드라이버 제거 중: !DRIVER_INF!
            
            :: /force 옵션을 사용하여 드라이버가 사용 중이더라도 강제로 제거 시도
            pnputil /delete-driver !DRIVER_INF! /force >NUL 2>&1
            
            IF !ERRORLEVEL! EQU 0 (
                ECHO 성공적으로 제거됨: !DRIVER_INF!
                SET /A REMOVED_COUNT+=1
            ) ELSE (
                ECHO 제거 실패 (오류 코드 %ERRORLEVEL%): !DRIVER_INF!
            )
        )
    )

    ECHO.
    ECHO ------------------------------------------------------------------
    ECHO 제거 작업 완료. 총 !REMOVED_COUNT!개의 드라이버 패키지가 제거되었습니다.
    ECHO ------------------------------------------------------------------
    ECHO.
    ECHO **즉시 시스템을 재부팅해야 합니다.**

    :: =========================================================
    :: 4. 정리
    :: =========================================================
    DEL "%temp%\driver_list.txt" >NUL 2>&1

:END
    pause
    EXIT /B