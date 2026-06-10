# FAZ 7-5P.6 — Payment Webhook Intake / Verification Runtime

## 7-5P.6.1 Amaç

Bu adım, Payment Provider Adapter modülünde webhook intake ve verification runtime sınırını kurar.

Bu seviyede hedef:
- provider webhook signature header standardı oluşturmak
- HMAC SHA256 imza doğrulama eklemek
- timestamp skew guard eklemek
- raw webhook payload zorunluluğu koymak
- tenant_id / attempt_id / provider_code doğrulamak
- PaymentService.VerifyWebhook üzerinden audit event yazdırmak
- webhook doğrulama sonucunu payment attempt history içinde izlenebilir hale getirmek

## 7-5P.6.2 Webhook güvenlik modeli

Webhook kabul edilmeden önce şu guardlar çalışır:

- tenant_id zorunlu
- attempt_id zorunlu
- provider_code zorunlu
- correlation_id zorunlu
- raw payload zorunlu
- signature header zorunlu
- timestamp zorunlu
- timestamp tolerans içinde olmalı
- HMAC SHA256 imza doğru olmalı
- provider_code runtime provider ile eşleşmeli

## 7-5P.6.3 Signature standardı

Signature header formatı:
t=<unix_timestamp>,v1=<hex_hmac_sha256>

İmzalanan veri:
<unix_timestamp>.<raw_payload>

Bu model ileride gerçek provider adaptörlerine uyarlanabilir.

## 7-5P.6.4 PaymentService köprüsü

Webhook doğrulama başarılı olursa runtime:

1. PaymentService.VerifyWebhook çağırır
2. OperationWebhookVerify contract validation çalışır
3. Attempt status değişmeden audit event eklenir
4. Repository Update ile event history persist edilir

## 7-5P.6.5 Test ve audit kuralı

Bu adımda final durum sadece gerçek test ve audit sayaçlarından türetilir.

Elle yazılmış final OK satırları test kanıtı sayılmaz.

Zorunlu kanıtlar:
- go test gerçek çalışmalı
- webhook test isimleri raw output içinde görünmeli
- dosya/kod/config/doküman karşılıkları audit fonksiyonlarıyla kontrol edilmeli
- FAIL_COUNT=0 olmadan PASS verilmemeli

## 7-5P.6.6 Kapanış koşulu

Bu adım ancak şu koşullarla PASS sayılır:
- PaymentWebhookIntakeRuntime var
- HMAC SHA256 signature verification var
- timestamp skew guard var
- tenant/attempt/provider/correlation guard var
- raw payload required guard var
- invalid signature testi var
- stale timestamp testi var
- provider mismatch testi var
- PaymentService VerifyWebhook bridge testi var
- webhook audit event persistence testi var
- go test PASS
- real implementation audit PASS
- final status sayaçlardan türetilmiş olmalı
