# 7-5 — Billing Readiness

## Adim Amaci

Bu adim Pix2pi icin gercek tahsilat acilmadan once billing hazirligini kurar.

7-5 sonunda:

- Fatura taslak modeli olusur.
- Plan fiyat katalogu olusur.
- KDV hesaplama modeli olusur.
- Muhasebeci paketi firma basi ucret modeli hazirlanir.
- Billing simulation aktif olur.
- Gercek odeme kapisi kapali kalir.
- Mali musavir/vergi onayi gate olarak kaydedilir.
- Gercek odeme saglayici entegrasyonu icin adapter hazirligi yapilir.
- 7-6 Tenant Onboarding / Self-Service Readiness icin temel hazirlanir.

## 7-5.1 Billing Hazirligi

### 7-5.1.1 Fatura hazirlik modeli
Durum: IMPLEMENTED_OR_PRESENT

Billing runtime gercek e-fatura kesmez.
Bu adimda sadece fatura taslagi uretir.

Fatura taslagi alanlari:

- tenant_id
- account_id
- plan_code
- billing_period_start
- billing_period_end
- net_amount_kurus
- vat_rate_bps
- vat_amount_kurus
- gross_amount_kurus
- currency
- billing_status
- real_payment_enabled

### 7-5.1.2 Vergi/KDV uyumu
Durum: IMPLEMENTED_OR_PRESENT

Baslangic KDV modeli:

- default VAT: 20%
- hesaplama basis point ile yapilir
- 20% = 2000 bps
- para birimi TRY
- tutarlar kurus olarak saklanir

### 7-5.1.3 Muhasebeci paketi firma basi ucret modeli
Durum: IMPLEMENTED_OR_PRESENT

Muhasebeci paketi firma sayisina gore ticari olarak genisleyebilir.

Bu adimda:

- accountant_firms usage counter 7-4 subscription runtime'dan gelir
- accountant plan fiyat katalogunda ayrilir
- firma basi ucret ileride 7-9 ve 7-11 ile ticari operasyon paneline baglanir

### 7-5.1.4 Gercek odeme saglayici oncesi billing simulation
Durum: IMPLEMENTED_OR_PRESENT

Billing simulation aciktir.

Bu sayede:

- gercek para cekmeden fatura taslagi uretilir
- plan fiyatlari test edilir
- KDV hesaplari test edilir
- subscription status ile billing karari test edilir

### 7-5.1.5 Gercek odeme entegrasyonu icin adapter hazirligi
Durum: IMPLEMENTED_OR_PRESENT

Gercek odeme adapter'i bu adimda acilmaz.

Gate kurali:

- real_payment_enabled=false
- billing_simulation_enabled=true
- requires_financial_approval_before_real_payment=true

Gercek tahsilat ancak mali musavir/vergi onayi, sozlesme ve odeme saglayici karari sonrasi acilir.

## 7-5.2 Billing Decision Model

### 7-5.2.1 Billing allow
Durum: IMPLEMENTED_OR_PRESENT

Uygun subscription ve billing profile ile fatura taslagi uretilebilir.

### 7-5.2.2 Billing deny
Durum: IMPLEMENTED_OR_PRESENT

Eksik tenant, account, plan, tax profile veya gecersiz subscription status durumunda billing taslagi reddedilir.

### 7-5.2.3 Payment gate deny
Durum: IMPLEMENTED_OR_PRESENT

7-5'te gercek odeme kapali oldugu icin real payment istegi reddedilir.

## 7-5.3 Code Artifact

Durum: IMPLEMENTED_OR_PRESENT

Billing readiness Go modeli:

- internal/platform/commercial/billing/billing.go
- internal/platform/commercial/billing/billing_test.go

## 7-5.4 Config Artifact

Durum: IMPLEMENTED_OR_PRESENT

Billing readiness config dosyasi:

- configs/faz7/billing_readiness.v1.json

## 7-5.5 7-6 Gecis Hazirligi

Durum: IMPLEMENTED_OR_PRESENT

7-5 tamamlandiginda 7-6 icin asagidaki temeller hazirdir:

- tenant subscription billing profile ihtiyaci
- onboarding sirasinda billing profile toplama
- trial/demo icin billing simulation
- gercek odeme kapali gate
- mali/vergi onayi kapisi
- plan fiyat katalogu

## 7-5 Final Karari

- FAZ_7_5_DOC_STATUS=READY
- FAZ_7_5_CONFIG_STATUS=READY
- FAZ_7_5_CODE_STATUS=READY
- FAZ_7_5_TEST_REQUIRED=YES
- FAZ_7_5_REAL_IMPLEMENTATION_AUDIT_REQUIRED=YES
- FAZ_7_6_READY_CONDITION=FAZ_7_5_TEST_STATUS_PASS_AND_REAL_IMPLEMENTATION_STATUS_PASS
