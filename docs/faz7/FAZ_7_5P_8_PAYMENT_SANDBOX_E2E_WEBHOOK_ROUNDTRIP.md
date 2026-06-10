# FAZ 7-5P.8 — Payment Provider Sandbox E2E Flow / Webhook Roundtrip

## 7-5P.8.1 Amaç

Bu adım, Payment Provider Adapter modülünde sandbox uçtan uca ödeme akışını doğrular.

Bu seviyede hedef:
- PaymentService Authorize akışını çalıştırmak
- PaymentAttempt repository persistence davranışını doğrulamak
- SimulationProvider webhook delivery üretmek
- WebhookIntake VerifyAndRecord ile HMAC signature doğrulamak
- Webhook sonucunda attempt audit event history güncellendiğini doğrulamak
- provider transaction id sürekliliğini doğrulamak
- gerçek ödeme ağına çıkmadan güvenli sandbox roundtrip kurmak

## 7-5P.8.2 E2E akış

Roundtrip sırası:

1. PaymentService.Authorize çağrılır
2. PaymentAttempt AUTHORIZED olur
3. Repository içine kaydedilir
4. SimulationPaymentProviderAdapter webhook delivery üretir
5. Webhook payload HMAC SHA256 ile imzalanır
6. PaymentWebhookIntakeRuntime VerifyAndRecord çağrılır
7. Signature ve timestamp doğrulanır
8. PaymentService.VerifyWebhook çalışır
9. Attempt status değişmeden audit event eklenir
10. Repository Update ile event history persist edilir

## 7-5P.8.3 Güvenlik kuralları

Bu E2E runtime gerçek ödeme yapmaz.

Kurallar:
- PRODUCTION kullanılmaz
- real_payment_enabled false kalır
- webhook signature zorunludur
- raw payload zorunludur
- provider code eşleşmelidir
- tenant/attempt/correlation zorunludur
- FAIL_COUNT=0 olmadan PASS verilmez

## 7-5P.8.4 Test ve audit kuralı

Bu adımda final durum sadece gerçek test ve audit sayaçlarından türetilir.

Elle yazılmış final OK satırları test kanıtı sayılmaz.

Zorunlu kanıtlar:
- go test gerçek çalışmalı
- E2E test isimleri raw output içinde görünmeli
- dosya/kod/config/doküman karşılıkları audit fonksiyonlarıyla kontrol edilmeli
- roundtrip testinde attempt event sayısı artmalı
- webhook signature doğrulanmalı
- repository içinde final attempt tekrar okunabilmeli

## 7-5P.8.5 Kapanış koşulu

Bu adım ancak şu koşullarla PASS sayılır:
- PaymentSandboxE2ERuntime var
- Authorize to webhook roundtrip function var
- simulation provider webhook delivery bridge var
- webhook intake verify bridge var
- repository final state verification var
- audit event count verification var
- invalid dependency testi var
- invalid event type testi var
- go test PASS
- real implementation audit PASS
- final status sayaçlardan türetilmiş olmalı
