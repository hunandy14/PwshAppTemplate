載入設定檔通用模組
===

快速使用
```ps1
irm bit.ly/Import-Param|iex; Import-Param 'Setting.json' -NodeName:'Param1'
```

詳細說明
```ps1
# 載入函式
irm bit.ly/Import-Param|iex

# 計時器開始
$StWh=(StopWatch -Start)
# 分圈計時 (當前-開始)
($StWh|StopWatch -Lap)
# 分段計時 (當前-上一次計時器操作)
($StWh|StopWatch -Split)
# 停止計時
($StWh|StopWatch -Stop)

# log輸出
("ABCDEㄅㄆㄇㄈあいうえお")|WriteLog 'log.log' -Encoding:'UTF-8'
```