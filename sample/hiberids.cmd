@powershell "iex('#'+[io.file]::ReadAllText('%~f0'))"& exit /b
Write-Host "by PSVersion::" $PSVersionTable.PSVersion
