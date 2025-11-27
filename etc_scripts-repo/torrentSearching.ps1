Write-Host "`n"
$query = Read-Host " 토렌트 검색어를 입력하세요"
$ToUrls = @(
"https://w22.torrentten11.com/bbs/search.php?url=https%3A%2F%2Ftorrentten.com%2Fbbs%2Fsearch.php&stx=$query","https://torrentqq257.com/search?q=$query",
"https://w89.torrentpi17.com/bbs/search.php?url=https%3A%2F%2Fw89.torrentpi17.com%2Fbbs%2Fsearch.php&stx=$query",
"https://www.torrentreel29.site/search.php?b_id=tmovie&sc=$query",
"https://t40.heytorrent12.com/bbs/search.php?url=https%3A%2F%2Ft40.heytorrent12.com%2Fbbs%2Fsearch.php&stx=$query",
"https://t12.bbigtorrent12.com/bbs/search.php?url=https%3A%2F%2Ft12.bbigtorrent12.com%2Fbbs%2Fsearch.php&stx=$query",
"https://torrentjok1.com/bbs/search.php?url=https%3A%2F%2Ftorrentjok1.com%2Fbbs%2Fsearch.php&stx=$query",
"https://torrentmobile100.com/bbs/search.php?url=https%3A%2F%2Ftorrentmobile100.com%2Fbbs%2Fsearch.php&stx=$query",
"https://t55.torrenthoya34.site/bbs/search.php?url=https%3A%2F%2Ft55.torrenthoya34.site%2Fbbs%2Fsearch.php&stx=$query",
"https://w32.torrentnx16.com/bbs/search.php?url=https%3A%2F%2Fw32.torrentnx16.com%2Fbbs%2Fsearch.php&stx=$query"
)
# ForEach($Site in $ToUrls){ Start-Process "C:\Program Files\Google\Chrome\Application\chrome.exe" $Site }
ForEach($Site in $ToUrls){ Start-Process "C:\Program Files\Mozilla Firefox\firefox.exe" $Site }