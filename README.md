# ecc-encryption-verify

步驟：
- 1.En_A(b)：Bob使用Alice的公開金鑰 A 加密隨機數 b。
- 2.c = m + b：Alice將秘密 m 和Bob的隨機數 b 相加。
- 3.驗證 C = (m + b)G 應該等於 M + B。
- 4.Bob計算 m = c - b，得到秘密值m。

## 環境
### 智能合約：
- 測試於本地區塊鏈 Ganache 
- compiler version: 0.8.27 (cancun)
- optimization runs set to 200
### Python：
- version 3.7
- 用於傳輸參數與收集gas消耗數值
