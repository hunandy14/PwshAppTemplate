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
