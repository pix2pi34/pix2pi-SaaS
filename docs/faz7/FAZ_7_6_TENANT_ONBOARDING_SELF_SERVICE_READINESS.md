# 7-6 — Tenant Onboarding / Self-Service Readiness

## Adim Amaci

Bu adim Pix2pi icin self-service tenant onboarding hazirligini kurar.

7-6 sonunda:

- Yeni isletme kayit akisi modellenir.
- Tenant olusturma modeli hazirlanir.
- Ilk admin kullanici modeli hazirlanir.
- Demo veri / bos baslangic secimi modellenir.
- Trial subscription baslatma akisi 7-4 subscription runtime ile baglanir.
- Billing profile hazirligi 7-5 billing readiness ile baglanir.
- Onboarding audit izi olusturulur.
- 7-7 Public Website / Landing / Demo Flow icin temel hazirlanir.

## 7-6.1 Onboarding Akisi

### 7-6.1.1 Yeni isletme kayit akisi
Durum: IMPLEMENTED_OR_PRESENT

Yeni isletme kaydi asagidaki alanlarla baslar:

- business_name
- legal_name
- tax_number
- tax_office
- billing_email
- billing_address
- admin_user_id
- admin_email
- plan_code
- start_mode

### 7-6.1.2 Tenant olusturma
Durum: IMPLEMENTED_OR_PRESENT

Tenant olusturma hazirlik modeli:

- tenant_id zorunludur
- account_id zorunludur
- plan_code zorunludur
- tenant_status ACTIVE olarak hazirlanir
- onboarding_status READY_FOR_TRIAL olarak uretilebilir

### 7-6.1.3 Ilk admin kullanici
Durum: IMPLEMENTED_OR_PRESENT

Ilk admin kullanici zorunlu alanlari:

- admin_user_id
- admin_email
- role=TENANT_ADMIN
- tenant_id baglantisi

Admin kullanici olmadan onboarding reddedilir.

### 7-6.1.4 Demo veri / bos baslangic secimi
Durum: IMPLEMENTED_OR_PRESENT

Baslangic modu iki sekilde tanimlanir:

- demo_data
- blank

Gecersiz start_mode reddedilir.

### 7-6.1.5 Onboarding audit izi
Durum: IMPLEMENTED_OR_PRESENT

Onboarding sonucu audit edilebilir alanlar uretir:

- tenant_id
- account_id
- admin_user_id
- admin_email
- plan_code
- start_mode
- onboarding_status
- subscription_status
- billing_status
- decision
- reason_code

## 7-6.2 Subscription Baglantisi

Durum: IMPLEMENTED_OR_PRESENT

Onboarding runtime, 7-4 subscription runtime ile baglanir.

Basarili onboarding sonucunda:

- trial subscription baslar
- subscription status TRIALING olur
- trial_ends_at olusur
- tenant subscription account hazirlanir

## 7-6.3 Billing Profile Baglantisi

Durum: IMPLEMENTED_OR_PRESENT

Onboarding runtime, 7-5 billing readiness ile baglanir.

Basarili onboarding sonucunda:

- billing profile olusur
- invoice draft simulation hazirlanir
- real payment kapali kalir
- billing simulation acik kalir

## 7-6.4 Code Artifact

Durum: IMPLEMENTED_OR_PRESENT

Tenant onboarding Go modeli:

- internal/platform/commercial/onboarding/onboarding.go
- internal/platform/commercial/onboarding/onboarding_test.go

## 7-6.5 Config Artifact

Durum: IMPLEMENTED_OR_PRESENT

Tenant onboarding config dosyasi:

- configs/faz7/tenant_onboarding.v1.json

## 7-6.6 7-7 Gecis Hazirligi

Durum: IMPLEMENTED_OR_PRESENT

7-6 tamamlandiginda 7-7 icin asagidaki temeller hazirdir:

- public landing demo request model
- trial baslatma modeli
- onboarding form alanlari
- billing profile alanlari
- tenant/account/admin hazirlik modeli
- demo_data / blank secimi
- audit edilebilir onboarding sonucu

## 7-6 Final Karari

- FAZ_7_6_DOC_STATUS=READY
- FAZ_7_6_CONFIG_STATUS=READY
- FAZ_7_6_CODE_STATUS=READY
- FAZ_7_6_TEST_REQUIRED=YES
- FAZ_7_6_REAL_IMPLEMENTATION_AUDIT_REQUIRED=YES
- FAZ_7_7_READY_CONDITION=FAZ_7_6_TEST_STATUS_PASS_AND_REAL_IMPLEMENTATION_STATUS_PASS
