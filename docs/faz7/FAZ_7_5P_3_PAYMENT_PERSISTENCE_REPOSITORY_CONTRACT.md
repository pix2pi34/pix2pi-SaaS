# FAZ 7-5P.3 — Payment Persistence / Repository Contract

## 7-5P.3.1 Amac

Bu adim, Payment Provider Adapter modulunde payment attempt kayit katmaninin sozlesmesini kurar.

Bu seviyede hedef:
- PaymentAttemptRepository interface olusturmak
- In-memory repository ile contract davranisini test etmek
- Tenant-safe lookup standardi kurmak
- Attempt id uniqueness kuralini koymak
- Idempotency key uniqueness kuralini koymak
- PaymentAttemptEvent persistence standardini belirlemek
- Update ve event append davranisini test etmek

Bu adim henuz PostgreSQL migration degildir. Once repository contract dogrulanir, sonraki adimda database persistence eklenir.

## 7-5P.3.2 Repository contract

Repository su operasyonlari destekler:

- Save
- Update
- FindByAttemptID
- FindByIdempotencyKey
- AppendEvent
- ListEvents

Tum operasyonlar tenant_id ile calisir.

## 7-5P.3.3 Tenant-safe persistence

Payment attempt kayitlari tenant bazinda izole edilir.

Kurallar:
- Ayni attempt_id farkli tenant icinde ayri kayit olabilir.
- FindByAttemptID tenant_id olmadan calismaz.
- FindByIdempotencyKey tenant_id olmadan calismaz.
- Bir tenant baska tenant attempt kaydini okuyamaz.

## 7-5P.3.4 Uniqueness ve idempotency

Repository seviyesinde iki ana guard vardir:

### Attempt uniqueness
Ayni tenant icinde ayni attempt_id tekrar kaydedilemez.

### Idempotency uniqueness
Ayni tenant icinde ayni idempotency_key farkli attempt_id ile kullanilamaz.

Bu guard cift odeme riskini azaltir.

## 7-5P.3.5 Event persistence

PaymentAttemptEvent history repository seviyesinde saklanir.

Kurallar:
- Attempt create event history ile birlikte kaydedilir.
- Update sonrasi event history korunur.
- AppendEvent ile yeni audit event eklenir.
- ListEvents tenant-safe calisir.

## 7-5P.3.6 Bu adimda kurulan dosyalar

- docs/faz7/FAZ_7_5P_3_PAYMENT_PERSISTENCE_REPOSITORY_CONTRACT.md
- configs/faz7/payment_persistence_repository_contract.v1.json
- internal/platform/commercial/paymentadapter/repository.go
- internal/platform/commercial/paymentadapter/repository_test.go
- docs/faz7/evidence/FAZ_7_5P_3_REAL_IMPLEMENTATION_AUDIT.md

## 7-5P.3.7 Kapanis kosulu

Bu adim ancak su kosullarla PASS sayilir:
- PaymentAttemptRepository interface var
- InMemoryPaymentAttemptRepository var
- Save/Update/FindByAttemptID/FindByIdempotencyKey var
- AppendEvent/ListEvents var
- Tenant-safe lookup testleri var
- Attempt uniqueness testi var
- Idempotency uniqueness testi var
- Event persistence testi var
- Unit testler PASS
- Real implementation audit PASS
