```
Get-ExecutionPolicy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
# Restricted로 되돌리기 (가장 안전함)
Set-ExecutionPolicy -ExecutionPolicy Restricted -Scope CurrentUser
#파일 잠금 확인
Unblock-File -Path .\setup-packages.ps1
```