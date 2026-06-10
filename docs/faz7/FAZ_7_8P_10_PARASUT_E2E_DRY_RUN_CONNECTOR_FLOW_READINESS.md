# FAZ 7-8P.10 Paraşüt End-to-End Dry-Run Scenario / Full Connector Flow Readiness

## Amaç

FAZ 7-8P.10, Paraşüt connector ailesinde daha önce kurulan tüm runtime parçalarını tek uçtan uca dry-run senaryoda bağlar.

Bu modül gerçek Paraşüt API çağrısı yapmaz. Gerçek webhook endpoint açmaz. Gerçek ERP write yapmaz. Ama credential/secret-ref, OAuth, token exchange, API client, data mapping, sync worker, webhook trigger, audit, retry ve DLQ zincirinin birlikte çalıştığını doğrular.

## Uçtan uca akış

1. Credential / secret-ref runtime hazırlanır.
2. OAuth authorization URL üretilir.
3. OAuth callback dry-run accepted / token exchange blocked status üretir.
4. Token exchange dry-run contract oluşturulur.
5. Simulated token response ile access_token_ref ve refresh_token_ref üretilir.
6. API client contract oluşturulur.
7. API operation dry-run çalışır.
8. Paraşüt source data ERP sync record'a map edilir.
9. ERP write dry-run contract oluşturulur.
10. Sync worker dry-run çalışır.
11. Webhook envelope doğrulanır.
12. Webhook event type sync operation'a map edilir.
13. Idempotency duplicate guard çalışır.
14. Webhook sync trigger worker dry-run zincirini tetikler.
15. Audit / observability eventleri yazılır.
16. Retry / DLQ failure decision üretilir.
17. Real provider API, real webhook endpoint, real ERP write ve real queue trigger kapalı kalır.

## Kapsam

### 7-8P.10.1 Credential + OAuth E2E Bridge

- Client secret ref oluşturma
- OAuth state üretme
- Authorization URL dry-run contract
- Callback intake contract
- Real token exchange kapalı

### 7-8P.10.2 Token Exchange + Token Lifecycle E2E Bridge

- Token exchange request contract
- Simulated token response
- access_token_ref oluşturma
- refresh_token_ref oluşturma
- Token lifecycle active status
- Real token refresh kapalı

### 7-8P.10.3 API Client + Data Mapping + ERP Write E2E Bridge

- API client contract
- API operation request
- API dry-run response
- Customer/product/invoice mapping bridge
- ERP write dry-run bridge
- Real provider API kapalı
- Real ERP write kapalı

### 7-8P.10.4 Sync Worker + Webhook Trigger E2E Bridge

- Sync worker schedule
- Tenant integration enabled gate
- Token lifecycle gate
- Webhook signature verification
- Event type mapping
- Idempotency duplicate guard
- Worker trigger dry-run
- Real queue trigger kapalı

### 7-8P.10.5 Audit / Retry / DLQ E2E Bridge

- API operation audit
- Mapping audit
- Webhook trigger audit
- Correlation trace
- Provider transaction / event trace
- Timeout retryable
- Rate limit retryable
- Unknown provider error DLQ

### 7-8P.10.6 Final Closure

- Docs readiness
- Config readiness
- Code readiness
- Tests readiness
- Real implementation audit readiness
- Full connector dry-run readiness
- Real provider API remains closed
- Real webhook endpoint remains closed
- Real ERP write remains closed

## Bilinçli sınır

Bu modül şunları yapmaz:

- Gerçek Paraşüt API çağrısı yapmaz
- Gerçek public webhook endpoint açmaz
- Gerçek credential plaintext resolver açmaz
- Gerçek ERP DB write yapmaz
- Production sync queue trigger çalıştırmaz
- Production token exchange / refresh yapmaz

Bu adım Paraşüt connector ailesinin canlıya geçmeden önceki full dry-run entegrasyon kanıtıdır.

## Final kapanış şartı

FAZ 7-8P.10 ancak aşağıdaki kontroller geçtiğinde PASS olur:

- Go testleri PASS
- Credential + OAuth bridge mevcut
- Token exchange + lifecycle bridge mevcut
- API client + mapping + ERP write bridge mevcut
- Sync worker + webhook trigger bridge mevcut
- Audit / retry / DLQ bridge mevcut
- Real implementation audit PASS
- Real provider API kapalı
- Real webhook endpoint kapalı
- Real ERP write kapalı
