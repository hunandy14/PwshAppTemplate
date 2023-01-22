@echo off

set "0=%~f0"& set "1=%~dp0"& set "2=%*"& set PwshScript=([Io.File]::ReadAllText($env:0,[Text.Encoding]::GetEncoding('UTF-8')) -split '[:]PwshScript')

:: 方法1: PowerShell 5 運行
powershell -nop "(%PwshScript%[2])|iex; Exit $LastExitCode"

:: 方法1: PowerShell 7 運行 (有nop的條件下無法使用 UTF8 以外的編碼載入)
@REM pwsh -nop -c "(%PwshScript%[2])|iex; Exit $LastExitCode"

:: 方法3: PowerShell 7 運行 (把檔案寫到temp裡避開方法2的問題)
@REM set "0=%~f0"& set "1=%~dp0"& set PwshScript=([Io.File]::ReadAllText($env:0,[Text.Encoding]::Default) -split '[:]PwshScript')
@REM set PsFile=($env:temp+'\a.ps1')& set path=%path%;C:\Program Files\PowerShell\7
@REM powershell -nop "(%PwshScript%[2])|Out-File %PsFile% utf8"
@REM pwsh -nop -c "([Io.File]::ReadAllText(%PsFile%,[Text.Encoding]::Default))|iex; Exit $LastExitCode"

echo ExitCode: %errorlevel%& pause
Exit %errorlevel%





:PwshScript#:: script1
#:: --------------------------------------------------------------------------------------------------------------------------------
Write-Host "by PSVersion::" $PSVersionTable.PSVersion
$AppFile='App.ps1'; $AppEnc='UTF-8'
iex([Io.File]::ReadAllText($AppFile, [Text.Encoding]::GetEncoding($AppEnc)))


:PwshScript#:: script2
#:: --------------------------------------------------------------------------------------------------------------------------------
try {
    Set-ExecutionPolicy Bypass Process -Force
    Set-Location ($env:1); [IO.Directory]::SetCurrentDirectory(((Get-Location -PSProvider FileSystem).ProviderPath)); $Arguments = $env:2
    ([Io.File]::ReadAllText($env:0,[Text.Encoding]::GetEncoding('UTF-8')) -split '[:]PwshScript')[1]|iex
} catch {
    #$Msg = $_.Exception.Message
    $Msg = $Error|Out-String
    $LogStr = "[$((Get-Date).Tostring('yyyy/MM/dd HH:mm:ss.fff'))] $Msg"
    Write-Host $LogStr -ForegroundColor:Red
    $LogStr >> "log\exception.log"
}

:PwshScript#:: End
#:: --------------------------------------------------------------------------------------------------------------------------------
