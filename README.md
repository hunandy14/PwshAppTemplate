PowerShell App 程序樣板
====

注意事項：Setting.json 裡面的密碼要自己更新，那個密碼生成的時候有用到當前使用者的UID，換使用者之後檢測道不同會報錯。


<br><br><br>

## 拆分參數
### 1. 用匿名函式
用匿名函式去讀參數，結果會被自動收集到陣列裡

```ps1
$Arguments = @(& {return $args} $env:2)
```

但該方法有一些小問題要處理
1. 被集中到一個變數裡導致被當作一個字串傳遞 -> 用iex解套
2. 由iex導致的參數中雙引號內特定符號(錢號,反引號)被解釋 -> 把雙引號轉成單引號
3. 由於雙引號轉成單引號導致參數中...再寫下去沒完沒了就這些事自己想辦法吧XD

```ps1
$ArgumentsString = '-i input.mkv frame-%d.png -test "123 $abc"'
$Arguments = @("&{return(`$args)}$($ArgumentsString-replace([char]34,[char]39))"|Invoke-Expression)
$Arguments
```

<br>

### 2. PowerShell 內建獲取函式的方法
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

<br>

### 3. 使用 iex 解析
最優解，既然是單一參數就從頭到尾都用iex不參與實際操作就可以避開這問題了 (版本5需要反轉譯，版本7不需要)  

```ps1
$ArgumentsString = '-X POST https://httpbin.org/post -H "Content-Type: application/json" -d "{""key"": ""frame-`%d.png""}"'
if( $PSVersionTable.PSVersion.Major -le 5 ){ $ArgumentsString = $ArgumentsString -replace'([$`"''(){}[\];#&|])','`$1' }
"curl.exe $ArgumentsString" |iex

```

<br>

### 4. 使用 CMD 解析
2024-09-16 追加這個應該是最終答案了  
理由是對於使用者來說他們在這個環境下會預期應該是走 CMD 規則  
雖然這會導致 PowerShell 的解析全部失效，但這是正確的  

```ps1
$argslist = @(cmd.exe /c "for %i in ($env:1) do @echo %~i")
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

## 混合高級腳本代碼(集中單一參數轉發)
轉發高級腳本的方式 `proxy.bat` 範例

```bat
@(set "0=%~f0"^)#) & set "1=%*" & setlocal enabledelayedexpansion & powershell -nop -c "$dq=[char]34;$a='(['+$dq+'$`])';$b='`$1';$scr=([io.file]::ReadAllText($env:0,[Text.Encoding]::Default)-split'\n',2)[1]; $parm=$env:1-replace($a,$b); iex('&{'+$scr+'}'+$dq+$parm+$dq); $err=$LastExitCode;$Host.SetShouldExit($err);Exit($err)" & exit /b !errorlevel!
[CmdletBinding()]
param (
    [Parameter(Position=0)]
    [string]$ArgumentsString
)
Write-Host ""
Write-Host "在 proxy.bat 中 %* 獲取的數字串 :" -BackgroundColor DarkMagenta
Write-Host "  $env:1" -ForegroundColor DarkCyan

Write-Host ""
Write-Host "轉發到 pwsh.exe 內部獲取的參數字串: " -BackgroundColor DarkMagenta
Write-Host "  $ArgumentsString" -ForegroundColor DarkCyan

curl.exe @($ArgumentsString -split ' ')
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
> 目前只有設定雙引號錢號與反引號，暫時沒發現其他問題但總覺得可能還有漏掉的  
>   
> 對於轉譯的跳脫符號問題可以參考這篇大全  
> https://stackoverflow.com/questions/562038/escaping-double-quotes-in-batch-script/31413730#31413730  



<br><br><br>

## 混合高級腳本代碼(多參數轉發)
轉發高級腳本的方式 `proxy.bat` 範例

```bat
@(set "0=%~f0"^)#) & set "1=%*" & setlocal enabledelayedexpansion & powershell -nop -c "$scr=([io.file]::ReadAllText($env:0,[Text.Encoding]::Default)-split'\n',2)[1]; iex('&{'+$scr+'}'+($env:1)); $err=$LastExitCode;$Host.SetShouldExit($err);Exit($err)" & exit /b !errorlevel!
[CmdletBinding()]
param (
    [Parameter(Position=0)]
    [string]$Argument1,
    [string]$Argument2,
    [switch]$ShowInfo
)
Write-Host "Bat 解析的參數: $env:1"
Write-Host "Argument1: $Argument1"
Write-Host "Argument2: $Argument2"
Write-Host "ShowInfo : $ShowInfo"

Exit 1


```

用例

```bat
proxy.bat -Argument1 AA -Argument2 "B B" -ShowInfo

```

結果

```
Bat 解析的參數: -Argument1 AA -Argument2 "B B" -ShowInfo
Argument1: AA
Argument2: B B
ShowInfo : True
```
