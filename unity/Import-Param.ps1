# 載入函式庫
Invoke-RestMethod bit.ly/autoFixCsv|Invoke-Expression
# Import-Module .\"Unity\autoFixCsv.ps1"

# 獲取安全密碼字串
function EncryptPassWord {
    [CmdletBinding(DefaultParameterSetName = "A")]
    param (
        [Parameter(Position = 0, ParameterSetName = "A", Mandatory)]
        [String] $String,
        [Parameter(Position = 0, ParameterSetName = "B", Mandatory)]
        [Object] $Object
    )
    if ($Object) { $secure = $Object } else {
        $secure = (ConvertTo-SecureString $String -AsPlainText -Force)
    }
    return (ConvertFrom-SecureString $secure)
} # EncryptPassWord "MyPassWord"

# 從安全密碼字串獲取原密碼
function DecryptPassWord {
    [CmdletBinding(DefaultParameterSetName = "A")]
    param (
        [Parameter(Position = 0, ParameterSetName = "A", Mandatory)]
        [String] $String,
        [Parameter(Position = 0, ParameterSetName = "B", Mandatory)]
        [Object] $Object
    )
    if ($Object) { $secure = $Object } else {
        $secure = (ConvertTo-SecureString $String)
    }
    $bsr    = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bsr)
} # DecryptPassWord (EncryptPassWord "MyPassWord")

# 路徑檢查並自動轉換完整路徑
function PathTool {
    [CmdletBinding(DefaultParameterSetName = "A")]
    param (
        [Parameter(Position = 0, ParameterSetName = "", Mandatory)]
        [string] $Path,
        [Parameter(ParameterSetName = "A")]
        [switch] $NewItem,
        [Parameter(ParameterSetName = "B")]
        [switch] $IsItem
    )
    $Path = [IO.Path]::GetFullPath($Path)
    if ($NewItem) {
        if (!(Test-Path $Path)) { New-Item $Path -Force | Out-Null }
    }
    if ($IsItem) {
        if (Test-Path $Path -PathType:Leaf) { return $true } else { return $false }
    }
    return $Path
} # PathTool "Setting.json"

# 讀取Json檔案
function Import-Json {
    param (
        [Parameter(Position = 0, ParameterSetName = "", Mandatory)]
        [string] $Path,
        [Parameter(Position = 1, ParameterSetName = "")]
        [string] $Node
    )
    # $PSBaseName = split-path $MyInvocation.MyCommand.Name -LeafBase
    $json = (Get-Content $Path|ConvertFrom-Json)
    if ($Node) { $json = $json.$Node }
    return $json
} # Import-Json 'Setting.json' -Node:'CreateGroup'

# 讀取設定檔
function Import-Param {
    param (
        [Parameter(Position = 0, ParameterSetName = "", Mandatory)]
        [string] $Path,
        [Parameter(Position = 1, ParameterSetName = "", Mandatory)]
        [string] $NodeName,
        
        [Switch] $AutoLoadCsv,
        [Switch] $TrimCsvValue
    )
    # $PSBaseName = Split-Path $MyInvocation.MyCommand.Name -LeafBase
    $json = (Get-Content $Path|ConvertFrom-Json)
    $Node = $json.$NodeName
    if ($NULL -eq $Node) { $ErrorMsg = "[$Path]:: $NodeName is NULL"; throw $ErrorMsg; }

    $Node.PSObject.Properties|ForEach-Object{
        $Name  = $_.Name; $Value = $_.Value
        # 檢查各項節點是否為空值，為空值時填入預設值，如預設值也沒有則報例外
        if ($Value -eq "") {
            $defaultValue = $json.Default.$Name
            if ($NULL -eq $defaultValue) { $ErrorMsg = "[$Path]:: $NodeName.$Name is NULL"; throw $ErrorMsg; }
            if ('' -eq $defaultValue) { $ErrorMsg = "[$Path]:: $NodeName.$Name is Empty"; throw $ErrorMsg; }
            $_.Value = $Value = $defaultValue
        }
        
        # 檢查與修正路徑為絕對路徑 (有錯PathTool會報例外)
        if ($Name -eq "InputFile") {
            $_.Value = PathTool $Value
            # 自動載入CSV檔案
            if ($AutoLoadCsv) {
                if ((Get-Item $_.Value).Extension -eq '.csv') {
                    $Csv = autoFixCsv $_.Value -OutObject -TrimValue:$TrimCsvValue
                    $Node | Add-Member -MemberType:NoteProperty -Name:'CsvObject' -Value:$Csv
                }
            }
        } if ($Name -eq "LogFile") {
            $_.Value = PathTool $Value -NewItem
        }
        # 將加密密碼轉為安全密碼物件
        if ($Name -eq "SecurePassword") {
            $_.Value = ConvertTo-SecureString $Value
        }
    }
    return $Node
} # Import-Param 'Setting.json' -NodeName:'Param1'

# 獲取CSV
# $Param = (Import-Param 'Setting.json' -NodeName:'Param1' -AutoLoadCsv -TrimCsvValue); $Param.CsvObject
# 獲取安全密碼
# $PassWd = DecryptPassWord $Param.SecurePassword; $PassWd
