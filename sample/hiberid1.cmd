@(set +=^)#)& setlocal enabledelayedexpansion& set "0=%~f0"& set "1=%*"& powershell -nop "iex('&{#'+[io.file]::ReadAllText($env:0)+'}'+($env:1-replace'([*?[\]`()$.&;|])','`$1'))-ea(1)"& exit /b !errorlevel!
[CmdletBinding()]
param (
    [Parameter(Position=0)]
    [string]$Argument1,
    [string]$Argument2,
    [switch]$ShowInfo
)
Write-Host "by PSVersion::" $PSVersionTable.PSVersion -ForegroundColor DarkGray
Write-Host "Caller   : $env:0 $env:1"
Write-Host "Argument1: $Argument1"
Write-Host "Argument2: $Argument2"
Write-Host "ShowInfo : $ShowInfo"
Exit -1
