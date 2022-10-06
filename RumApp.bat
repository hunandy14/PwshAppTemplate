@echo off
CD "%~dp0"
:: [版本5: powershell.exe (預設就有)], [版本7: pwsh.exe (額外安裝)]
Set Powershell=pwsh.exe
:: 設置pwsh執行權限
Set Execut=try{Set-ExecutionPolicy -ExecutionPolicy:Bypass -Scope:Process}catch{}


echo ----------------------------------------------------------------
:: 方法1: 載入並執行函式
Set PwshLib=Unity\Import-Param.ps1
Set FuncName=Import-Param
Set Param1='Setting.json'
Set Param2=-NodeName:'Param1'
Set Param3=-TrimCsvValue
call %Powershell% -Nop -C "& {%Execut%; Set-Location '%~dp0'; Import-Module .\'%PwshLib%'; %FuncName% %Param1% %Param2% %Param3%; Exit $LastExitCode}"
echo ExitCode: %errorlevel%


echo ----------------------------------------------------------------
:: 方法2: 直接執行檔案
Set PwshApp=App.ps1
call %Powershell% -Nop -C "& {%Execut%; Set-Location '%~dp0'; .\'%PwshApp%'; Exit $LastExitCode}"
echo ExitCode: %errorlevel%


echo ----------------------------------------------------------------
:: 方法3: 把Powershell寫入同一份Bat檔案
set "0=%~f0" & set "1=%~dp0" & call %Powershell% -nop -c "iex (%Execut%; [io.file]::ReadAllText($env:0) -split '[:]PwshScript')[1];"
echo ExitCode: %errorlevel%


pause
Exit %errorlevel%

::--------------------------------------------------------------------------------------------------------------------------------
:PwshScript
#:: script
Set-Location "$($env:1)"
.\"App.ps1"
Exit $LastExitCode
#:: done #:PwshScript
::--------------------------------------------------------------------------------------------------------------------------------
