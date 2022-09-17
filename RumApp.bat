@echo off
:: [版本5: powershell.exe (預設就有)], [版本7: pwsh.exe (額外安裝)]
Set Powershell=pwsh.exe


:: 載入並執行函式
Set PwshLib=Unity\Import-Param.ps1
Set FuncName=Import-Param
Set Param1='Setting.json'
Set Param2=-NodeName:'Param1'
Set Param3=-AutoLoadCsv -TrimCsvValue

call %Powershell% -C "& {Set-Location '%~dp0'; Import-Module .\'%PwshLib%'; %FuncName% %Param1% %Param2% %Param3%; Exit $LastExitCode}"
echo ExitCode: %errorlevel%


:: 直接執行檔案
Set PwshApp=App.ps1

call %Powershell% -C "& {Set-Location '%~dp0'; .\'%PwshApp%'; Exit $LastExitCode}"
echo ExitCode: %errorlevel%


pause
