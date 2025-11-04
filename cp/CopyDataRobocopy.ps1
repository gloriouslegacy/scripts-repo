# Get-ExecutionPolicy
# Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned

#.\CopyDataRobocopy.ps1 `
#    -SourcePath "C:\Data" `
#    -DestinationPath "D:\Backup" `
#    -ExcludeFile "*.tmp", "*.log" `
#    -ExcludeDir "Temp", "Cache"

param(
    [Parameter(Mandatory=$true)]
    [string]$SourcePath,

    [Parameter(Mandatory=$true)]
    [string]$DestinationPath,

    [string]$ScriptDir = $PSScriptRoot,
    [string]$RobocopyLogFile = "$ScriptDir\RobocopyLog-$(Get-Date -Format 'yyyyMMdd-HHmmss').log",
    
    [string[]]$ExcludeFile = @(), 
    [string[]]$ExcludeDir = @()   
)

# 인코딩 설정: .NET 클래스에서 사용할 UTF-16 인코딩 객체 정의
$UnicodeEncoding = [System.Text.Encoding]::Unicode
# Robocopy 출력이 깨지는 현상을 해결하기 위해 콘솔/출력 인코딩을 CP949로 설정
$OutputEncoding = [System.Text.Encoding]::GetEncoding(949)


# 1. 로그 시작 기록 및 시간 측정 시작
$StartTime = Get-Date
$LogHeader = "=== Robocopy 데이터 복사 작업 시작: $($StartTime) ==="
# .NET 클래스로 최초 로그 쓰기 (덮어쓰기)
[System.IO.File]::WriteAllText($RobocopyLogFile, "$LogHeader`r`n", $UnicodeEncoding)

# .NET 클래스로 로그 추가 (AppendAllText)
[System.IO.File]::AppendAllText($RobocopyLogFile, "원본 경로: $SourcePath`r`n", $UnicodeEncoding)
[System.IO.File]::AppendAllText($RobocopyLogFile, "대상 경로: $DestinationPath`r`n", $UnicodeEncoding)
if ($ExcludeFile.Count -gt 0) {
    [System.IO.File]::AppendAllText($RobocopyLogFile, "제외 파일 패턴: $($ExcludeFile -join ', ')`r`n", $UnicodeEncoding)
}
if ($ExcludeDir.Count -gt 0) {
    [System.IO.File]::AppendAllText($RobocopyLogFile, "제외 폴더: $($ExcludeDir -join ', ')`r`n", $UnicodeEncoding)
}
[System.IO.File]::AppendAllText($RobocopyLogFile, "---`r`n", $UnicodeEncoding)


# 2. 복사 전 전체 용량 및 파일 목록 확인
try {
    $PreCopyData = Get-ChildItem -Path $SourcePath -Recurse -ErrorAction Stop | Where-Object { 
        -not $_.PSIsContainer 
    }
    
    $TotalSizeBeforeCopy_Bytes = $PreCopyData | Measure-Object -Property Length -Sum | Select-Object -ExpandProperty Sum
    $TotalSizeBeforeCopy_GB = $TotalSizeBeforeCopy_Bytes / 1GB

    [System.IO.File]::AppendAllText($RobocopyLogFile, "✅ 복사 전 원본 폴더($SourcePath)의 **총 용량** (전체): $($TotalSizeBeforeCopy_GB.ToString('N2')) GB`r`n", $UnicodeEncoding)
    [System.IO.File]::AppendAllText($RobocopyLogFile, "총 파일 수 (전체): $($PreCopyData.Count) 개`r`n", $UnicodeEncoding)
    [System.IO.File]::AppendAllText($RobocopyLogFile, "---`r`n", $UnicodeEncoding)
}
catch {
    [System.IO.File]::AppendAllText($RobocopyLogFile, "❌ 오류: 복사 전 원본 용량 확인 중 오류 발생 - $($_.Exception.Message)`r`n", $UnicodeEncoding)
    Exit
}


# 3. Robocopy 데이터 복사 실행 (UNILOG+ 사용)

[System.IO.File]::AppendAllText($RobocopyLogFile, "📦 Robocopy 데이터 복사 시작...`r`n", $UnicodeEncoding)
Write-Host "➡️ Robocopy가 별도의 콘솔 창에서 실행되며, 해당 창에서 진행률을 확인할 수 있습니다." -ForegroundColor Yellow
Write-Host "스크립트는 작업 완료 시까지 대기합니다. (로그에 일시적으로 진행률이 기록되지만, 완료 후 제거됩니다.)" -ForegroundColor Yellow

