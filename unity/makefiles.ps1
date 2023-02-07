# [IO.File]::WriteAllText("unity\Import-Param.ps1", (irm bit.ly/Import-Param), [Text.Encoding]::GetEncoding(65001));
$Enc    = [System.Text.Encoding]::GetEncoding(65001)
$BatEnc = New-Object System.Text.UTF8Encoding $False

# 移除文本中的註解
function RemoveComment( [Object] $Content, [String] $Mark='#' ) {
    return [string](((($Content-split "`n") -replace("($Mark(.*?)$)|(\s+$)","") -notmatch('^\s*$'))) -join "`r`n")
} # RemoveComment (Invoke-RestMethod bit.ly/Get-FileList)
# 展開 irm 內容
function ExpandIrm( [Object] $Content, [String] $Encoding='UTF8' ) {
    $bitlyLine=(($Content -split "`n") -match "bit.ly|raw.githubusercontent.com")
    foreach ($line in $bitlyLine) {
        $expand = $line -replace('(\s*\|\s*(Invoke-Expression|iex))|^iex','') |Invoke-Expression
        $Content = $Content.Replace($line, ($expand))
    }
    return (RemoveComment $Content)
} # ExpandIrm (Invoke-RestMethod bit.ly/Get-FileList)



# Script1 の読み込み
$Script1FileName = ".\OracleDL.ps1"
$MainSrc   = ([Io.File]::ReadAllText($Script1FileName,$Enc) -split '[:]MakeFile')[1]
$Script1   = $MainSrc
# Script2 の読み込み
$Script2FileName = ".\OracleExecutor.ps1"
$IncudeSrc = ExpandIrm(ExpandIrm([Io.File]::ReadAllText($Script2FileName,$Enc)))
$Script2   = $IncudeSrc

# batFile の読み込みとリプレース
$batFile = [Io.File]::ReadAllText("$PSScriptRoot\template.txt",$Enc)
$batFile = $batFile.Replace('${PsScript.Main}',$Script1)
$batFile = $batFile.Replace('${PsScript.Include}',$Script2)



# ファイルの作成
$BatFileName = "OracleDL.bat"
$FileDst = ".\release\batch\$BatFileName"
New-Item (Split-Path $FileDst) -ItemType:Directory -Force|Out-Null
[IO.File]::WriteAllText($FileDst, $batFile, $BatEnc);


# ファイルコピー
$FileSrc = ".\sql\s1JS_S06_LRHDV001.sql"
$FileDst = ".\release\lib\oracle\sql\s1JS_S06_LRHDV001.sql"
New-Item (Split-Path $FileDst) -ItemType:Directory -Force|Out-Null
Copy-Item $FileSrc $FileDst -Force

$FileSrc = ".\sql\HDpass.sql"
$FileDst = ".\release\lib\oracle\sql\HDpass.sql"
New-Item (Split-Path $FileDst) -ItemType:Directory -Force|Out-Null
Copy-Item $FileSrc $FileDst -Force

# $FileSrc = ".\sql\JS_S06_LRHDV001.sql"
# $FileDst = ".\release\lib\oracle\sql\JS_S06_LRHDV001.sql"
# New-Item (Split-Path $FileDst) -ItemType:Directory -Force|Out-Null
# Copy-Item $FileSrc $FileDst -Force
# Copy-Item 'Parma.json' 'release\Parma.json' -Force