PowerShell App 程序樣板
====

注意事項：Setting.json 裡面的密碼要自己更新，那個密碼生成的時候有用到當前使用者的UID，換使用者之後檢測道不同會報錯。


<br><br>

## 混合代碼

看似PS代碼，但實際上卻可以被命名成cmd或ps1執行

```ps1
@(setlocal enabledelayedexpansion& set "0=%~f0"& set "1=%*"^)#)& powershell "iex('&{'+[io.file]::ReadAllText($env:0)+'}'+$env:1)-ea(1)"& exit /b !errorlevel!
Write-Host "by PSVersion::" $PSVersionTable.PSVersion

```



<br><br>

## 拆分參數

PowerShell內建函式拆解

```ps1
$argslist = @(&{return $args}$env:1)
```


<br>

使用 cmd 規則拆解

```ps1
$argslist = @(cmd.exe /c "for %i in ($env:1) do @echo %~i")
```
