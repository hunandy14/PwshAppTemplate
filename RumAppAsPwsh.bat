@echo off

set "0=%~f0"& set "1=%~dp0"& set PwshScript=([Io.File]::ReadAllText($env:0,[Text.Encoding]::Default) -split '[:]PwshScript')
::powershell -nop "(%PwshScript%[2]+%PwshScript%[1])|iex; Exit $LastExitCode"

set PsFile=($env:temp+'\a.ps1')& set pwsh=C:\Program Files\PowerShell\7\pwsh.exe
powershell -nop "(%PwshScript%[2]+%PwshScript%[1])|Out-File %PsFile% utf8"
%pwsh% -nop -c "([Io.File]::ReadAllText(%PsFile%,[Text.Encoding]::Default))|iex; Exit $LastExitCode"

echo ExitCode: %errorlevel%& pause
Exit %errorlevel%





:PwshScript#:: script2
#:: --------------------------------------------------------------------------------------------------------------------------------
Write-Host "by PSVersion::" $PSVersionTable.PSVersion "`n"
$AppFile='App.ps1'; $AppEnc='UTF-8'
iex([Io.File]::ReadAllText($AppFile, [Text.Encoding]::GetEncoding($AppEnc)))


:PwshScript#:: script1
#:: --------------------------------------------------------------------------------------------------------------------------------
Set-Location ($env:1); [IO.Directory]::SetCurrentDirectory(((Get-Location -PSProvider FileSystem).ProviderPath))
