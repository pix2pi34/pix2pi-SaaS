# 7-4 — Commercial Account / Subscription Runtime

## Adim Amaci

Bu adim Pix2pi ticari hesap ve subscription runtime temelini kurar.

7-4 sonunda:

- Tenant subscription kaydi modellenir.
- Plan degisikligi runtime seviyesinde desteklenir.
- Trial/demo suresi modellenir.
- Paket yenileme modellenir.
- Askiya alma / yeniden acma modellenir.
- Canceled / expired durumlari modellenir.
- Subscription durumu entitlement runtime ile baglanir.
- 7-5 Billing Readiness icin temel hazirlanir.

## 7-4.1 Subscription Modeli

### 7-4.1.1 Tenant subscription kaydi
Durum: IMPLEMENTED_OR_PRESENT

Her ticari hesap tenant_id, account_id, plan_code ve status alanlariyla temsil edilir.

Zorunlu alanlar:

- tenant_id
- account_id
- plan_code
- subscription_status
- current_period_start
- current_period_end

### 7-4.1.2 Plan degisikligi
Durum: IMPLEMENTED_OR_PRESENT

Subscription runtime plan degisikligini destekler.

Plan degisikligi sirasinda:

- Eski plan korunabilir audit verisi olarak izlenir.
- Yeni plan catalog icinde mevcut olmalidir.
- Unknown plan reddedilir.
- Entitlement kontrolleri yeni plana gore calisir.

### 7-4.1.3 Trial/demo suresi
Durum: IMPLEMENTED_OR_PRESENT

Trial/demo subscription status'u TRIALING olarak tutulur.

Trial icin:

- trial_ends_at zorunludur.
- trial suresi dolmadiysa feature/limit kontrolu calisabilir.
- trial suresi dolduysa DENY doner.

### 7-4.1.4 Paket yenileme
Durum: IMPLEMENTED_OR_PRESENT

Subscription runtime renew islemini destekler.

Renew islemi:

- current_period_start alanini yeni baslangica ceker.
- current_period_end alanini yeni sureye gore gunceller.
- status'u ACTIVE yapar.
- usage sayaçlarini yeni periyoda sifirlar.

### 7-4.1.5 Askiya alma / yeniden acma
Durum: IMPLEMENTED_OR_PRESENT

Subscription runtime suspend ve resume islemlerini destekler.

- SUSPENDED durumda feature/limit kullanimi reddedilir.
- Resume islemi status'u ACTIVE yapar.
- CANCELED hesap resume edilemez.

## 7-4.2 Status Modeli

### 7-4.2.1 ACTIVE
Durum: IMPLEMENTED_OR_PRESENT

Aktif subscription, sure dolmadiysa entitlement kontrolune girebilir.

### 7-4.2.2 TRIALING
Durum: IMPLEMENTED_OR_PRESENT

Trial subscription, trial_ends_at dolmadiysa entitlement kontrolune girebilir.

### 7-4.2.3 SUSPENDED
Durum: IMPLEMENTED_OR_PRESENT

Askiya alinmis subscription tum feature ve limit kontrollerini reddeder.

### 7-4.2.4 CANCELED
Durum: IMPLEMENTED_OR_PRESENT

Iptal edilmis subscription tum feature ve limit kontrollerini reddeder.

### 7-4.2.5 EXPIRED
Durum: IMPLEMENTED_OR_PRESENT

Suresi dolmus subscription tum feature ve limit kontrollerini reddeder.

## 7-4.3 Entitlement Baglantisi

Durum: IMPLEMENTED_OR_PRESENT

Subscription runtime, 7-3 entitlement runtime ile baglanir.

Kontrol akisi:

1. Subscription operational mi?
2. Tenant/user context mevcut mu?
3. Plan catalog icinde mevcut mu?
4. Feature plan icinde acik mi?
5. Limit asiliyor mu?

## 7-4.4 Usage Counters

Durum: IMPLEMENTED_OR_PRESENT

Subscription account icinde temel usage sayaçlari tutulur:

- current_users
- current_tenants
- current_api_requests
- current_exports
- current_accountant_firms
- current_integrations

Bu sayaçlar 7-5 billing readiness ve 7-11 commercial ops console icin temel veri olacaktir.

## 7-4.5 Code Artifact

Durum: IMPLEMENTED_OR_PRESENT

Subscription runtime Go modeli:

- internal/platform/commercial/subscription/subscription.go
- internal/platform/commercial/subscription/subscription_test.go

## 7-4.6 Config Artifact

Durum: IMPLEMENTED_OR_PRESENT

Subscription runtime config dosyasi:

- configs/faz7/subscription_runtime.v1.json

## 7-4.7 7-5 Gecis Hazirligi

Durum: IMPLEMENTED_OR_PRESENT

7-4 tamamlandiginda 7-5 icin asagidaki runtime temeller hazirdir:

- Subscription account modeli
- Status modeli
- Trial/demo modeli
- Renewal modeli
- Plan change modeli
- Suspend/resume/cancel modeli
- Usage counter modeli
- Entitlement runtime entegrasyonu

## 7-4 Final Karari

- FAZ_7_4_DOC_STATUS=READY
- FAZ_7_4_CONFIG_STATUS=READY
- FAZ_7_4_CODE_STATUS=READY
- FAZ_7_4_TEST_REQUIRED=YES
- FAZ_7_4_REAL_IMPLEMENTATION_AUDIT_REQUIRED=YES
- FAZ_7_5_READY_CONDITION=FAZ_7_4_TEST_STATUS_PASS_AND_REAL_IMPLEMENTATION_STATUS_PASS
