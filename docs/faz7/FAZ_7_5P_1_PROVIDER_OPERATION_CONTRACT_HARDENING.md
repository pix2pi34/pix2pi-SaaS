# FAZ 7-5P.1 — Provider Contract / Operation Contract Hardening

## 7-5P.1.1 Amac

Bu adim, FAZ 7-5P ile kurulan Payment Provider Adapter temelini daha kurumsal hale getirir.

Bu seviyede hedef:
- Her odeme operasyonu icin zorunlu alanlari netlestirmek
- Provider capability matrix kurmak
- Standart hata kodlari olusturmak
- Webhook dogrulama kontratini ayirmak
- Capture / refund / void operasyonlarinda provider transaction id zorunlulugunu belirlemek
- Production real payment gate kuralini sozlesme katmaninda da korumak
- Tum kararlarin audit edilebilir olmasini saglamak

## 7-5P.1.2 Operasyon sozlesmeleri

Desteklenen operasyonlar:

### AUTHORIZE
Zorunlu:
- tenant_id
- correlation_id
- idempotency_key
- amount_minor
- currency

### CAPTURE
Zorunlu:
- tenant_id
- correlation_id
- idempotency_key
- provider_transaction_id
- amount_minor
- currency

### REFUND
Zorunlu:
- tenant_id
- correlation_id
- idempotency_key
- provider_transaction_id
- amount_minor
- currency

### VOID
Zorunlu:
- tenant_id
- correlation_id
- idempotency_key
- provider_transaction_id

### WEBHOOK_VERIFY
Zorunlu:
- tenant_id
- correlation_id
- webhook_signature
- raw_webhook_payload

## 7-5P.1.3 Provider capability matrix

Her provider icin hangi operasyonlarin desteklendigi config ve kod tarafinda belirlenir.

Bu sayede:
- Provider desteklemiyorsa REFUND kapali tutulabilir
- VOID destegi provider bazinda kapatilabilir
- Webhook gerekliligi provider bazinda enforce edilebilir
- Production mode gercek odeme kapisi kapaliysa islem bloklanir

## 7-5P.1.4 Standart hata kodlari

Bu adimda hata kodlari standartlastirilir:

- PAYMENT_TENANT_REQUIRED
- PAYMENT_CORRELATION_REQUIRED
- PAYMENT_IDEMPOTENCY_REQUIRED
- PAYMENT_AMOUNT_REQUIRED
- PAYMENT_CURRENCY_REQUIRED
- PAYMENT_PROVIDER_TRANSACTION_REQUIRED
- PAYMENT_WEBHOOK_SIGNATURE_REQUIRED
- PAYMENT_WEBHOOK_PAYLOAD_REQUIRED
- PAYMENT_OPERATION_UNSUPPORTED
- PAYMENT_PROVIDER_MISMATCH
- PAYMENT_PRODUCTION_GATE_CLOSED

## 7-5P.1.5 Guvenlik ve audit karari

Her karar asagidaki alanlari uretir:
- allowed
- status
- provider_code
- mode
- operation
- error_code
- message
- retryable
- audit_required
- real_payment

Bu karar modeli ileride:
- payment attempt table
- webhook event table
- settlement reconciliation
- provider incident log
- accounting integration

icin temel olur.

## 7-5P.1.6 Bu adimda kurulan dosyalar

- docs/faz7/FAZ_7_5P_1_PROVIDER_OPERATION_CONTRACT_HARDENING.md
- configs/faz7/payment_provider_contract.v1.json
- internal/platform/commercial/paymentadapter/contracts.go
- internal/platform/commercial/paymentadapter/contracts_test.go
- docs/faz7/evidence/FAZ_7_5P_1_REAL_IMPLEMENTATION_AUDIT.md

## 7-5P.1.7 Kapanis kosulu

Bu adim ancak su kosullarla PASS sayilir:
- Provider capability matrix var
- Operation contract modeli var
- Standart hata kodlari var
- Webhook contract guard var
- Capture/refund/void provider transaction id guard var
- Production real payment gate contract seviyesinde var
- Unit testler PASS
- Real implementation audit PASS
