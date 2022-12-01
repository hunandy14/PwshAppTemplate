# 獲取當前批次檔位置
if ($PSScriptRoot) { $curDir = $PSScriptRoot } else { $curDir = (Get-Location).Path }
Set-Location $curDir
# 載入函式
# Import-Module .\'unity\Import-Param.ps1'
Invoke-Expression([Io.File]::ReadAllText((Convert-Path '.\unity\Import-Param.ps1'), [Text.Encoding]::GetEncoding('UTF-8')))

# 計時開始
$StWh=(StopWatch -Start)

# 獲取CSV
$Param = (Import-Param 'Setting.json' -NodeName:'Param1');
Write-Host "Excel內容: `n" + $Param.CsvObject
# 獲取安全密碼
if ($Param.SecurePWord) { 
    $PassWd = [Runtime.InteropServices.Marshal]::PtrToStringBSTR([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Param.SecurePWord))
    Write-Host "安全密碼: $PassWd"
    Write-Host ""
}

# 來自BAT的參數
if($Arguments){ Write-Host $Arguments }

# 輸出LOG
$Msg    = "設定檔載入完成"
$Time   = ($StWh|StopWatch -Stop)
$LogStr = $Msg + ", 耗時:$Time."
$LogStr |WriteLog $Param.LogPath -UTF8BOM
    
Exit 119
