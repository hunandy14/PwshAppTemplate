Import-Module .\'unity\Import-Param.ps1'

# 獲取當前批次檔位置
if ($PSScriptRoot) { $curDir = $PSScriptRoot } else { $curDir = (Get-Location).Path }
Set-Location $curDir

# 獲取CSV
$Param = (Import-Param 'Setting.json' -NodeName:'Param1' -AutoLoadCsv -TrimCsvValue); $Param.CsvObject
# 獲取安全密碼
$PassWd = DecryptPassWord $Param.SecurePassword; $PassWd

Exit 0