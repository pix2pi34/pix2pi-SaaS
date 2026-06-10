# FAZ 7-5P.5 — Payment Service Orchestration / Use Case Layer

## 7-5P.5.1 Amaç

Bu adım, Payment Provider Adapter modülünde daha önce kurulan parçaları tek use-case servisinde birleştirir.

Birleşen parçalar:
- PaymentProviderAdapter
- ProviderCapabilityMatrix
- OperationContractDecision
- PaymentAttempt lifecycle
- PaymentAttemptRepository persistence

Bu katman gerçek provider entegrasyonu değildir. Bu katman provider entegrasyonlarının güvenli şekilde bağlanacağı orchestration/use-case sınırıdır.

## 7-5P.5.2 Orchestration sorumlulukları

PaymentService şu use-case operasyonlarını yönetir:

- Authorize
- Capture
- Refund
- Void
- VerifyWebhook

Her operasyon:
- tenant context ister
- provider contract validation yapar
- payment attempt lifecycle uygular
- repository persistence yapar
- idempotency replay davranışını yönetir
- audit event history üretir

## 7-5P.5.3 Authorize akışı

Authorize akışı:
1. tenant + idempotency ile eski attempt aranır
2. varsa idempotency replay olarak döner
3. yoksa PaymentAttempt oluşturulur
4. ProviderCapabilityMatrix contract decision üretir
5. PaymentAttempt lifecycle uygulanır
6. Repository Save yapılır

## 7-5P.5.4 Capture / Refund / Void akışı

Capture, Refund ve Void akışı:
1. tenant + attempt_id ile mevcut attempt yüklenir
2. provider transaction id kontrol edilir
3. operation contract validation yapılır
4. state transition uygulanır
5. Repository Update yapılır

## 7-5P.5.5 Webhook verify akışı

Webhook verify akışı:
1. attempt yüklenir
2. webhook signature ve raw payload kontrol edilir
3. status değiştirmeden audit event eklenir
4. Repository Update yapılır

## 7-5P.5.6 Idempotency kuralı

Authorize tarafında aynı tenant içinde aynı idempotency_key ile tekrar istek gelirse:
- yeni attempt açılmaz
- mevcut attempt replay olarak döner
- duplicate ödeme riski azalır

## 7-5P.5.7 Test ve audit kuralı

Bu adımda final durum sadece gerçek test ve audit sayaçlarından türetilir.

Elle yazılmış final OK satırları test kanıtı sayılmaz.

Zorunlu kanıtlar:
- go test gerçek çalışmalı
- test isimleri raw output içinde görünmeli
- dosya/kod/config/doküman karşılıkları audit fonksiyonlarıyla kontrol edilmeli
- FAIL_COUNT=0 olmadan PASS verilmemeli

## 7-5P.5.8 Kapanış koşulu

Bu adım ancak şu koşullarla PASS sayılır:
- PaymentService var
- provider adapter binding var
- capability matrix binding var
- repository binding var
- Authorize / Capture / Refund / Void / VerifyWebhook use-case fonksiyonları var
- idempotency replay testi var
- lifecycle + persistence testleri var
- go test PASS
- real implementation audit PASS
- final status sayaçlardan türetilmiş olmalı
