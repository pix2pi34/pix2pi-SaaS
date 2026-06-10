# FAZ 7-5P.4 — Payment DB Migration / PostgreSQL Repository

## 7-5P.4.1 Amaç

Bu adım, Payment Provider Adapter modülünde payment attempt kayıtlarını PostgreSQL tarafına hazırlar.

Bu seviyede hedef:
- `payment_attempts` tablosunu tanımlamak
- `payment_attempt_events` tablosunu tanımlamak
- tenant-safe primary/unique/index yapısını kurmak
- PostgreSQL repository implementasyonu eklemek
- `PaymentAttemptRepository` interface'inin PostgreSQL karşılığını oluşturmak
- DB bağlantısı olmadan compile/test edilebilir repository contract testleri yazmak
- gerçek migration ve kod/config/doküman karşılığını audit etmek

## 7-5P.4.2 Migration tabloları

### payment_attempts

Ana ödeme denemesi kaydıdır.

Zorunlu alanlar:
- tenant_id
- attempt_id
- invoice_id
- provider_code
- correlation_id
- idempotency_key
- amount_minor
- currency
- status

Güvenlik:
- PRIMARY KEY (tenant_id, attempt_id)
- UNIQUE (tenant_id, idempotency_key)
- tenant_id bazlı lookup
- provider_transaction_id index

### payment_attempt_events

Ödeme denemesi event history kaydıdır.

Zorunlu alanlar:
- tenant_id
- attempt_id
- from_status
- to_status
- operation
- provider_code
- message
- correlation_id
- idempotency_key
- audit_required
- real_payment
- occurred_at

Güvenlik:
- FK (tenant_id, attempt_id) -> payment_attempts
- tenant bazlı event listeleme indexi

## 7-5P.4.3 PostgreSQL repository

PostgreSQL repository şu operasyonları destekler:

- Save
- Update
- FindByAttemptID
- FindByIdempotencyKey
- AppendEvent
- ListEvents

Tüm operasyonlar tenant_id ile çalışır.

## 7-5P.4.4 Idempotency ve uniqueness

Bu adımda DB seviyesinde iki kritik guard vardır:

- tenant_id + attempt_id primary key
- tenant_id + idempotency_key unique constraint

Bu sayede aynı tenant içinde:
- aynı attempt iki kez kaydedilemez
- aynı idempotency key farklı attempt için kullanılamaz

## 7-5P.4.5 Test yaklaşımı

Bu adımda canlı DB bağlantısı zorunlu değildir.

Gerçek test kanıtı:
- `go test ./internal/platform/commercial/paymentadapter -v`
- migration dosyası içerik testi
- SQL statement tenant-safe clause testi
- PostgreSQL repository interface compile testi
- SQL args tenant/idempotency/audit alan testi
- real implementation audit sayaçları

Elle yazılmış final OK satırları test kanıtı sayılmaz.

## 7-5P.4.6 Kapanış koşulu

Bu adım ancak şu koşullarla PASS sayılır:
- migration SQL var
- payment_attempts tablosu var
- payment_attempt_events tablosu var
- tenant_id + attempt_id primary key var
- tenant_id + idempotency_key unique constraint var
- provider_transaction_id index var
- PostgreSQLPaymentAttemptRepository var
- Save/Update/FindByAttemptID/FindByIdempotencyKey/AppendEvent/ListEvents PostgreSQL kodu var
- PaymentAttemptRepository interface implementasyonu compile oluyor
- Go test PASS
- Real implementation audit PASS
- FAIL_COUNT=0
