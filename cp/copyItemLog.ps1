# Get-ExecutionPolicy
# Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned

# [string]$LogFile = "C:\Temp\CopyLog-$(Get-Date -Format 'yyyyMMdd-HHmmss').log",
# .\copyItemLog.ps1 -SourcePath "C:\Data" -DestinationPath "D:\Backup" -LogFile "D:\Logs\MyCustomLog.log"

# .tmp 파일과 .bak 파일을 제외하고 복사
#.\Copy-Data-Advanced.ps1 `
#    -SourcePath "C:\Data" `
#    -DestinationPath "D:\Backup" `
#    -Exclude "*.tmp", "*.bak"

# 로컬에서 원격 서버로 복사
#.\Copy-Data-Advanced.ps1 `
#    -SourcePath "C:\LocalData" `
#    -DestinationPath "\\RemoteServer\ShareName\BackupFolder"

# 원격 서버에서 로컬로 복사
#.\Copy-Data-Advanced.ps1 `
#    -SourcePath "\\RemoteServer\ShareName\SourceFolder" `
#    -DestinationPath "C:\LocalDownload"

# 스크립트 실행 시 필요한 매개변수를 정의
param(
    [Parameter(Mandatory=$true)]
    [string]$SourcePath,

    [Parameter(Mandatory=$true)]
    [string]$DestinationPath,

    [string]$LogFile = "C:\Temp\CopyLog-$(Get-Date -Format 'yyyyMMdd-HHmmss').log",

    # 새로운 매개변수: 복사에서 제외할 확장자 목록 (예: *.tmp, *.bak)
    [string[]]$Exclude = @() 
)

# 인코딩 설정: .NET 클래스에서 사용할 UTF-16 인코딩 객체 정의 (Unicode)
$UnicodeEncoding = [System.Text.Encoding]::Unicode


# 1. 로그 시작 기록 및 시간 측정 시작$StartTime = Get-Date
$LogHeader = "=== 데이터 복사 작업 시작: $($StartTime) ==="
# Out-File (덮어쓰기) -> [System.IO.File]::WriteAllText 사용
[System.IO.File]::WriteAllText($LogFile, "$LogHeader`r`n", $UnicodeEncoding)

# Out-File -Append -> [System.IO.File]::AppendAllText 사용
[System.IO.File]::AppendAllText($LogFile, "원본 경로: $SourcePath`r`n", $UnicodeEncoding)
[System.IO.File]::AppendAllText($LogFile, "대상 경로: $DestinationPath`r`n", $UnicodeEncoding)
if ($Exclude.Count -gt 0) {
    [System.IO.File]::AppendAllText($LogFile, "제외 패턴: $($Exclude -join ', ')`r`n", $UnicodeEncoding)
}
[System.IO.File]::AppendAllText($LogFile, "---`r`n", $UnicodeEncoding)


# 2. 복사 전 전체 용량 및 파일 목록 확인 
try {
    # Get-ChildItem으로 모든 항목을 재귀적으로 가져오고, 제외 패턴을 적용합니다.
    $PreCopyData = Get-ChildItem -Path $SourcePath -Recurse -Exclude $Exclude -ErrorAction Stop | Where-Object { -not $_.PSIsContainer }
    
    $TotalSizeBeforeCopy_Bytes = $PreCopyData | Measure-Object -Property Length -Sum | Select-Object -ExpandProperty Sum
    $TotalSizeBeforeCopy_GB = $TotalSizeBeforeCopy_Bytes / 1GB

    [System.IO.File]::AppendAllText($LogFile, "✅ 복사 전 원본 폴더($SourcePath)의 **총 용량** (제외 파일 제외): $($TotalSizeBeforeCopy_GB.ToString('N2')) GB`r`n", $UnicodeEncoding)
    [System.IO.File]::AppendAllText($LogFile, "총 복사 대상 파일 수: $($PreCopyData.Count) 개`r`n", $UnicodeEncoding)
    [System.IO.File]::AppendAllText($LogFile, "---`r`n", $UnicodeEncoding)
}
catch {
    [System.IO.File]::AppendAllText($LogFile, "❌ 오류: 복사 전 원본 용량 확인 중 오류 발생 - $($_.Exception.Message)`r`n", $UnicodeEncoding)
    Exit
}

