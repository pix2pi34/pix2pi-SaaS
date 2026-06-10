# FAZ 4C — 4C-6 Real UAT Execution

## Amaç

Bu blokta uzmanparcaci gerçek pilot işletmesi için UAT yapılacaktır.

UAT, teknik test değil; gerçek kullanıcı / işletme gözüyle kabul testidir.

---

## Ön koşul

4C-5 Real Pilot Data Entry / Import kapanmış olmalıdır.

Beklenen durum:

4C_5_FINAL_STATUS=PASS
4C_5_REAL_PILOT_DATA_ENTRY_IMPORT_STATUS=PASS
4C_5_STAGING_DB_WRITE_APPLIED=YES
4C_5_CORE_DB_WRITE_APPLIED=NO
4C_5_CRITICAL_BLOCKER_COUNT=0
4C_6_READY=YES

---

## Pilot

PILOT_BUSINESS_NAME=uzmanparcaci
PILOT_SECTOR=OTO_YEDEK_PARCA
PILOT_USER_EMAIL=uzmanparcaci1@gmail.com
PILOT_ROLE_CODE=PILOT_ADMIN

---

## UAT kapsamı

UAT alanları:

1. Tenant erişimi
2. Kullanıcı / rol erişimi
3. Staging ürün verisi görünürlüğü
4. Ürün import veri kalitesi
5. Oto yedek parça özel alanları
6. İşletme kullanıcı onayı
7. Bug / blocker kayıtları
8. Go / No-Go hazırlığı

---

## UAT kapsam dışı

FAZ 4C UAT içinde yapılmayacaklar:

- Canlı pazaryeri entegrasyonu yok
- Trendyol / Hepsiburada / N11 canlı API yok
- Paraşüt canlı senkron yok
- ERP core product apply yok
- Canlı e-Fatura / e-Arşiv yok
- Canlı ödeme / banka / POS yok
- Tam TECDOC motoru yok
- Otomatik web scraping yok

Pazaryeri entegrasyonu FAZ 4D kapsamındadır.

---

## 4C-6 planı

1. 4C-6A — UAT Execution Plan / Checklist Freeze
2. 4C-6B — UAT Runtime Precheck
3. 4C-6C — UAT Test Case Package
4. 4C-6D — UAT Execution / Evidence Capture
5. 4C-6E — UAT Result Classification
6. 4C-6F — UAT Bug / Blocker Register
7. 4C-6G — UAT Business Acceptance Gate
8. 4C-6H — UAT Final Closure

---

## 4C-6A status

4C_6A_UAT_EXECUTION_PLAN_STATUS=PASS
4C_6A_UAT_SCOPE_STATUS=FROZEN
4C_6A_SELECTED_BUSINESS=uzmanparcaci
4C_6A_SELECTED_SECTOR=OTO_YEDEK_PARCA
4C_6A_UAT_MODE=REAL_PILOT_UAT
4C_6A_UAT_EXECUTION_TYPE=CHECKLIST_BASED
4C_6A_DB_WRITE_APPLIED=NO
4C_6B_READY=YES