try {
    # 1. 인수를 ArgumentList 배열로 구성
    $RobocopyArgs = @(
        $SourcePath,
        $DestinationPath,
        "/E",          
        "/ZB",         
        "/COPYALL",    
        "/R:5",        
        "/W:5",        
        "/V",          
        "/TEE",        
        "/UNILOG+:""$RobocopyLogFile""" # 유니코드 로그 옵션 (Robocopy 자체 출력)
    )
    
    # ... (제외 패턴 추가 코드 생략) ...
    if ($ExcludeFile.Count -gt 0) {
        $RobocopyArgs += "/XF"
        $RobocopyArgs += $ExcludeFile
    }
    if ($ExcludeDir.Count -gt 0) {
        $RobocopyArgs += "/XD"
        $RobocopyArgs += $ExcludeDir
    }
    
    # 2. Start-Process를 사용하여 Robocopy 실행
    $Command = "robocopy $($RobocopyArgs -join ' ')"
    [System.IO.File]::AppendAllText($RobocopyLogFile, "Robocopy 명령어 구문: $Command`r`n", $UnicodeEncoding)

    $RobocopyProcess = Start-Process -FilePath "robocopy.exe" -ArgumentList $RobocopyArgs -PassThru -Wait
    
    $RobocopyExitCode = $RobocopyProcess.ExitCode
    
    if ($RobocopyExitCode -le 7) {
        [System.IO.File]::AppendAllText($RobocopyLogFile, "✅ Robocopy 복사 완료. 종료 코드: $RobocopyExitCode (성공)`r`n", $UnicodeEncoding)
    } else {
        [System.IO.File]::AppendAllText($RobocopyLogFile, "❌ Robocopy 복사 오류 발생. 종료 코드: $RobocopyExitCode (오류 - 로그 상세 확인 필요)`r`n", $UnicodeEncoding)
    }
}
catch {
    [System.IO.File]::AppendAllText($RobocopyLogFile, "❌ 오류: Robocopy 실행 중 파워쉘 오류 발생 - $($_.Exception.Message)`r`n", $UnicodeEncoding)
    Exit
}
[System.IO.File]::AppendAllText($RobocopyLogFile, "---`r`n", $UnicodeEncoding)


# 4. 로그 파일 후처리 (진행률 라인 제거)
Write-Host "⚙️ 로그 파일에서 진행률 정보 제거 중..." -ForegroundColor Cyan

try {
    # 1. 로그 파일의 모든 내용을 읽어옵니다. (Get-Content는 인코딩 지정 없이 시스템 기본값 사용 - UNICODE 파일은 잘 읽음)
    # Unicode 파일이므로 Get-Content -Encoding을 생략하거나 -Encoding Unicode를 사용해야 함.
    # 안전하게 Get-Content -Encoding Unicode 사용
    $LogContent = Get-Content -Path $RobocopyLogFile -Encoding Unicode
    
    # 2. 진행률(%) 문자열이 포함된 모든 라인을 필터링하여 제외
    $FilteredContent = $LogContent | Where-Object { 
        $_ -notmatch '\s*\d+\.\d+%\r?\s*$' -and 
        $_ -notmatch '\s*\d+%\s+'
    }
    
    # 3. 필터링된 내용을 로그 파일에 덮어씁니다. (Set-Content도 에러를 냈으므로 .NET 클래스로 대체)
    $OutputText = $FilteredContent -join "`r`n"
    [System.IO.File]::WriteAllText($RobocopyLogFile, $OutputText, $UnicodeEncoding)
    
    Write-Host "✅ 진행률 정보가 로그 파일에서 성공적으로 제거되었습니다." -ForegroundColor Green
}
catch {
    [System.IO.File]::AppendAllText($RobocopyLogFile, "❌ 오류: 로그 파일 후처리 중 오류 발생 - $($_.Exception.Message)`r`n", $UnicodeEncoding)
}
[System.IO.File]::AppendAllText($RobocopyLogFile, "---`r`n", $UnicodeEncoding)


# 5. 복사 후 용량 확인 및 결과 로깅
try {
    $PostCopyData = Get-ChildItem -Path $DestinationPath -Recurse -ErrorAction Stop | Where-Object { -not $_.PSIsContainer }
    
    $TotalSizeAfterCopy_Bytes = $PostCopyData | Measure-Object -Property Length -Sum | Select-Object -ExpandProperty Sum
    $TotalSizeAfterCopy_GB = $TotalSizeAfterCopy_Bytes / 1GB

    [System.IO.File]::AppendAllText($RobocopyLogFile, "✅ 복사 후 대상 폴더의 **확인된 용량**: $($TotalSizeAfterCopy_GB.ToString('N2')) GB`r`n", $UnicodeEncoding)
    [System.IO.File]::AppendAllText($RobocopyLogFile, "✨ 최종 복사 성공 여부는 Robocopy 통계를 확인하십시오.`r`n", $UnicodeEncoding)
}
catch {
    [System.IO.File]::AppendAllText($RobocopyLogFile, "❌ 오류: 복사 후 대상 용량 확인 중 오류 발생 - $($_.Exception.Message)`r`n", $UnicodeEncoding)
}
[System.IO.File]::AppendAllText($RobocopyLogFile, "---`r`n", $UnicodeEncoding)

# 6. 작업 소요 시간 기록
$EndTime = Get-Date
$TimeTaken = $EndTime - $StartTime
[System.IO.File]::AppendAllText($RobocopyLogFile, "⏱️ 총 소요 시간: $($TimeTaken.Hours) 시간 $($TimeTaken.Minutes) 분 $($TimeTaken.Seconds) 초`r`n", $UnicodeEncoding)

[System.IO.File]::AppendAllText($RobocopyLogFile, "=== 데이터 복사 작업 종료: $($EndTime) ===`r`n", $UnicodeEncoding)

# 최종 사용자 피드백
Write-Host "스크립트 실행이 완료되었습니다. 결과는 다음 로그 파일에서 확인하세요:" -ForegroundColor Green
Write-Host $RobocopyLogFile -ForegroundColor Yellow