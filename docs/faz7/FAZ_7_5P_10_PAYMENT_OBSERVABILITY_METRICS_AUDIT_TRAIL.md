# FAZ 7-5P.10 — Payment Observability / Metrics / Audit Trail Readiness

## 7-5P.10.1 Amaç

Bu adım, Payment Provider Adapter modülüne observability, metric ve audit trail hazırlık katmanı ekler.

Bu seviyede hedef:
- payment operation metric sayaçları oluşturmak
- authorize / capture / refund / void / webhook metriclerini izlemek
- failed payment metriclerini izlemek
- retry decision metriclerini izlemek
- duplicate webhook metriclerini izlemek
- tenant bazlı audit trail kayıtları oluşturmak
- audit trail export/readiness modeli kurmak
- ileride Prometheus / Grafana / Ops Console entegrasyonuna hazır olmak

## 7-5P.10.2 Metric modeli

Temel metric grupları:

- payment_operation_total
- payment_operation_authorize_total
- payment_operation_capture_total
- payment_operation_refund_total
- payment_operation_void_total
- payment_webhook_verified_total
- payment_failed_total
- payment_retry_allowed_total
- payment_retry_denied_total
- payment_retry_non_retryable_total
- payment_duplicate_webhook_total
- payment_audit_trail_total

## 7-5P.10.3 Audit trail modeli

Audit trail kayıtları tenant bazlıdır.

Alanlar:
- tenant_id
- attempt_id
- provider_code
- operation
- status
- event_type
- error_code
- correlation_id
- idempotency_key
- message
- occurred_at

Bu kayıtlar ileride:
- Ops Console
- incident ekranı
- payment reconciliation
- müşteri destek incelemesi
- provider dispute araştırması
için temel olur.

## 7-5P.10.4 Runtime sorumlulukları

PaymentObservabilityRuntime şu işlemleri yapar:

- payment operation result kaydeder
- webhook once result kaydeder
- retry decision kaydeder
- metric snapshot üretir
- tenant audit trail export eder
- failed payment kayıtlarını metric ve audit trail içine yazar

## 7-5P.10.5 Test ve audit kuralı

Bu adımda final durum sadece gerçek test ve audit sayaçlarından türetilir.

Elle yazılmış final OK satırları test kanıtı sayılmaz.

Zorunlu kanıtlar:
- go test gerçek çalışmalı
- observability test isimleri raw output içinde görünmeli
- dosya/kod/config/doküman karşılıkları audit fonksiyonlarıyla kontrol edilmeli
- failed metric artmalı
- retry metric artmalı
- duplicate webhook metric artmalı
- tenant audit trail export çalışmalı
- FAIL_COUNT=0 olmadan PASS verilmemeli

## 7-5P.10.6 Kapanış koşulu

Bu adım ancak şu koşullarla PASS sayılır:
- PaymentObservabilityRuntime var
- metric model var
- operation metric recorder var
- webhook metric recorder var
- retry decision metric recorder var
- failed payment metric recorder var
- duplicate webhook metric recorder var
- tenant audit trail export var
- metric snapshot testi var
- audit trail export testi var
- go test PASS
- real implementation audit PASS
- final status sayaçlardan türetilmiş olmalı
