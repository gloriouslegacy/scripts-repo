@echo off

set "hostsFile=%SystemRoot%\System32\drivers\etc\hosts"
set "tempFile=%temp%\hosts_temp.txt"

REM 임시 파일에 주소 추가
echo. >> %tempFile% # 빈 줄 삽입
echo # Daum PotPlayer Adblock >> %tempFile%
echo 127.0.0.1 p1-play.edge4k.com >> %tempFile%
echo 127.0.0.1 p2-play.edge4k.com >> %tempFile%
echo 127.0.0.1 p1-play.kgslb.com >> %tempFile%
echo 127.0.0.1 kyson.ad.daum.net >> %tempFile%
echo 127.0.0.1 display.ad.daum.net # Unable to watch live. >> %tempFile%
echo 127.0.0.1 analytics.ad.daum.net # Unable to watch live. >> %tempFile%

REM 임시 파일의 내용을 호스트 파일에 추가합니다.
type %tempFile% >> %hostsFile%

REM 임시 파일 삭제
del %tempFile%

echo 호스트 파일에 주소가 성공적으로 추가되었습니다!
pause
