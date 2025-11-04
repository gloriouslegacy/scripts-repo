# ----------------------------------------------------------------------
## 1. 스크립트 실행 단수화 Wrapper 코드
# Wrapper 코드는 스크립트가 실행될 때, 사용자가 입력한 매개변수를 분석하여 적절한 함수를 자동으로 호출

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('png2ico', 'ico2png')]
    [string]$Action,  # 변환 방향 지정 (png2ico 또는 ico2png)

    [Parameter(Mandatory=$true)]
    [string]$SourcePath,  # 원본 파일 경로

    [Parameter(Mandatory=$true)]
    [string]$DestinationPath, # 대상 파일 경로

    [string]$IconSizes = "256,128,64,48,32,16", # png2ico용
    [int]$FrameIndex = 0 # ico2png용
)

# Wrapper 코드 논리 부분 (함수 호출)
switch ($Action) {
    'png2ico' {
        Convert-PngToIco -PngPath $SourcePath -IcoPath $DestinationPath -IconSizes $IconSizes
    }
    'ico2png' {
        Convert-IcoToPng -IcoPath $SourcePath -PngPath $DestinationPath -FrameIndex $FrameIndex
    }
    default {
        Write-Error "Invalid Action parameter. Use 'png2ico' or 'ico2png'."
    }
}
# ----------------------------------------------------------------------

## 2. PNG를 ICO로 변환 함수 (Convert-PngToIco)

function Convert-PngToIco {
    param(
        [Parameter(Mandatory=$true)] [string]$PngPath,
        [Parameter(Mandatory=$true)] [string]$IcoPath,
        [Parameter(Mandatory=$false)] [string]$IconSizes = "256,128,64,48,32,16"
    )

    if (-not (Test-Path $PngPath)) { Write-Error "Error: Source PNG file not found at '$PngPath'"; return }
    $ResolvedPngPath = (Get-Item $PngPath).FullName
    $ResolvedIcoPath = (Join-Path (Split-Path $ResolvedPngPath) (Split-Path $IcoPath -Leaf))

    Write-Host "Converting '$ResolvedPngPath' to ICO with sizes: $IconSizes..."

    try {
        & magick "$ResolvedPngPath" -define "icon:auto-resize=$IconSizes" "$ResolvedIcoPath" | Out-Null
        
        if (Test-Path $ResolvedIcoPath) {
            Write-Host "✅ Success: ICO file created at '$ResolvedIcoPath'" -ForegroundColor Green
        } else {
            Write-Error "Error: magick command ran, but ICO file was not found at '$ResolvedIcoPath'. Check the source PNG file for issues."
        }
    }
    catch {
        Write-Error "ImageMagick conversion failed. Check if ImageMagick is installed and in PATH."
        Write-Error $_.Exception.Message
    }
}
# ----------------------------------------------------------------------

## 3. ICO를 PNG로 변환 함수 (Convert-IcoToPng)

function Convert-IcoToPng {
    param(
        [Parameter(Mandatory=$true)] [string]$IcoPath,
        [Parameter(Mandatory=$true)] [string]$PngPath,
        [Parameter(Mandatory=$false)] [int]$FrameIndex = 0
    )

    if (-not (Test-Path $IcoPath)) { Write-Error "Error: Source ICO file not found at '$IcoPath'"; return }
    $ResolvedIcoPath = (Get-Item $IcoPath).FullName
    $ResolvedPngPath = (Join-Path (Split-Path $ResolvedIcoPath) (Split-Path $PngPath -Leaf))
    
    Write-Host "Converting '$ResolvedIcoPath' (Frame Index $FrameIndex) to PNG..."

    try {
        & magick "$ResolvedIcoPath[$FrameIndex]" "$ResolvedPngPath" | Out-Null
        
        if (Test-Path $ResolvedPngPath) {
            Write-Host "✅ Success: PNG file created at '$ResolvedPngPath'" -ForegroundColor Green
        } else {
            Write-Error "Error: magick command ran, but PNG file was not found."
        }
    }
    catch {
        Write-Error "ImageMagick conversion failed. Check if ImageMagick is installed and in PATH."
        Write-Error $_.Exception.Message
    }
}
# ----------------------------------------------------------------------



# ----------------------------------------------------
#               사용 예시
# ----------------------------------------------------

# Set-ExecutionPolicy RemoteSigned -Scope Process

# 스크립트 실행하기 전 ImageMagick 설치 및 PATH에 추가
# Winget (Windows 10/11 기본)	winget install ImageMagick.ImageMagick
# Chocolatey (별도 설치 필요)	choco install imagemagick
# magick -version

# (1) PNG to ICO : 특정 크기만 포함
# $CustomSizes = "128,48,16"
# .\ImageConverter.ps1 -Action png2ico -SourcePath ".\test.png" -DestinationPath ".\test.ico" -IconSizes 32

# (2) ICO to PNG
# .\ImageConverter.ps1 -Action ico2png -SourcePath ".\test.ico" -DestinationPath ".\test.png" -FrameIndex 0