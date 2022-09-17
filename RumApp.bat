@echo off
:: [版本5: powershell.exe (預設就有)], [版本7: pwsh.exe (額外安裝)]
Set Powershell=powershell.exe

:: 載入並執行函式
Set PwshLib=Unity\Import-Param.ps1
Set FuncName=Import-Param
Set Param1='Setting.json'
Set Param2=-NodeName:'Param1'
Set Param3=-AutoLoadCsv -TrimCsvValue
call %Powershell% "& {Set-Location '%~dp0'; Import-Module .\'%PwshLib%'; %FuncName% %Param1% %Param2% %Param3%}"

:: 直接執行檔案
Set PwshApp=App.ps1
call %Powershell% "& {Set-Location '%~dp0'; .\'%PwshApp%';}"

:: 輸出錯誤代碼
echo %errorlevel%
pause
