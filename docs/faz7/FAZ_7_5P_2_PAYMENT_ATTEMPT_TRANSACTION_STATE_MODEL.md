# FAZ 7-5P.2 — Payment Attempt / Transaction State Model

## 7-5P.2.1 Amac

Bu adim, Payment Provider Adapter modulune odeme denemesi ve transaction state modelini ekler.

Bu seviyede hedef:
- Payment attempt modelini kurmak
- Provider transaction id mapping standardini belirlemek
- Odeme yasam dongusu state gecislerini tanimlamak
- Idempotency-safe attempt kuralini eklemek
- Contract decision sonucunu attempt state modeline baglamak
- Audit-ready event history olusturmak

## 7-5P.2.2 Payment attempt modeli

Payment attempt bir odeme denemesidir.

Zorunlu alanlar:
- attempt_id
- tenant_id
- invoice_id
- provider_code
- correlation_id
- idempotency_key
- amount_minor
- currency

Bu model, ileride database persistence katmanina tasinacak ana transaction kaydidir.

## 7-5P.2.3 Transaction state modeli

Desteklenen state degerleri:

- CREATED
- AUTHORIZED
- CAPTURED
- REFUNDED
- VOIDED
- FAILED

Gecerli ana akislar:

- CREATED -> AUTHORIZED
- CREATED -> FAILED
- AUTHORIZED -> CAPTURED
- AUTHORIZED -> VOIDED
- AUTHORIZED -> FAILED
- CAPTURED -> REFUNDED
- CAPTURED -> FAILED

## 7-5P.2.4 Provider transaction mapping

Provider tarafindan donen transaction id su operasyonlardan sonra saklanir:
- AUTHORIZE
- CAPTURE
- REFUND
- VOID

Capture, refund ve void operasyonlarinda provider transaction id onceki transaction ile uyumlu olmalidir.

## 7-5P.2.5 Idempotency-safe attempt

Ayni attempt icin gelen tekrar isteklerde:
- idempotency_key ayniysa guvenli tekrar olarak kabul edilebilir
- idempotency_key farkliysa cift odeme riski nedeniyle reddedilir

Bu sayede:
- tekrar authorize riski azaltilir
- cift capture riski azaltilir
- cift refund riski azaltilir
- audit trail bozulmaz

## 7-5P.2.6 Audit event history

Her state gecisi PaymentAttemptEvent olarak kaydedilir.

Event alanlari:
- from_status
- to_status
- operation
- provider_code
- provider_transaction_id
- error_code
- message
- correlation_id
- idempotency_key
- audit_required
- real_payment

## 7-5P.2.7 Bu adimda kurulan dosyalar

- docs/faz7/FAZ_7_5P_2_PAYMENT_ATTEMPT_TRANSACTION_STATE_MODEL.md
- configs/faz7/payment_attempt_transaction_state.v1.json
- internal/platform/commercial/paymentadapter/attempt.go
- internal/platform/commercial/paymentadapter/attempt_test.go
- docs/faz7/evidence/FAZ_7_5P_2_REAL_IMPLEMENTATION_AUDIT.md

## 7-5P.2.8 Kapanis kosulu

Bu adim ancak su kosullarla PASS sayilir:
- PaymentAttempt modeli var
- PaymentAttemptStatus modeli var
- CREATED/AUTHORIZED/CAPTURED/REFUNDED/VOIDED/FAILED state degerleri var
- State transition guard var
- Provider transaction mapping var
- Idempotency replay guard var
- Audit event history var
- Unit testler PASS
- Real implementation audit PASS
