PowerShell App 程序樣板
====

注意事項：Setting.json 裡面的密碼要自己更新，那個密碼生成的時候有用到當前使用者的UID，換使用者之後檢測道不同會報錯。

拆分參數可以用下面的方式

用匿名函式去讀參數，結果會被自動收集到陣列裡

```ps1
$Arguments = @(& {return $args} $env:2)
```

另一個方法是偷 PowerShell 內建獲取函式的方法，直接轉線程的物件出來用

```ps1
$Arguments = '"C:\List 1.csv" -Table CHG.CHG.CHG_M01'

$ScriptBlock = {
    param(
        [Parameter(Position = 0, ParameterSetName = "", Mandatory)]
        [string] $Path,
        [Parameter(ParameterSetName = "")]
        [string] $Table
    ) $PSBoundParameters
}; $Arguments = Invoke-Expression "& `$ScriptBlock $Arguments"

$Arguments
```



<br><br><br>

## 混合版代碼
只需要加在開頭而已很神的代碼

```bat
# 最簡版本
@(set "0=%~f0"^)#) & powershell -nop -c "iex([io.file]::ReadAllText($env:0))" & exit /b

# 增加參數版本
@(set "0=%~f0"^)#) & set "1=%*" & powershell -nop -c "iex([io.file]::ReadAllText($env:0))" & exit /b

# 增加可返回參數版本
@(set "0=%~f0"^)#) & set "1=%*" & setlocal enabledelayedexpansion & powershell -nop -c "iex([io.file]::ReadAllText($env:0));$Host.SetShouldExit($LastExitCode);Exit $LastExitCode" & exit /b !errorlevel!
Write-Host "by PSVersion::" $PSVersionTable.PSVersion
Write-Host "Command is '$env:0 $env:1'"
Exit 0


```


<br><br><br>


## 混合版代碼(包含轉發參數)
轉發高級腳本的方式 `proxy.bat` 範例

```bat
@(set "0=%~f0"^)#) & set "1=%*" & setlocal enabledelayedexpansion & powershell -nop -c "$dq=[char]34;$a='(['+$dq+'$])';$b='`$1';$scr=([io.file]::ReadAllText($env:0,[Text.Encoding]::Default)-split'\n',2)[1]; iex('&{'+$scr+'}'+($dq+($env:1-replace($a,$b))+$dq)); $err=$LastExitCode;$Host.SetShouldExit($err);Exit($err)" & exit /b !errorlevel!
[CmdletBinding()]
param (
    [Parameter(Position=0)]
    [string]$ArgumentsString
) $ArgumentsList = @($ArgumentsString -split ' ')
Write-Host "Bat  解析的參數: $env:1"
Write-Host "Pwsh 實際的參數: $ArgumentsList"
curl.exe $ArgumentsList
Exit 1


```

用例

```bat
proxy.bat -X POST https://httpbin.org/post -H "Content-Type: application/json" -d "{\"key\": \"value\"}"


```

<br>

> 這邊有一點要注意的是 bat 解析的跳脫字元跟 powershell 是不同的，也就是說對於  
> 在powershell中執行 "a.bat "雙引號`"中的雙引號" 之後，實際在 bat 中  
> 獲取到的參數 %* 是被解析過的，以至於無法分辨哪個雙引號是邊界引號  
>   
> 其次範例中解析的參數跟實際參數要注意一下，要是有不同可能是 $a 的跳脫字元有漏  
> 目前只有設定雙引號與錢號，暫時沒發現其他問題但總覺得可能還有漏掉的  
>   
> 對於轉譯的跳脫符號問題可以參考這篇大全  
> https://stackoverflow.com/questions/562038/escaping-double-quotes-in-batch-script/31413730#31413730  
