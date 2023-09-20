@(set "0=%~f0"^)#) & set "1=%*" & setlocal enabledelayedexpansion & powershell -nop -c "iex([io.file]::ReadAllText($env:0));$Host.SetShouldExit($LastExitCode);Exit $LastExitCode" & exit /b !errorlevel!
Write-Host "by PSVersion::" $PSVersionTable.PSVersion
Write-Host "Command is '$env:0 $env:1'"
Exit -7
