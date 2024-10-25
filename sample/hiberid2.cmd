<# ::BatchScript
@echo off & set "0=%~f0" & set "1=%*"
set "2=@echo off & for %%i in (!1!) do (echo %%i)"
set "escapePSKeywords=ForEach-Object { $_ -replace '([*?[\]`()$.&;|])', '`$1' }"
powershell -nop "iex('&{'+[io.file]::ReadAllText($env:0)+'} '+((cmd /V:ON /c $env:2)|%escapePSKeywords%))-ea(1)"
exit /b %errorlevel%
::PowerShellScript #>
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
