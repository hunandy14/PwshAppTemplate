PowerShell App 程序樣板
====

注意事項：Setting.json 裡面的密碼要自己更新，那個密碼生成的時候有用到當前使用者的UID，換使用者之後檢測道不同會報錯。


<br><br>

## 混合代碼

看似PS代碼，但實際上卻可以被命名成cmd或ps1執行。(預設行為是UTF8請務必儲存成這個編碼)

```ps1
@(setlocal enabledelayedexpansion& set "0=%~f0"& set "1=%*"^)#)& powershell -exec Bypass -nop -c "iex('&{#'+[io.file]::ReadAllText($env:0)+'}'+$env:1)-ea(1)"& exit /b !errorlevel!
Write-Host "by PSVersion::" $PSVersionTable.PSVersion -ForegroundColor DarkGray
Write-Host "Caller   : $env:0 $env:1"

```

詳細說明參考[高級混合代碼](https://github.com/hunandy14/PwshAppTemplate/blob/master/doc/3.%20高級混合代碼.md)



<br><br>

## 拆分參數

PowerShell內建函式拆解

```ps1
$argslist = Invoke-Expression "&{`$args}$env:1"
```


<br>

使用 cmd 規則拆解

```ps1
$argslist = @(cmd.exe /c "for %i in ($env:1) do @echo %~i")
```


<br><br>

## PowerShell 參數
對於 PowerShell 的參數下面有幾個建議增加的
以下是 PowerShell 參數的整理表格，包含每個參數的功能描述：

| 參數           | 功能描述                                                                                                  |
|-------------   |-----------------------------------------------------------------------------------------------------------|
| `-exec Bypass` | 設定執行策略為 "Bypass"，允許執行腳本，無論系統的執行策略設定為何。這通常用於跳過執行政策限制。           |
| `-noni`        | 表示不啟動互動式命令提示符（Non-Interactive Mode）。這對於只執行腳本或命令，而不需要進入互動模式時很有用。 |
| `-nop`         | 表示不加載 PowerShell 配置檔（No Profile）。這可以加速執行速度，避免因配置檔的問題影響腳本執行。           |
| `-c`           | 簡寫形式，表示要執行的命令（Command）。這用於直接執行後接的 PowerShell 命令。                              |



<br><br>

## ReadAllText($file, $enc) 常見編碼
```ps1
# 日文::Shift-JIS (932)
[Text.Encoding]::GetEncoding('Shift-JIS')
# 繁體中文::BIG5 (950)
[Text.Encoding]::GetEncoding('BIG5')
# 萬國碼::UTF8 (65001)
[Text.Encoding]::GetEncoding('UTF-8')
# 當前系統編碼
PowerShell -Nop "& {return [Text.Encoding]::Default}"
# 當前 PowerShell 編碼
[Text.Encoding]::Default
```
