# =================================================================================================
# 獲取編碼
Invoke-RestMethod "raw.githubusercontent.com/hunandy14/Get-Encoding/master/Get-Encoding.ps1"|Invoke-Expression
# 計時器
Invoke-RestMethod "raw.githubusercontent.com/hunandy14/StopWatch/master/StopWatch.ps1"|Invoke-Expression
# 日誌輸出器
Invoke-RestMethod "raw.githubusercontent.com/hunandy14/WriteLog/master/WriteLog.ps1"|Invoke-Expression


# =================================================================================================
# 環境變數設定
function Set-Environment {
    param(
        [Parameter(Position = 0, ParameterSetName = "", Mandatory)]
        [string] $Name,
        [Parameter(Position = 1, ParameterSetName = "", Mandatory)]
        [string] $Value,
        [switch] $Append
    )
    # パスの修正
    $Value = $Value -replace("/","\")
    # 環境変数の設定
    if (!$Append) {
        $cmd = "`$env:$Name = '$Value'"
        # Write-Host $cmd
        Invoke-Expression $cmd
    } else {
        $EnvValue = (Invoke-Expression "`$env:$Name;") -replace(";+",";")
        if ($EnvValue.IndexOf($Value) -eq -1) {
            $EnvValue += "$Value;"
            $cmd = "`$env:$Name = '$EnvValue'"
            # Write-Host $cmd
            Invoke-Expression $cmd
        }
    }
} # Set-Environment Path C:\bin

# 載入環境變數
function LoadEnvVar {
    param (
        [Parameter(Position = 0, ParameterSetName = "", Mandatory)]
        [Object] $EnvObject
    )
    # ロード
    $AppendList = @("Path")
    $EnvObject.PSObject.Properties |ForEach-Object{
        $Name=$_.Name; $Value=$_.Value
        if ($AppendList -match $Name) { $Append=$true } else { $Append=$false }
        Set-Environment $Name $Value -Append:$Append
    }
} # LoadEnvVar ('{"Env": {"Path": "W:/App/instantclient_21_8", "NLS_LANG": "Japanese_Japan.JA16SJIS"}}' |ConvertFrom-Json).Env


# =================================================================================================
# 修復路徑工具
function PathTool {
    [CmdletBinding(DefaultParameterSetName = "A")]
    param (
        [Parameter(Position = 0, ParameterSetName = "", Mandatory)]
        [String] $Path,
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


# =================================================================================================
# 讀取設定檔
function Import-Param {
    param (
        [Parameter(Position = 0, ParameterSetName = "")]
        [String] $Path = "Setting.json",
        [Parameter(Position = 1, ParameterSetName = "", Mandatory)]
        [String] $NodeName,
        # 編碼選項
        [Parameter(ParameterSetName = "")]
        [String] $Encoding,
        [Switch] $SystemEncoding,
        # CSV檔案選項
        [Switch] $NoLoadCsv,
        [Switch] $TrimCsvValue,
        # 密碼選項
        [Switch] $AsPlainTextPWord,    # 從明碼轉換(Json檔案裡寫的不是加密文而是明碼文時使用)
        [Switch] $ForceConvertPWord,   # 密碼物件生成錯誤時強制使用空白密碼生成物件
        [Switch] $NoConvertPWord       # 禁用安全密碼物件生成與認證物件生成(啟用時上面兩個選項就沒有意義了)
    )
    # 載入設定檔
    $sysEnc=$SystemEncoding; $Enc1 = (Get-Encoding $Encoding -SystemEncoding:$sysEnc)
    try{ $json = ([IO.File]::ReadAllLines($Path, $Enc1)|ConvertFrom-Json) } catch {
        $sysEnc=!$SystemEncoding; $Enc1 = (Get-Encoding $Encoding -SystemEncoding:$sysEnc)
        try{ $json = ([IO.File]::ReadAllLines($Path, $Enc1)|ConvertFrom-Json) } catch {
            Write-Error ($Error[$Error.Count-1]); return
        }
    }
    $Enc2 = (Get-Encoding $json.ThisJsonEncoding -SystemEncoding:$sysEnc)
    if ($Enc2 -ne $Enc1) {
        $Enc1 = $Enc2
        try{ $json = ([IO.File]::ReadAllLines($Path, $Enc1)|ConvertFrom-Json) } catch {
            Write-Error ($Error[$Error.Count-1]); return
        }
    }
    
    # 獲取節點
    # $json = ([IO.File]::ReadAllLines($Path, (Get-Encoding $Encoding -SystemEncoding:$SystemEncoding))|ConvertFrom-Json)
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
        # 獲取Pwsh編碼物件
        if ($Name -match("(.*?)Encoding$")) {
            $_.Value = (Get-Encoding $_.Value)
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
        } if ($Name -match("(.*?)Path$")) { # Path 為輸出路徑, 不存在則自動建立新檔
            $_.Value = PathTool $Value -NewItem
        }
        # 生成安全密碼物件
        if (($Name -eq "SecurePWord") -and (!$NoConvertPWord)) {
            if ($AsPlainTextPWord) {          # 強制使用明碼生成
                $_.Value = ConvertTo-SecureString $_.Value -AsPlainText -Force
            } else {                          # 使用加密密碼生成
                $_.Value = ConvertTo-SecureString $_.Value -EA:0
                if (!$_.Value) {
                    if ($ForceConvertPWord) { # 強制轉換(失敗時用空白密碼轉換)
                        $_.Value = ConvertTo-SecureString " " -AsPlainText -Force
                    } else {
                        Write-Host "[Warning]:: Security password object conversion failed." -ForegroundColor:Yellow
                        Write-Host "(The encrypted plaintext is wrong or the users of encryption and decryption are different)"
                        Write-Host "  Generate secure password example -> " -NoNewline
                        Write-Host "ConvertFrom-SecureString(ConvertTo-SecureString -A -F `"PassWD`")" -ForegroundColor:DarkCyan
                    }
                }
            }
        }
    }
    
    # 建立憑證
    if (($Node.UserID) -and (!$NoConvertPWord)) {
        if ($Node.SecurePWord) {
            $Credential = (New-Object -TypeName Management.Automation.PSCredential -ArgumentList:$Node.UserID,$Node.SecurePWord)
        } else { # 沒有密碼則由終端輸入
            $Credential = (Get-Credential $Node.UserID)
        } $Node | Add-Member -MemberType:NoteProperty -Name:'Credential' -Value:$Credential
    }
    return $Node
} # Import-Param -NodeName:'Default'
# Import-Param 'Setting.json' 'Param1'
# Import-Param 'Setting.json' -NodeName:'Param1'
# Import-Param 'Setting.json'
# Import-Param -NodeName:'Param1' -ForceConvertPWord
# Import-Param -NodeName:'Param1' -NoConvertPWord
# Import-Param -NodeName:'Param1' -AsPlainTextPWord

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
        [Object] $InputObject
    ) BEGIN { } PROCESS {
    foreach ($Item in $InputObject) {
        $obj = &$ConvertObject($Item)
        &$ForEachBlock($obj)
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
