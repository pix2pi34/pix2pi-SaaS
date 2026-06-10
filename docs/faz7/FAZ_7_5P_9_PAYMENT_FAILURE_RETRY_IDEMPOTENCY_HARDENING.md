# FAZ 7-5P.9 — Payment Failure / Retry / Idempotency E2E Hardening

## 7-5P.9.1 Amaç

Bu adım, Payment Provider Adapter modülünü hata, tekrar deneme ve idempotency tarafında sertleştirir.

Bu seviyede hedef:
- Authorize idempotency replay davranışını doğrulamak
- Failed authorize durumunu repository içinde audit edilebilir şekilde saklamak
- Duplicate webhook tekrarında ikinci kez audit event yazılmasını engellemek
- Retryable / non-retryable hata karar modelini kurmak
- Retry limit guard eklemek
- Webhook event count protection eklemek
- Gerçek ödeme ağına çıkmadan sandbox failure senaryolarını test etmek

## 7-5P.9.2 Failure modeli

Ödeme başarısız olduğunda attempt kaydı silinmez.

Kurallar:
- denied authorize sonucu FAILED olarak persist edilir
- failure_code saklanır
- failure_message saklanır
- audit event history korunur
- tenant ve idempotency bağı bozulmaz

## 7-5P.9.3 Idempotency replay modeli

Aynı tenant içinde aynı idempotency_key ile tekrar authorize gelirse:
- yeni attempt açılmaz
- mevcut attempt döner
- duplicate charge riski azaltılır
- replay=true olarak işaretlenir

## 7-5P.9.4 Duplicate webhook modeli

Aynı webhook dedupe key tekrar gelirse:
- ikinci kez PaymentService.VerifyWebhook çağrılmaz
- event history artmaz
- mevcut attempt okunur
- duplicate=true olarak işaretlenir

## 7-5P.9.5 Retry karar modeli

Retry kararı şu alanlardan türetilir:
- error_code
- attempt_number
- max_attempts
- retryable error code listesi

Kurallar:
- production real payment gate closed retryable değildir
- provider transaction required kontrollü retryable kabul edilebilir
- max_attempts aşılırsa retry reddedilir

## 7-5P.9.6 Test ve audit kuralı

Bu adımda final durum sadece gerçek test ve audit sayaçlarından türetilir.

Elle yazılmış final OK satırları test kanıtı sayılmaz.

Zorunlu kanıtlar:
- go test gerçek çalışmalı
- failure/retry/idempotency test isimleri raw output içinde görünmeli
- dosya/kod/config/doküman karşılıkları audit fonksiyonlarıyla kontrol edilmeli
- duplicate webhook event count artmamalı
- failed authorize repository içinde bulunmalı
- FAIL_COUNT=0 olmadan PASS verilmemeli

## 7-5P.9.7 Kapanış koşulu

Bu adım ancak şu koşullarla PASS sayılır:
- PaymentFailureRetryRuntime var
- Retry policy modeli var
- retryable/non-retryable decision modeli var
- authorize idempotency replay testi var
- failed authorize persistence testi var
- duplicate webhook dedupe testi var
- webhook event count protection testi var
- retry limit testi var
- go test PASS
- real implementation audit PASS
- final status sayaçlardan türetilmiş olmalı
