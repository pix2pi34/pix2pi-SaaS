# FAZ 7-5P.7 — Payment Provider Simulation Adapter / Sandbox Runtime

## 7-5P.7.1 Amaç

Bu adım, gerçek ödeme sağlayıcıya bağlanmadan önce güvenli simulation/sandbox provider adapter kurar.

Bu adapter gerçek para çekmez.

Bu seviyede hedef:
- SimulationPaymentProviderAdapter oluşturmak
- PaymentProviderAdapter interface ile uyumlu çalışmak
- SIMULATION ve SANDBOX modlarını desteklemek
- PRODUCTION mode kullanımını reddetmek
- authorize / capture / refund / void operasyonlarını simüle etmek
- provider transaction id üretmek
- webhook payload ve signature header üretmek
- Payment Webhook Intake runtime ile uyumlu test webhook'u oluşturmak

## 7-5P.7.2 Güvenlik kararı

Bu adapter gerçek ödeme için kullanılmaz.

Kurallar:
- PRODUCTION mode reddedilir
- real_payment_enabled=true reddedilir
- provider transaction id simülasyon olarak üretilir
- webhook signature HMAC SHA256 ile üretilir
- tenant/correlation/idempotency kontrolleri contract layer üzerinden çalışır

## 7-5P.7.3 Operasyonlar

Desteklenen simulation operasyonları:

- Authorize
- Capture
- Refund
- Void
- BuildWebhookDelivery

## 7-5P.7.4 Webhook üretimi

Simulation adapter webhook payload üretir.

Payload alanları:
- provider_code
- tenant_id
- attempt_id
- provider_transaction_id
- event_type
- occurred_at

Signature header formatı:
t=<unix_timestamp>,v1=<hex_hmac_sha256>

Bu header, 7-5P.6 Webhook Intake Runtime ile doğrulanabilir.

## 7-5P.7.5 Test ve audit kuralı

Bu adımda final durum sadece gerçek test ve audit sayaçlarından türetilir.

Elle yazılmış final OK satırları test kanıtı sayılmaz.

Zorunlu kanıtlar:
- go test gerçek çalışmalı
- simulation provider test isimleri raw output içinde görünmeli
- dosya/kod/config/doküman karşılıkları audit fonksiyonlarıyla kontrol edilmeli
- FAIL_COUNT=0 olmadan PASS verilmemeli

## 7-5P.7.6 Kapanış koşulu

Bu adım ancak şu koşullarla PASS sayılır:
- SimulationPaymentProviderAdapter var
- PaymentProviderAdapter interface implementasyonu var
- production mode deny testi var
- real payment enabled deny testi var
- authorize simulation testi var
- capture/refund/void simulation testi var
- webhook delivery + signature testi var
- contract denied behavior testi var
- go test PASS
- real implementation audit PASS
- final status sayaçlardan türetilmiş olmalı
