# FAZ 7-8P.8 Paraşüt Sync Worker / Job Orchestration Dry-Run Readiness

## Amaç

FAZ 7-8P.8, Paraşüt entegrasyonu için sync worker / job orchestration dry-run katmanını kurar.

Bu modül gerçek Paraşüt API çağrısı yapmaz. Gerçek ERP write yapmaz. Ama tenant entegrasyon enablement, token lifecycle check, API operation dry-run, data mapping, ERP write dry-run, retry/DLQ kararı ve audit/observability zincirini tek worker orchestration contract altında bağlar.

## Akış

1. Sync job schedule contract hazırlanır.
2. Tenant integration enabled check yapılır.
3. Token lifecycle kontrol edilir.
4. Access token aktifse API operation dry-run çalışır.
5. Paraşüt source data mapping çalışır.
6. ERP write dry-run contract oluşturulur.
7. Mapping/API audit event yazılır.
8. Failure durumunda retry/DLQ kararı üretilir.
9. Real provider API ve real ERP write kapalı kalır.

## Kapsam

### 7-8P.8.1 Sync Job Schedule / Worker Context

- Job key contract
- Tenant ID zorunlu
- App key zorunlu
- Provider key zorunlu
- Operation zorunlu
- Requested by zorunlu
- Correlation ID zorunlu
- Dry-run only
- Schedule interval contract

### 7-8P.8.2 Tenant Integration Enabled / Token Lifecycle Gate

- Tenant integration enabled check
- Disabled integration blocked
- ACTIVE token devam eder
- REFRESH_REQUIRED token API operation öncesi durur
- EXPIRED token API operation öncesi durur
- REVOKED token blocked
- Real token refresh kapalı

### 7-8P.8.3 API Operation + Mapping Orchestration

- API client contract bridge
- API operation request builder bridge
- API dry-run response bridge
- Customer mapping bridge
- Product mapping bridge
- Invoice mapping bridge
- Real provider API kapalı

### 7-8P.8.4 ERP Write Dry-Run Orchestration

- ERP write dry-run bridge
- Real ERP write kapalı
- Tenant-safe write contract
- Mapping audit event
- API operation audit event

### 7-8P.8.5 Retry / DLQ / Failure Orchestration

- Timeout retryable
- Rate limit retryable
- Validation non-retryable
- Unknown provider error DLQ
- Retry decision bridge
- DLQ readiness marker

### 7-8P.8.6 Final Closure

- Docs readiness
- Config readiness
- Code readiness
- Tests readiness
- Real implementation audit readiness
- Sync worker dry-run readiness
- Real provider API remains closed
- Real ERP write remains closed

## Bilinçli sınır

Bu modül şunları yapmaz:

- Gerçek scheduler/cron başlatmaz
- Gerçek queue consumer çalıştırmaz
- Gerçek Paraşüt API çağrısı yapmaz
- Gerçek ERP DB write yapmaz
- Production sync job açmaz
- Real token refresh yapmaz

Bu adım canlı sync worker öncesi orchestration dry-run/readiness katmanıdır.

## Final kapanış şartı

FAZ 7-8P.8 ancak aşağıdaki kontroller geçtiğinde PASS olur:

- Go testleri PASS
- Sync job schedule contract mevcut
- Tenant integration enabled check mevcut
- Token lifecycle gate mevcut
- API operation dry-run orchestration mevcut
- Data mapping orchestration mevcut
- ERP write dry-run orchestration mevcut
- Retry/DLQ orchestration mevcut
- Audit/observability bridge mevcut
- Real implementation audit PASS
- Real provider API gate kapalı
- Real ERP write gate kapalı
