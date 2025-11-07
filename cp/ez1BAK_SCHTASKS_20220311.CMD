@ECHO OFF
COLOR 0f
MODE CON COLS=110 LINES=45
::MODE CON COLS=80 LINES=45
::CD /d %tmp%
::PUSHD %~dp0
::MODE CON COLS=68 LINES=35

:: 관리자 권한
@reg query HKU\S-1-5-20>nul || (PowerShell start -verb runas '%0'&exit)


SET US=%username%

set Documents=%USERPROFILE%\Documents
set Music=%USERPROFILE%\Music
set Downloads=%USERPROFILE%\Downloads
set Videos=%USERPROFILE%\Videos
set Pictures=%USERPROFILE%\Pictures
set Favorites=%USERPROFILE%\Favorites
set Desktop=%USERPROFILE%\Desktop

::BEEP
SET i=0

TITLE ez1BAK                      by 8228


	set todayDate=%date:~0,4%%date:~5,2%%date:~8,2%
	set todayTime=%time:~0,2%%time:~3,2%%time:~6,2%

::자동 백업 --------------------------------------------------------------------------------------------------------------

:Backup

	IF NOT EXIST D:\ GOTO BAKERROR
	IF EXIST D:\ez1BAKlog.LOG DEL /F /Q D:\ez1BAKlog.LOG

ECHO %US% MIRRORING START %DATE% %TIME% 


for /f "tokens=1 delims=" %%c in ('dir /b /a:d /a:-h c:\Users\%US%') do ( echo [%date% %time%] Start %%c bak... & robocopy c:\Users\%US%\%%c d:\%US%\%%c /MIR /xa:h /w:0 /r:5 >> D:\ez1BAKlog.LOG & echo [%date% %time%] Compete %%c bak. )

:TaskbarbakM
	ECHO [%date% %time%] Start TaskBar bak...
	
		MKDIR "D:\%US%\Taskbar"

	ROBOCOPY "%USERPROFILE%\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar" "D:\%US%\Taskbar" /MIR /XA:H /W:0 /R:5 >> D:\ez1BAKlog.LOG
	REG EXPORT HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband "D:\%US%\Taskbar\Taskbar-Pinned-Apps-Backup.reg" /y
	
::	Call :Color 0A " = TASKBAR COMPLETE " 0 & echo 　%date% %time%
	ECHO [%date% %time%] Compete TaskBar bak.


:NPKIbakM

	IF NOT EXIST "%USERPROFILE%\AppData\LocalLow\NPKI" GOTO ChromebakM

	ECHO [%date% %time%] Start NPKI bak...

	ROBOCOPY %USERPROFILE%\AppData\LocalLow\NPKI D:\%US%\NPKI /MIR /W:0 /R:5 >> D:\ez1BAKlog.LOG

::	Call :Color 0A " = 공인 인증서 백업 COMPLETE " 0 & echo 　%date% %time%
	ECHO [%date% %time%] Compete NPKI bak.


:StickybakM
	ECHO [%date% %time%] Start Sticky-Notes bak...

:WIN7StickybakM

IF NOT EXIST "%USERPROFILE%\AppData\Roaming\Microsoft\Sticky Notes\StickyNotes.snt" GOTO WIN10StickybakM
IF EXIST "%USERPROFILE%\AppData\Roaming\Microsoft\Sticky Notes\StickyNotes.snt" MKDIR "D:\%US%\bakWIN7StickyNote"
ROBOCOPY "%USERPROFILE%\AppData\Roaming\Microsoft\Sticky Notes" "D:\%US%\bakWIN7StickyNote\Sticky Notes" /MIR /W:0 /R:5 >> D:\ez1BAKlog.LOG

:WIN10StickybakM

IF NOT EXIST "%USERPROFILE%\AppData\Local\Packages\Microsoft.MicrosoftStickyNotes_8wekyb3d8bbwe\LocalState\plum.sqlite" GOTO WLANbakM
IF EXIST "%USERPROFILE%\AppData\Local\Packages\Microsoft.MicrosoftStickyNotes_8wekyb3d8bbwe\LocalState\plum.sqlite" MKDIR "D:\%US%\ezBAKlog\bakWIN10StickyNote"
ROBOCOPY "%USERPROFILE%\AppData\Local\Packages\Microsoft.MicrosoftStickyNotes_8wekyb3d8bbwe\LocalState" "D:\%US%\bakWIN10StickyNote" /MIR /W:0 /R:10 >> D:\ez1BAKlog.LOG

::	Call :Color 0A " = Sticky bakup COMPLETE " 0 & echo 　%date% %time%
	ECHO [%date% %time%] Compete Sticky-Notes bak.

:WLANbakM
	ECHO [%date% %time%] Start WLAN bak...

	IF NOT EXIST "D:\%US%\WLAN" MKDIR D:\%US%\WLAN

	netsh wlan export profile key=clear folder=d:\%US%\WLAN

::	Call :Color 0A " = WLNA Profile backup COMPLETE " 0 & echo 　%date% %time%
	ECHO [%date% %time%] Compete WLAN bak.


ECHO %US% MIRRORING COMMPLETE %DATE% %TIME% 

TIMEOUT 3 > NUL

EXIT

:BAKERROR

ECHO D 드라이브가 존재하지 않습니다. 
ECHO D 드라이브 설정 후 실행 바랍니다.
ECHO.

PAUSE 
TIMEOUT 2 > NUL
EXIT