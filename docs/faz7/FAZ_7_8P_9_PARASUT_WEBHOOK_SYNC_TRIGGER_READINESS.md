# FAZ 7-8P.9 Paraşüt Webhook Event → Sync Trigger Readiness

## Amaç

FAZ 7-8P.9, Paraşüt webhook event geldiğinde bu eventin güvenli şekilde doğrulanmasını, event type mapping yapılmasını, idempotency guard ile duplicate eventlerin engellenmesini ve sync worker dry-run orchestration zincirinin tetiklenmesini hazırlar.

Bu modül gerçek Paraşüt webhook endpoint yayını yapmaz. Gerçek Paraşüt API çağrısı yapmaz. Gerçek ERP write yapmaz. Webhook intake, signature contract, tenant/provider guard, event mapping, idempotency, sync worker trigger, retry/DLQ ve audit/observability köprüsünü dry-run/readiness seviyesinde kurar.

## Akış

1. Paraşüt webhook event envelope gelir.
2. Tenant/provider/app guard çalışır.
3. Signature dry-run verification yapılır.
4. Timestamp skew guard çalışır.
5. Event type mapping yapılır.
6. Idempotency key üretilir.
7. Duplicate webhook event engellenir.
8. Sync job schedule oluşturulur.
9. Sync worker dry-run tetiklenir.
10. API dry-run + mapping + ERP write dry-run zinciri çalışır.
11. Audit/observability eventleri yazılır.
12. Failure durumunda retry/DLQ kararı üretilir.
13. Real provider API ve real ERP write kapalı kalır.

## Kapsam

### 7-8P.9.1 Webhook Intake / Signature Contract

- Tenant ID zorunlu
- Provider key zorunlu
- App key zorunlu
- Event ID zorunlu
- Event type zorunlu
- Raw payload zorunlu
- Webhook secret ref zorunlu
- Signature zorunlu
- Timestamp zorunlu
- Timestamp skew guard
- Real webhook endpoint kapalı

### 7-8P.9.2 Event Type Mapping Contract

- customer.created / customer.updated → SYNC_CUSTOMER
- product.created / product.updated → SYNC_PRODUCT
- sales_invoice.created / sales_invoice.updated → PULL_INVOICE
- Unsupported event type rejected
- Object type mapping
- Operation mapping

### 7-8P.9.3 Idempotency / Duplicate Guard

- Tenant/provider/event_id idempotency key
- First event accepted
- Duplicate event ignored safely
- Cross-tenant event separation
- Duplicate event audit marker

### 7-8P.9.4 Sync Worker Trigger Bridge

- Sync job schedule builder
- Tenant integration enabled gate
- Token lifecycle gate
- Source envelope bridge
- ExecuteParasutSyncWorkerDryRun bridge
- Real API closed
- Real ERP write closed

### 7-8P.9.5 Retry / DLQ / Audit Orchestration

- Timeout retryable
- Rate limit retryable
- Validation non-retryable
- Unknown provider error DLQ
- Webhook trigger audit event
- Correlation trace
- Provider event trace

### 7-8P.9.6 Final Closure

- Docs readiness
- Config readiness
- Code readiness
- Tests readiness
- Real implementation audit readiness
- Webhook sync trigger dry-run readiness
- Real webhook endpoint remains closed
- Real provider API remains closed
- Real ERP write remains closed

## Bilinçli sınır

Bu modül şunları yapmaz:

- Gerçek public webhook endpoint açmaz
- Gerçek Paraşüt webhook çağrısı almaz
- Gerçek provider secret resolver açmaz
- Gerçek Paraşüt API çağrısı yapmaz
- Gerçek ERP DB write yapmaz
- Production queue trigger çalıştırmaz

Bu adım canlı webhook/sync worker öncesi trigger readiness katmanıdır.

## Final kapanış şartı

FAZ 7-8P.9 ancak aşağıdaki kontroller geçtiğinde PASS olur:

- Go testleri PASS
- Webhook intake/signature contract mevcut
- Event type mapping mevcut
- Idempotency/duplicate guard mevcut
- Sync worker trigger bridge mevcut
- Retry/DLQ orchestration mevcut
- Audit/observability bridge mevcut
- Real implementation audit PASS
- Real webhook endpoint kapalı
- Real provider API kapalı
- Real ERP write kapalı