# 3. 데이터 복사 실행
[System.IO.File]::AppendAllText($LogFile, "📦 데이터 복사 시작...`r`n", $UnicodeEncoding)
try {
    # Copy-Item을 사용하여 원본 폴더의 모든 내용(*), 하위 폴더 포함(-Recurse) 복사
    # -Exclude 매개변수를 추가하여 지정된 파일을 제외합니다.
    Copy-Item -Path "$SourcePath\*" -Destination $DestinationPath -Recurse -Force -Exclude $Exclude -ErrorAction Stop
    [System.IO.File]::AppendAllText($LogFile, "✅ 데이터 복사 완료.`r`n", $UnicodeEncoding)
}
catch {
    [System.IO.File]::AppendAllText($LogFile, "❌ 오류: 데이터 복사 중 오류 발생 - $($_.Exception.Message)`r`n", $UnicodeEncoding)
    Exit
}
[System.IO.File]::AppendAllText($LogFile, "---`r`n", $UnicodeEncoding)

# 4. 복사 후 용량 확인 및 결과 로깅
try {
    # 복사된 대상 폴더의 용량을 확인합니다. (제외된 파일은 당연히 대상 폴더에 없어야 합니다.)
    $PostCopyData = Get-ChildItem -Path $DestinationPath -Recurse -Exclude $Exclude -ErrorAction Stop | Where-Object { -not $_.PSIsContainer }
    $TotalSizeAfterCopy_Bytes = $PostCopyData | Measure-Object -Property Length -Sum | Select-Object -ExpandProperty Sum
    $TotalSizeAfterCopy_GB = $TotalSizeAfterCopy_Bytes / 1GB

    [System.IO.File]::AppendAllText($LogFile, "✅ 복사 후 대상 폴더($DestinationPath)의 **확인된 용량**: $($TotalSizeAfterCopy_GB.ToString('N2')) GB`r`n", $UnicodeEncoding)
    [System.IO.File]::AppendAllText($LogFile, "총 복사된 파일 수: $($PostCopyData.Count) 개`r`n", $UnicodeEncoding)

    # 최종 용량 비교 및 결과 메시지
    if ($TotalSizeBeforeCopy_Bytes -eq $TotalSizeAfterCopy_Bytes -and $PreCopyData.Count -eq $PostCopyData.Count) {
        [System.IO.File]::AppendAllText($LogFile, "🎉 복사 전후 용량과 파일 수가 일치합니다. 복사 성공.`r`n", $UnicodeEncoding)
    } else {
        [System.IO.File]::AppendAllText($LogFile, "⚠️ 경고: 복사 전후 용량 또는 파일 수가 일치하지 않습니다. 데이터 복사를 확인하십시오.`r`n", $UnicodeEncoding)
    }
}
catch {
    [System.IO.File]::AppendAllText($LogFile, "❌ 오류: 복사 후 대상 용량 확인 중 오류 발생 - $($_.Exception.Message)`r`n", $UnicodeEncoding)
}
[System.IO.File]::AppendAllText($LogFile, "---`r`n", $UnicodeEncoding)

# 5. 작업 소요 시간 기록
$EndTime = Get-Date
$TimeTaken = $EndTime - $StartTime
[System.IO.File]::AppendAllText($LogFile, "⏱️ 총 소요 시간: $($TimeTaken.Hours) 시간 $($TimeTaken.Minutes) 분 $($TimeTaken.Seconds) 초`r`n", $UnicodeEncoding)

[System.IO.File]::AppendAllText($LogFile, "=== 데이터 복사 작업 종료: $($EndTime) ===`r`n", $UnicodeEncoding)

# 최종 사용자 피드백
Write-Host "스크립트 실행이 완료되었습니다. 결과는 다음 로그 파일에서 확인하세요:" -ForegroundColor Green
Write-Host $LogFile -ForegroundColor Yellow