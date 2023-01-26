@echo off

set "0=%~f0"& set "1=%~dp0"& set "2=%*"& set PwshScript=([Io.File]::ReadAllText($env:0,[Text.Encoding]::GetEncoding('UTF-8')) -split '[:]PwshScript')

:: 方法1: PowerShell 5 運行
powershell -nop -exec Bypass -c "(%PwshScript%[3])|iex; Exit $LastExitCode"

:: 方法1: PowerShell 7 運行 (有nop的條件下無法使用 UTF8 以外的編碼載入)
@REM pwsh -nop -c "(%PwshScript%[3])|iex; Exit $LastExitCode"

:: 方法3: PowerShell 7 運行 (把檔案寫到temp裡避開方法2的問題)
@REM set "0=%~f0"& set "1=%~dp0"& set PwshScript=([Io.File]::ReadAllText($env:0,[Text.Encoding]::Default) -split '[:]PwshScript')
@REM set PsFile=($env:temp+'\a.ps1')& set path=%path%;C:\Program Files\PowerShell\7
@REM powershell -nop "(%PwshScript%[3])|Out-File %PsFile% utf8"
@REM pwsh -nop -c "([Io.File]::ReadAllText(%PsFile%,[Text.Encoding]::Default))|iex; Exit $LastExitCode"

echo ExitCode: %errorlevel%
Exit /b %errorlevel%



:PwshScript#:: script1 Main
#:: --------------------------------------------------------------------------------------------------------------------------------
Write-Host "by PSVersion::" $PSVersionTable.PSVersion
"RunTest" |WriteLog "log\WriteLog.log" -ErrorAction Stop



:PwshScript#:: script2 Function
#:: --------------------------------------------------------------------------------------------------------------------------------
Invoke-RestMethod "raw.githubusercontent.com/hunandy14/WriteLog/master/WriteLog.ps1"|Invoke-Expression



:PwshScript#:: script3 Execute
#:: --------------------------------------------------------------------------------------------------------------------------------
try {
    Set-Location ($env:1); [IO.Directory]::SetCurrentDirectory(((Get-Location -PSProvider FileSystem).ProviderPath)); $Arguments = $env:2
    ([Io.File]::ReadAllText($env:0,[Text.Encoding]::GetEncoding('UTF-8')) -split '[:]PwshScript')[2]|iex
    ([Io.File]::ReadAllText($env:0,[Text.Encoding]::GetEncoding('UTF-8')) -split '[:]PwshScript')[1]|iex
} catch {
    #$Msg = $_.Exception.Message
    $Msg = $Error|Out-String
    $LogStr = "[$((Get-Date).Tostring('yyyy/MM/dd HH:mm:ss.fff'))] $Msg"
    Write-Host $LogStr -ForegroundColor:Red
    $LogStr >> "exception.log"
    Exit 1
}



:PwshScript#:: End
#:: --------------------------------------------------------------------------------------------------------------------------------
