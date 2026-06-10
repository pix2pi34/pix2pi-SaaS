# uzmanparcaci — FAZ 4C UAT Test Cases

## UAT bilgisi

PILOT_BUSINESS_NAME=uzmanparcaci
TENANT_BUSINESS_CODE=UZMANPARCACI
TENANT_ID=6dfe8d22-035a-401f-807c-507408d2e439
TENANT_SCHEMA=tenant_uzmanparcaci
PILOT_USER_EMAIL=uzmanparcaci1@gmail.com
PILOT_ROLE_CODE=PILOT_ADMIN
UAT_MODE=REAL_PILOT_UAT

---

## Ön koşul

4C_6B_UAT_RUNTIME_PRECHECK_STATUS=PASS
4C_6B_STAGING_ROW_COUNT=5
4C_6B_DUPLICATE_SKU_COUNT=0
4C_6B_TENANT_MISMATCH_COUNT=0
4C_6B_OEM_FIELD_COUNT=5
4C_6B_EQUIVALENT_FIELD_COUNT=5
4C_6B_FITMENT_FIELD_COUNT=5

---

## Test cases

### UAT-01 — Tenant erişimi

Amaç: uzmanparcaci tenant bilgisinin doğru olduğunu doğrulamak.

Beklenen:

- TENANT_BUSINESS_CODE=UZMANPARCACI
- TENANT_SLUG=uzmanparcaci
- TENANT_SCHEMA=tenant_uzmanparcaci
- Tenant count = 1

Kabul:

- PASS: Tenant doğru
- FAIL: Tenant yok veya yanlış tenant

---

### UAT-02 — Kullanıcı / rol erişimi

Amaç: pilot kullanıcının doğru tenant ve role bağlı olduğunu doğrulamak.

Beklenen:

- PILOT_USER_EMAIL=uzmanparcaci1@gmail.com
- PILOT_ROLE_CODE=PILOT_ADMIN
- User count = 1
- Role count = 1
- Assignment count = 1
- Cross-tenant assignment = 0

Kabul:

- PASS: Kullanıcı, rol ve assignment doğru
- FAIL: Rol yok, kullanıcı yok veya cross-tenant risk var

---

### UAT-03 — Staging tablo görünürlüğü

Amaç: staging import tablosunun hazır olduğunu doğrulamak.

Beklenen:

- STAGING_TABLE=tenant_uzmanparcaci.pilot_product_import_staging
- Table exists = 1

Kabul:

- PASS: Staging tablo var
- FAIL: Staging tablo yok

---

### UAT-04 — Sample ürün sayısı

Amaç: pilot ürün datasının beklenen sayıda olduğunu doğrulamak.

Beklenen:

- Sample row count = 5

Kabul:

- PASS: 5 ürün var
- FAIL: Ürün sayısı 5 değil

---

### UAT-05 — Duplicate SKU kontrolü

Amaç: aynı SKU tekrarının olmadığını doğrulamak.

Beklenen:

- Duplicate SKU count = 0

Kabul:

- PASS: Duplicate yok
- FAIL: Duplicate SKU var

---

### UAT-06 — Tenant mismatch kontrolü

Amaç: ürün verisinin başka tenant ile karışmadığını doğrulamak.

Beklenen:

- Tenant mismatch count = 0

Kabul:

- PASS: Tenant karışması yok
- FAIL: Başka tenant verisi karışmış

---

### UAT-07 — OEM kod doğrulama

Amaç: oto yedek parça için OEM kodlarının tutulduğunu doğrulamak.

Beklenen:

- OEM field count = 5
- Her ürünün OEM kodu var

Kabul:

- PASS: 5 ürünün OEM kodu var
- FAIL: OEM kod eksik

---

### UAT-08 — Eşdeğer kod doğrulama

Amaç: eşdeğer parça kodlarının tutulduğunu doğrulamak.

Beklenen:

- Equivalent field count = 5
- Her ürünün eşdeğer kodu var

Kabul:

- PASS: 5 ürünün eşdeğer kodu var
- FAIL: Eşdeğer kod eksik

---

### UAT-09 — Araç uyum notu doğrulama

Amaç: arac uyum bilgisinin tutulduğunu doğrulamak.

Beklenen:

- Fitment field count = 5
- Her ürünün araç uyum notu var

Kabul:

- PASS: 5 ürünün araç uyum notu var
- FAIL: Araç uyum notu eksik

---

### UAT-10 — Barkod kararı

Amaç: barkod boşluğunun blocker olmadığını doğrulamak.

Beklenen:

- Barkod boşluğu olabilir
- Pilot işletme barkod kullanmıyor
- Barkod eksikliği blocker değil

Kabul:

- PASS: Barkod eksikliği bilinçli kabul edildi
- WARNING: Barkod ileride istenebilir
- FAIL: Barkod zorunlu kabul edilirse

---

### UAT-11 — Pazaryeri scope guard

Amaç: pazaryeri canlı entegrasyonunun bu fazda beklenmediğini doğrulamak.

Beklenen:

- MARKETPLACE_LIVE_INTEGRATION=NO
- MARKETPLACE_PHASE=FAZ_4D

Kabul:

- PASS: Pazaryeri 4D’ye bırakıldı
- FAIL: 4C içinde canlı pazaryeri bekleniyor

---

### UAT-12 — İşletme kullanıcı kabulü

Amaç: pilot işletme temsilcisinin ilk kapsamı kabul edip etmediğini kayıt altına almak.

Beklenen:

- Kullanıcı “PASS” veya “CONDITIONAL_PASS” verir
- Notlar kayıt altına alınır

Kabul:

- PASS: Kabul var
- CONDITIONAL_PASS: Küçük notlarla kabul var
- FAIL: Kabul yok

---

### UAT-13 — Bug / blocker kaydı

Amaç: UAT sırasında çıkan hataları sınıflandırmak.

Beklenen:

- Critical blocker sayısı kayıt edilir
- Warning sayısı kayıt edilir
- Improvement sayısı kayıt edilir

Kabul:

- PASS: Critical blocker = 0
- FAIL: Critical blocker > 0

---

### UAT-14 — Go / No-Go hazırlığı

Amaç: UAT sonucuna göre sonraki kapıya geçiş kararını hazırlamak.

Beklenen:

- UAT_RESULT=PASS veya CONDITIONAL_PASS
- GO_NO_GO_READY=YES

Kabul:

- PASS: Go/No-Go kapısına geçilebilir
- FAIL: UAT tekrar gerekir

---

## Final status

4C_6C_UAT_TEST_CASE_PACKAGE_STATUS=PASS
4C_6C_TEST_CASE_COUNT=14
4C_6C_CRITICAL_BLOCKER_RULES_DEFINED=YES
4C_6C_DB_WRITE_APPLIED=NO
4C_6D_READY=YES
