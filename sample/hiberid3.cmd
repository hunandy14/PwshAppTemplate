@(set "1=%*"^)#)& powershell "iex('#'+[io.file]::ReadAllText('%~f0'))"& exit /b
$argslist = @(if($env:1){cmd /c "for %i in ($env:1) do @echo %~i"}else{$args})
Write-Host "by PSVersion::" $PSVersionTable.PSVersion
Write-Host "Argslist: [$($argslist -join ', ')]"
