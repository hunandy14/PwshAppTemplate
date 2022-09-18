Import-Module .\'unity\Import-Param.ps1'

# 計時開始
$Date = (Get-Date); $StWh = New-Object System.Diagnostics.Stopwatch; $StWh.Start()



# 獲取當前批次檔位置
if ($PSScriptRoot) { $curDir = $PSScriptRoot } else { $curDir = (Get-Location).Path }
Set-Location $curDir

# 獲取CSV
$Param = (Import-Param 'Setting.json' -NodeName:'Param1' -AutoLoadCsv -TrimCsvValue);
Write-Host "Excel內容: `n" + $Param.CsvObject
# 獲取安全密碼
$PassWd = DecryptPassWord $Param.SecurePWord;
Write-Host "安全密碼: $PassWd"
Write-Host ""



$StWh.Stop(); $Time = "{0:hh\:mm\:ss\.fff}" -f [timespan]::FromMilliseconds($StWh.ElapsedMilliseconds)
$LogStr  = "[$Date] $Msg" + (", 耗時: $Time")
Write-Host "[$Date] 開始執行, 耗時 [" -NoNewline; Write-Host $Time -NoNewline -ForegroundColor:DarkCyan; Write-Host "] 執行結束"

Exit 1
