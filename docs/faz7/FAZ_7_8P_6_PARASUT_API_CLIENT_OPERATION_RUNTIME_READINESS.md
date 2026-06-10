# FAZ 7-8P.6 Paraşüt API Client / Operation Runtime Dry-Run Readiness

## Amaç

FAZ 7-8P.6, Paraşüt access_token_ref hazır olduktan sonra çalışacak API client ve operation runtime katmanını dry-run/readiness seviyesinde kurar.

Bu modül gerçek Paraşüt API çağrısı yapmaz. Access token plaintext çözmez. Provider endpointlerine canlı HTTP request göndermez. Ama API client request contract, operation request builder, dry-run response, rate limit / timeout / retry bridge ve operation audit bridge katmanını hazırlar.

## Akış

1. Runtime access_token_ref alır.
2. Tenant-safe secret_ref guard çalışır.
3. Paraşüt API client contract hazırlanır.
4. Operation request oluşturulur.
5. Endpoint contract doğrulanır.
6. Real API gate kapalı olduğu için canlı HTTP çağrısı yapılmaz.
7. Dry-run provider response üretilir.
8. Rate limit / timeout / retry bridge kontrol edilir.
9. Operation audit event yazılır.
10. Real provider API kapalı kalır.

## Kapsam

### 7-8P.6.1 API Client Contract

- Tenant ID zorunlu
- App key zorunlu
- Access token ref zorunlu
- Correlation ID zorunlu
- Requested by zorunlu
- Tenant-safe access_token_ref guard
- Real API enabled gate kapalı
- Provider live module guard

### 7-8P.6.2 Operation Request Builder

- PULL_INVOICE request
- PUSH_INVOICE request
- SYNC_CUSTOMER request
- SYNC_PRODUCT request
- VERIFY_WEBHOOK request
- Idempotency key zorunlu
- Payload zorunluluğu
- Endpoint contract bridge

### 7-8P.6.3 Dry-Run Provider Response

- Gerçek Paraşüt API çağrısı yok
- Simulated provider object id
- Simulated HTTP status
- Operation result contract
- Provider transaction id
- Plaintext token kullanılmaz

### 7-8P.6.4 Rate Limit / Timeout / Retry Bridge

- Endpoint timeout policy bridge
- Rate limit policy bridge
- RetryPolicy bridge
- Provider timeout retryable
- Rate limit retryable
- Unknown error DLQ mapping

### 7-8P.6.5 Operation Audit / Observability Bridge

- Connector audit event
- Tenant audit trail
- Operation metrics
- Failed operation metrics
- Correlation ID trace
- Provider transaction trace

### 7-8P.6.6 Final Closure

- Docs readiness
- Config readiness
- Code readiness
- Tests readiness
- Real implementation audit readiness
- API client dry-run readiness
- Real provider API remains closed

## Bilinçli sınır

Bu modül şunları yapmaz:

- Gerçek Paraşüt API çağrısı yapmaz
- Gerçek HTTP client açmaz
- Access token plaintext çözmez
- Production token resolver kullanmaz
- Gerçek fatura/müşteri/ürün çekmez
- Gerçek fatura göndermez

Bu adım canlı API client öncesi dry-run/readiness katmanıdır.

## Final kapanış şartı

FAZ 7-8P.6 ancak aşağıdaki kontroller geçtiğinde PASS olur:

- Go testleri PASS
- API client contract mevcut
- Operation request builder mevcut
- Dry-run provider response mevcut
- Rate limit / timeout / retry bridge mevcut
- Operation audit / observability bridge mevcut
- Real implementation audit PASS
- Real provider API gate kapalı
