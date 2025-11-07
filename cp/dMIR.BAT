@ECHO OFF
COLOR 0f
MODE CON COLS=110 LINES=45
::MODE CON COLS=80 LINES=45
::CD /d %tmp%
::PUSHD %~dp0
::MODE CON COLS=68 LINES=35


SET US=%username%

set Documents=%USERPROFILE%\Documents
set Music=%USERPROFILE%\Music
set Downloads=%USERPROFILE%\Downloads
set Videos=%USERPROFILE%\Videos
set Pictures=%USERPROFILE%\Pictures
set Favorites=%USERPROFILE%\Favorites
set Desktop=%USERPROFILE%\Desktop


	ECHO.
	ECHO. *** %COMPUTERNAME% %US% 백업 Start %DATE% %TIME% 


	IF NOT EXIST "D:\%US%" MKDIR "D:\%US%\ezBAKlog"


for /f "tokens=1 delims=" %%c in ('dir /b /a:d /a:-h c:\Users\%US%') do ( echo [%date% %time%] Start %%c bak... & robocopy c:\Users\%US%\%%c d:\%US%\%%c /e /xa:h /w:0 /r:5 /log:d:\%US%\ezBAKlog\bak_%%c_%date%.log & echo [%date% %time%] Compete %%c bak. )

:TaskbarbakM
	ECHO [%date% %time%] Start TaskBar bak...
	
		MKDIR "D:\%US%\Taskbar"

	ROBOCOPY "%USERPROFILE%\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar" "D:\%US%\Taskbar" /E /XA:H /W:0 /R:5 > D:\%US%\ezBAKlog\bak_TaskBar_%date%.log
	REG EXPORT HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband "D:\%US%\Taskbar\Taskbar-Pinned-Apps-Backup.reg" /y
	
::	Call :Color 0A " = 작업표시줄 백업 COMPLETE " 0 & echo 　%date% %time%
	ECHO [%date% %time%] Compete TaskBar bak.

:NPKIbakM

	IF NOT EXIST "%USERPROFILE%\AppData\LocalLow\NPKI" GOTO ChromebakM

	ECHO [%date% %time%] Start NPKI bak...

	ROBOCOPY %USERPROFILE%\AppData\LocalLow\NPKI D:\%US%\NPKI /E /W:0 /R:5 > D:\%US%\ezBAKlog\%date%baklogNPKI.log

::	Call :Color 0A " = 공인 인증서 백업 COMPLETE " 0 & echo 　%date% %time%
	ECHO [%date% %time%] Compete NPKI bak.

:ChromebakM
	IF NOT EXIST "%USERPROFILE%\AppData\Local\Google\Chrome\User Data\Default\Bookmarks.*" GOTO EdgebakM

		TASKKILL /F /IM "chrome.exe" > NUL
		IF NOT EXIST "d:\%US%\Chrome\" MKDIR "d:\%US%\Chrome\"
		
	ECHO [%date% %time%] Start Chrome bak...

	XCOPY "%USERPROFILE%\AppData\Local\Google\Chrome\User Data\Default\Bookmarks.*" "d:\%US%\Chrome\" /C /Y > D:\%US%\ezBAKlog\%date%baklogChrome.log
	
::	Call :Color 0A " = Chrome Bookmarks 백업 COMPLETE " 0 & echo 　%date% %time%	
	ECHO [%date% %time%] Compete Chrome bak.

	
:EdgebakM
	IF NOT EXIST "%USERPROFILE%\AppData\Local\Microsoft\Edge\User Data\Default\Bookmarks.*" GOTO StickybakM

		TASKKILL /F /IM "msedge.exe" > NUL
		IF NOT EXIST "d:\%US%\msEdge\" MKDIR "d:\%USM%\msEdge\"
		
	ECHO [%date% %time%] Start msEdge bak...

	XCOPY "%USERPROFILE%\AppData\Local\Microsoft\Edge\User Data\Default\Bookmarks.*" "d:\%US%\msEdge\" /C /Y > D:\%US%\ezBAKlog\%date%baklogmsEdge.log
	
::	Call :Color 0A " = Edge Bookmarks 백업 COMPLETE " 0 & echo 　%date% %time%	
	ECHO [%date% %time%] Compete msEdge bak.


:StickybakM
	ECHO [%date% %time%] Start Sticky-Notes bak...

:WIN7StickybakM

IF NOT EXIST "%USERPROFILE%\AppData\Roaming\Microsoft\Sticky Notes\StickyNotes.snt" GOTO WIN10StickybakM
IF EXIST "%USERPROFILE%\AppData\Roaming\Microsoft\Sticky Notes\StickyNotes.snt" MKDIR "D:\%US%\bakWIN7StickyNote"
ROBOCOPY "%USERPROFILE%\AppData\Roaming\Microsoft\Sticky Notes" "D:\%US%\bakWIN7StickyNote\Sticky Notes" /E /W:0 /R:5 > D:\%US%\ezBAKlog\%date%baklogStickyNotes.log

:WIN10StickybakM

IF NOT EXIST "%USERPROFILE%\AppData\Local\Packages\Microsoft.MicrosoftStickyNotes_8wekyb3d8bbwe\LocalState\plum.sqlite" GOTO WLANbakM
IF EXIST "%USERPROFILE%\AppData\Local\Packages\Microsoft.MicrosoftStickyNotes_8wekyb3d8bbwe\LocalState\plum.sqlite" MKDIR "D:\%US%\ezBAKlog\bakWIN10StickyNote"
ROBOCOPY "%USERPROFILE%\AppData\Local\Packages\Microsoft.MicrosoftStickyNotes_8wekyb3d8bbwe\LocalState" "D:\%US%\bakWIN10StickyNote" /E /W:0 /R:10 > "D:\%US%\ezBAKlog\%date%baklogStickyNotesWIN10.log"

::	Call :Color 0A " = 스티커 노트 백업 COMPLETE " 0 & echo 　%date% %time%
	ECHO [%date% %time%] Compete Sticky-Notes bak.

:WLANbakM
	ECHO [%date% %time%] Start WLAN bak...

	IF NOT EXIST "D:\%US%\WLAN" MKDIR D:\%US%\WLAN

	netsh wlan export profile key=clear folder=d:\%US%\WLAN

::	Call :Color 0A " = WLNA Profile 백업 COMPLETE " 0 & echo 　%date% %time%
	ECHO [%date% %time%] Compete WLAN bak.

GOTO dMIR
 
:dMIR

ECHO [START] userDATA BAK %date% %time%

ECHO [MOUNT] userDATA BAK %date% %time%

MOUNTVOL V: \\?\Volume{b1781c89-0000-0000-0000-100000000000}\

ROBOCOPY "D:\%US%" V: /MIR /XA:H /LOG:D:\LOG_D_BAK.LOG /TEE

TIMEOUT 3 > NUL

MOUNTVOL V: /D

ECHO [UNMOUNT] userDATA BAK %date% %time%

ECHO [COMPLETE] userDATA BAK %date% %time%

TIMEOUT 3 > NUL

EXIT/B