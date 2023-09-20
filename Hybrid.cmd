@(set "0=%~f0"^)#) & set "1=%*" & powershell -nop -c "iex([io.file]::ReadAllText($env:0))" & exit /b
Write-Host "by PSVersion::" $PSVersionTable.PSVersion
Write-Host "Command is '$env:0 $env:1'"
