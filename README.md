# ecc-encryption-verify

步驟：
1.En_A(b)：Bob使用Alice的公開金鑰 A 加密隨機數 b。
2.c = m + b：Alice將秘密 m 和Bob的隨機數 b 相加。
3.驗證 C = (m + b)G 應該等於 M + B。
4.Bob計算 m = c - b，得到秘密值m。
