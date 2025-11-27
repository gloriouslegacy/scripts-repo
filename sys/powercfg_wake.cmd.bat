@echo off
title Power Management Check
color 0a
chcp 65001 >nul
echo Starting Power Management Check Script...
echo.

:top
echo Checking devices that can wake the computer from sleep mode...
echo 대기 모드에서 컴퓨터를 깨울 수 있는 장치를 확인하는 중입니다...
echo ----------------------------------------
powercfg -devicequery wake_armed
echo ----------------------------------------

echo [Instruction] Please disable the wake-up option for the listed devices:
echo [안내] 아래 나열된 장치에 대해 대기 모드 해제 옵션을 비활성화하세요.
echo [1] Open "Device Manager" and select the device.
echo [1] "장치 관리자"를 열고 해당 장치를 선택하세요.
echo [2] Go to the "Power Management" tab.
echo [2] "전원 관리" 탭으로 이동하세요.
echo [3] Uncheck "Allow this device to wake the computer."
echo [3] "이 장치를 사용하여 컴퓨터의 대기 모드를 종료할 수 있음"의 체크를 해제하세요.
echo.

echo Opening Device Manager...
start "" devmgmt.msc

echo Press any key to recheck the devices...
pause
goto top
