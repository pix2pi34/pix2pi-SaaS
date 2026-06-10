# FAZ 7-5P.11 — Payment Admin / Ops Readiness / Manual Review Queue

## 7-5P.11.1 Amaç

Bu adım, Payment Provider Adapter modülünü operasyon, destek ve manuel inceleme süreçlerine hazırlar.

Bu seviyede hedef:
- failed payment manuel inceleme kuyruğu kurmak
- retry review kuyruğu kurmak
- webhook dispute/manual review kaydı oluşturmak
- tenant-safe review list/read contract kurmak
- assign / resolve / reject ops action guard eklemek
- tenant audit trail read contract oluşturmak
- cross-tenant review erişimini engellemek
- ileride Ops Console ve support ekranına bağlanacak temel domain modelini hazırlamak

## 7-5P.11.2 Manual review queue modeli

Manual review item alanları:

- review_id
- tenant_id
- attempt_id
- provider_code
- review_type
- status
- priority
- reason
- error_code
- correlation_id
- assigned_to
- created_at
- updated_at
- resolved_message

Review type değerleri:
- FAILED_PAYMENT
- RETRY_REVIEW
- WEBHOOK_DISPUTE

Review status değerleri:
- OPEN
- IN_REVIEW
- RESOLVED
- REJECTED

## 7-5P.11.3 Ops action guard

Desteklenen aksiyonlar:
- ASSIGN
- RESOLVE
- REJECT

Kurallar:
- ASSIGN sadece OPEN kayıt için yapılır
- RESOLVE sadece IN_REVIEW kayıt için yapılır
- REJECT sadece IN_REVIEW kayıt için yapılır
- actor zorunludur
- cross-tenant review access reddedilir

## 7-5P.11.4 Tenant audit trail read contract

PaymentObservabilityRuntime içindeki audit trail kayıtları tenant bazlı okunur.

Ops kullanım amaçları:
- failed payment inceleme
- webhook dispute araştırma
- retry kararı inceleme
- support ticket açıklama
- provider dispute hazırlığı
- incident timeline oluşturma

## 7-5P.11.5 Test ve audit kuralı

Bu adımda final durum sadece gerçek test ve audit sayaçlarından türetilir.

Elle yazılmış final OK satırları test kanıtı sayılmaz.

Zorunlu kanıtlar:
- go test gerçek çalışmalı
- admin/ops test isimleri raw output içinde görünmeli
- dosya/kod/config/doküman karşılıkları audit fonksiyonlarıyla kontrol edilmeli
- failed review queue test edilmeli
- retry review queue test edilmeli
- webhook dispute queue test edilmeli
- ops action guard test edilmeli
- tenant audit trail read contract test edilmeli
- FAIL_COUNT=0 olmadan PASS verilmemeli

## 7-5P.11.6 Kapanış koşulu

Bu adım ancak şu koşullarla PASS sayılır:
- PaymentAdminOpsRuntime var
- manual review queue modeli var
- failed payment review queue var
- retry review queue var
- webhook dispute review queue var
- tenant-safe review list/read var
- assign/resolve/reject guard var
- tenant audit trail read contract var
- cross-tenant access protection test var
- go test PASS
- real implementation audit PASS
- final status sayaçlardan türetilmiş olmalı
