# =================================================================================================
# 修復路徑工具
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

# 輸出LOG
function WriteLog {
    param (
        [String] $Path,
        [Switch] $NoDate,
        [Parameter(ValueFromPipeline)] $Msg
    )
    if (!$Path) { $Path = (Get-Item $PSCommandPath).BaseName + ".log" }
    if (!(Test-Path $Path)) { New-Item $Path -Force | Out-Null }
    if ($NoDate) { $LogStr = $Msg } else {
        $LogStr = "[$((Get-Date).Tostring("yyyy/MM/dd HH:mm:ss.fff"))] $Msg"
    } $LogStr |Out-File $Path -Append
} # ("Log Test")|WriteLog

# 計時器
function StopWatch {
    [CmdletBinding(DefaultParameterSetName = "A")]
    param (
        [Parameter(ParameterSetName = "A")]
        [Switch] $Start,
        [Parameter(ParameterSetName = "B")]
        [Switch] $Stop,
        [Parameter(ParameterSetName = "B", ValueFromPipeline)]
        [Object] $StWh
    )
    if (!$StWh -or $Start) {
        $StWh = New-Object System.Diagnostics.Stopwatch
        $StWh.Start()
        return $StWh
    } else {
        $StWh.Stop()
        return ("{0:hh\:mm\:ss\.fff}" -f [timespan]::FromMilliseconds($StWh.ElapsedMilliseconds))
    }
} # $StWh=(StopWatch -Start); sleep 1; ($StWh|StopWatch -Stop);

# =================================================================================================
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
        
        [Switch] $NoLoadCsv,
        [Switch] $TrimCsvValue
    )
    # 開始計時
    $Date = (Get-Date); $StWh = New-Object System.Diagnostics.Stopwatch; $StWh.Start()
    
    # $PSBaseName = Split-Path $MyInvocation.MyCommand.Name -LeafBase
    $json = (Get-Content $Path|ConvertFrom-Json)
    $Node = $json.$NodeName
    if ($NULL -eq $Node) { $ErrorMsg = "[$Path]:: $NodeName is NULL"; throw $ErrorMsg; }

    foreach ($_ in ($Node.PSObject.Properties)) {
        $Name  = $_.Name; $Value = $_.Value
        # 檢查各項節點是否為空值，為空值時填入預設值，如預設值也沒有則報例外
        if ($Value -eq "") {
            $defaultValue = $json.Default.$Name
            if ($NULL -eq $defaultValue) { $ErrorMsg = "[$Path]:: $NodeName.$Name is NULL"; throw $ErrorMsg; }
            if ('' -eq $defaultValue) { $ErrorMsg = "[$Path]:: $NodeName.$Name is Empty"; throw $ErrorMsg; }
            $_.Value = $Value = $defaultValue
        }
        
        # 檢查與修正路徑為絕對路徑 (有錯PathTool會報例外)
        if ($Name -match("(.*?)File$")) { # File 為輸入的檔案, 自動檢查路敬語載入CSV
            $Name
            $_.Value = PathTool $Value
            # 自動載入CSV檔案
            if (!$NoLoadCsv) {
                if ((Get-Item $_.Value).Extension -eq '.csv') {
                    $Csv = Import-Csv $_.Value
                    $Node | Add-Member -MemberType:NoteProperty -Name:'CsvObject' -Value:$Csv
                }
            }
        } if ($Name -match("(.*?)Path$")) {# Path 為輸出路徑, 不存在則自動建立新檔
            $_.Value = PathTool $Value -NewItem
        }
        # 將加密密碼轉為安全密碼物件
        if ($Name -eq "SecurePWord") {
            $_.Value = ConvertTo-SecureString $Value
        }
    }
    
    # 建立憑證
    if ($Node.UserID -and $Node.SecurePWord) {
        $Credential = (New-Object -TypeName Management.Automation.PSCredential -ArgumentList:$Node.UserID,$Node.SecurePWord)
        $Node | Add-Member -MemberType:NoteProperty -Name:'Credential' -Value:$Credential
    }
    
    # 停止計時
    $StWh.Stop(); $Time = "{0:hh\:mm\:ss\.fff}" -f [timespan]::FromMilliseconds($StWh.ElapsedMilliseconds)
    
    # 輸出LOG
    $LogPath = $Node.LogPath
    $Date    = $Date.Tostring("yyyy/MM/dd HH:mm:ss.fff")
    $Msg     = "設定檔載入完成"
    $LogStr  = "[$Date] $Msg" + (", 耗時: $Time")
    $LogStr  | Out-File $LogPath -Append
    
    return $Node
} # Import-Param 'Setting.json' -NodeName:'Param1'

# 必要的話先修復CSV格式
# irm bit.ly/autoFixCsv|iex; autoFixCsv -TrimValue sample1.csv
# 獲取CSV
# $Param = (Import-Param 'Setting.json' -NodeName:'Param1')
# $Param.CsvObject

# 獲取明碼字串
# $Param  = Import-Param 'Setting.json' -NodeName:'Param1'
# $PassWd = [Runtime.InteropServices.Marshal]::PtrToStringBSTR([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Param.SecurePWord))
# $PassWd

# 獲取憑證
# $Param  = Import-Param 'Setting.json' -NodeName:'Param1'
# $Credential = $Param.Credential
# =================================================================================================
