::--------------------------------------------------------------------------------------------------------------------------------
@echo off
CD "%~dp0"
:: [版本5: powershell.exe (預設就有)], [版本7: pwsh.exe (額外安裝)]
Set Powershell=powershell.exe
:: 設置pwsh執行權限
Set Execut=try{Set-ExecutionPolicy -ExecutionPolicy:Bypass -Scope:Process}catch{}
:: 設置ps1讀取時的Encoding
Set Encoding=[Text.Encoding]::GetEncoding('UTF-8')
::Set Encoding=[Text.Encoding]::Default



:: 方法1: 載入並執行函式
::--------------------------------------------------------------------------------------------------------------------------------
Set PwshLib=Unity\Import-Param.ps1
Set FuncName=Import-Param
Set Param1='Setting.json'
Set Param2=-NodeName:'Param1'
Set Param3=-TrimCsvValue
@REM call %Powershell% -Nop -C "& {%Execut%; Set-Location '%~dp0'; Import-Module .\'%PwshLib%'; %FuncName% %Param1% %Param2% %Param3%; Exit $LastExitCode}"
@REM echo ExitCode: %errorlevel%



:: 方法2: 直接執行主程式1
::--------------------------------------------------------------------------------------------------------------------------------
echo ----------------------------------------------------------------
Set PwshApp=App.ps1
@REM call %Powershell% -Nop -C "& {%Execut%; Set-Location '%~dp0'; .\'%PwshApp%'; Exit $LastExitCode}"
@REM echo ExitCode: %errorlevel%

:: 方法2: 直接執行主程式2 (支援UTF-8的PS1檔案)
Set PwshApp=App.ps1
call %Powershell% -Nop -C "& {%Execut%; Set-Location '%~dp0'; iex([Io.File]::ReadAllText((Convert-Path '%PwshApp%'),%Encoding%)); Exit $LASTEXITCODE;}"
echo ExitCode: %errorlevel%



:: 方法3: 把Powershell寫入同一份Bat檔案 (支援UTF-8的PS1檔案)
::--------------------------------------------------------------------------------------------------------------------------------
echo ----------------------------------------------------------------
set "0=%~f0" & set "1=%~dp0" & call %Powershell% -nop -c "%Execut%; iex([Io.File]::ReadAllText($env:0,%Encoding%) -split '[:]PwshScript')[1];"
echo ExitCode: %errorlevel%
pause
Exit %errorlevel%



::--------------------------------------------------------------------------------------------------------------------------------
:PwshScript
#:: script
Set-Location ($env:1); [IO.Directory]::SetCurrentDirectory(((Get-Location -PSProvider FileSystem).ProviderPath))

$AppFile='App.ps1'; $AppEnc='UTF-8'
iex([Io.File]::ReadAllText((Convert-Path $AppFile), [Text.Encoding]::GetEncoding($AppEnc)))

Exit $LastExitCode
#:: done #:PwshScript
::--------------------------------------------------------------------------------------------------------------------------------
