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
    # 轉換路徑
    [IO.Directory]::SetCurrentDirectory(((Get-Location -PSProvider FileSystem).ProviderPath))
    $Path = [IO.Path]::GetFullPath($Path)
    # 如果為空路徑則新增檔案
    if ($NewItem) {
        if (!(Test-Path $Path)) { New-Item $Path -Force | Out-Null }
    }
    # 檢測是否為檔案回傳(是否)
    if ($IsItem) {
        if (Test-Path $Path -PathType:Leaf) { return $true } else { return $false }
    }
    return $Path
} # PathTool "Setting.json"

# 轉換並檢查編碼名稱
function cvEncName {
    param (
        [Parameter(Position = 0, ParameterSetName = "")]
        [String] $EncodingName
    )
    $defEnc = [Text.Encoding]::Default
    # $defEnc = [Text.Encoding]::GetEncoding([int](PowerShell -C "& {return ([Text.Encoding]::Default).WindowsCodePage}"))
    if ($EncodingName) {
        try {
            if ($EncodingName -eq 'UTF8') { $EncodingName = 'UTF-8' }
            $Enc = [Text.Encoding]::GetEncoding($EncodingName)
        } catch { try {
                $Enc = [Text.Encoding]::GetEncoding([int]$EncodingName)
            } catch {
                $ErrorMsg = "Encoding `"$EncodingName`" is not a supported encoding name."; throw $ErrorMsg
            } 
        } # Write-Host "Enc = $($Enc.EncodingName)"
        return $Enc
    } # Write-Host "defEnc = $($Enc.EncodingName)"
    return $defEnc
} # cvEncName

# 輸出LOG
function WriteLog {
    param (
        [Parameter(Position = 0, ParameterSetName = "")]
        [String] $Path = ((Get-Item $PSCommandPath).BaseName + ".log"),
        [Parameter(Position = 1, ParameterSetName = "")]
        [String] $FormatType = "yyyy/MM/dd HH:mm:ss.fff",
        [Parameter(ParameterSetName = "")]
        [String] $Encoding,
        [Switch] $NoDate,
        [Switch] $OutNull,
        [Parameter(ValueFromPipeline)] $Msg
    )
    $Enc = [Text.Encoding]::Default
    if ($Encoding) {$Enc = (cvEncName $Encoding)}
    if (!(Test-Path $Path)) { New-Item $Path -Force | Out-Null }
    if ($NoDate) { $LogStr = $Msg } else {
        $LogStr = "[$((Get-Date).Tostring($FormatType))] $Msg"
    } 
    # $LogStr |Out-File $Path -Append
    [IO.File]::AppendAllText($Path, "$LogStr`n", $Enc)
    if (!$OutNull) { Write-Host $LogStr }
} # ("ABCDEㄅㄆㄇㄈあいうえお")|WriteLog 'log.log' -Encoding:950

# 計時器
[TimeSpan]$__StopWatch_temp__ = (New-Object System.TimeSpan)
function StopWatch {
    [CmdletBinding(DefaultParameterSetName = "A")]
    param (
        [Parameter(ParameterSetName = "A")]
        [Switch] $Start,
        [Parameter(ParameterSetName = "B")]
        [Switch] $Stop,
        [Parameter(ParameterSetName = "B")]
        [Switch] $Lap,
        [Parameter(ParameterSetName = "B")]
        [Switch] $Split,
        [Parameter(ParameterSetName = "B", ValueFromPipeline)]
        [Object] $StWh
    )
    if (!$StWh -or $Start) {
        $StWh = New-Object System.Diagnostics.Stopwatch
        $time = [timespan]::FromMilliseconds($StWh.ElapsedMilliseconds)
        $StWh.Start()
        $Script:__StopWatch_temp__ = $time
        return $StWh
    } else {
        $StWh.Stop()
        $time = [timespan]::FromMilliseconds($StWh.ElapsedMilliseconds)
        if ($Stop) { # 暫停計時:: 當前-該計時器暫停
            $result = $time
        } if ($Lap) { # 分圈計時:: 當前-該計時器初始
            $result = $time
            $StWh.Start()
        } elseif ($Split) { # 分段計時:: 當前-任意計時器的上一次的操作
            $result = $time.Add($Script:__StopWatch_temp__.Negate())
            $StWh.Start()
        }
        $Script:__StopWatch_temp__ = $time
        return ("{0:hh\:mm\:ss\.fff}" -f $result)
    }
} # $StWh=(StopWatch -Start); sleep 1; ($StWh|StopWatch -Lap); sleep 1; ($StWh|StopWatch -Stop);



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
    # 載入設定檔
    $Enc  = [Text.Encoding]::Default
    $json = ([IO.File]::ReadAllLines($Path, $Enc)|ConvertFrom-Json)
    $Node = $json.$NodeName
    if ($NULL -eq $Node) { $ErrorMsg = "[$Path]:: $NodeName is NULL"; throw $ErrorMsg; }
    
    
    # 修正數值1
    foreach ($_ in ($Node.PSObject.Properties)) {
        $Name = $_.Name; $Value = $_.Value
        # 檢查各項節點是否為空值，為空值時填入預設值，如預設值也沒有則報例外
        if ($Value -eq "") {
            $defaultValue = $json.Default.$Name
            if ($NULL -eq $defaultValue) { $ErrorMsg = "[$Path]:: $NodeName.$Name is NULL"; throw $ErrorMsg; }
            if ('' -eq $defaultValue) { $ErrorMsg = "[$Path]:: $NodeName.$Name is Empty"; throw $ErrorMsg; }
            $_.Value = $Value = $defaultValue
        }
        # 檢查編碼是否為合法名稱
        if ($Name -match("(.*?)Encoding$")) {
            $_.Value = (cvEncName $_.Value)
        }
    }
    # 修正數值2
    foreach ($_ in ($Node.PSObject.Properties)) {
        $Name = $_.Name; $Value = $_.Value
        # 檢查與修正路徑為絕對路徑 (有錯PathTool會報例外)
        if ($Name -match("(.*?)File$")) { # File 為輸入的檔案, 自動檢查路敬語載入CSV
            $_.Value = PathTool $Value
            # 自動載入CSV檔案
            if (!$NoLoadCsv) {
                if ((Get-Item $_.Value).Extension -eq '.csv') {
                    $Csv = [IO.File]::ReadAllLines($_.Value, $Node.Encoding)|ConvertFrom-Csv
                    $Node | Add-Member -MemberType:NoteProperty -Name:'CsvObject' -Value:$Csv
                    $Field = ($Csv[0].PSObject.Properties.Name)
                    $Node | Add-Member -MemberType:NoteProperty -Name:'Field' -Value:$Field
                }
            }
        } if ($Name -match("(.*?)Path$")) {# Path 為輸出路徑, 不存在則自動建立新檔
            $_.Value = PathTool $Value -NewItem
        }
        # 將加密密碼轉為安全密碼物件
        if ($Name -eq "SecurePWord") {
            $_.Value = ConvertTo-SecureString $Value -EA:0
            if (!$_.Value) {
                Write-Host "[警告]:: 安全密碼物件轉換失敗, 加密明文可能有錯。" -ForegroundColor:Yellow -NoNewline
                Write-Host "(加解密使用者不同也會報錯)"
            }
        }
    }
    
    
    # 建立憑證
    if ($Node.UserID -and $Node.SecurePWord) {
        $Credential = (New-Object -TypeName Management.Automation.PSCredential -ArgumentList:$Node.UserID,$Node.SecurePWord)
        $Node | Add-Member -MemberType:NoteProperty -Name:'Credential' -Value:$Credential
    }
    return $Node
} # Import-Param 'Setting.json' -NodeName:'Param1'

# 必要的話先修復CSV格式
# irm bit.ly/autoFixCsv|iex; autoFixCsv -TrimValue sample1.csv
# 獲取CSV
# $Param = $null
# $Param = (Import-Param 'Setting.json' -NodeName:'Param1')
# if ($Param) { $Param.CsvObject }

# 獲取明碼字串
# $Param  = Import-Param 'Setting.json' -NodeName:'Param1'
# $PassWd = [Runtime.InteropServices.Marshal]::PtrToStringBSTR([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Param.SecurePWord))
# $PassWd

# 獲取憑證
# $Param  = Import-Param 'Setting.json' -NodeName:'Param1'
# $Credential = $Param.Credential


# =================================================================================================
# 循環CSV中ITEM的數值
function ForEachCsvItem {
    [CmdletBinding(DefaultParameterSetName = "A")]
    param (
        # 循環項目的ForEach區塊
        [Parameter(Position = 0, ParameterSetName = "A", Mandatory)]
        [Parameter(Position = 1, ParameterSetName = "B", Mandatory)]
        [scriptblock] $ForEachBlock,
        # PS表格 轉換為自訂 哈希表
        [Parameter(Position = 0, ParameterSetName = "B")]
        [scriptblock] $ConvertObject={
            [Object] $obj = @{}
            foreach ($it in ($_.PSObject.Properties)) {
                $obj += @{$it.Name = $it.Value}
            } return $obj
        },
        # 輸入的物件
        [Parameter(ParameterSetName = "", ValueFromPipeline)]
        [Object] $_
    ) BEGIN { } PROCESS {
    foreach ($_ in $_) {
        $_ = &$ConvertObject($_)
        &$ForEachBlock($_)
    } } END { }
} # (Import-Param 'Setting.json' -NodeName:'Param1').CsvObject | ForEachCsvItem { $_ }

# 範例: 轉換Item至Hashtable
function __ConvertToHashTable__ {
    # CSV 檔案
    $CsvList = (Import-Param 'Setting.json' -NodeName:'Param1').CsvObject
    # 轉換公式
    $ConvertObject={
        $obj = @{}
        $title_idx=0
        $field_idx=1
        foreach ($it in ($_.PSObject.Properties)) {
            if($Title[$title_idx]){
                $Name = $Title[$title_idx]
                $title_idx=$title_idx+1
            } else {
                $Name = "field_$($field_idx)"
                $field_idx = $field_idx+1
            } $obj += @{$Name = $it.Value}
        } return $obj
    }
    # 轉換
    $script:csvIdx=0; $CsvList|ForEachCsvItem -ConvertObject ([ScriptBlock]::Create({$Title=@('Title');}.ToString() + $ConvertObject)) {
        Write-Host "[$($script:csvIdx)]: $_"
        $script:csvIdx = $script:csvIdx+1
    }
} # __ConvertToHashTable__

# =================================================================================================
