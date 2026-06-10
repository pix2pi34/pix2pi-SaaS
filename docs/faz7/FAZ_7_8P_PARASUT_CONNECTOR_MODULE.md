# FAZ 7-8P Paraşüt Connector Module Foundation

## Amaç

FAZ 7-8P, FAZ 7-8I Integration Runtime Foundation üstüne kurulan ilk provider-specific connector modülüdür.

Bu modül gerçek Paraşüt API production bağlantısı açmaz. Önce Paraşüt entegrasyonu için güvenli, test edilebilir, tenant-aware ve audit-ready adapter temelini kurar.

## Kapsam

### 7-8P.1 Paraşüt Connector Config / Provider Identity

- Provider key standardı: parasut
- Tenant bazlı connector config
- Environment modeli: SIMULATION / SANDBOX / PRODUCTION
- Production gate kapalı varsayılanı
- Webhook secret zorunluluğu
- Capability listesi

### 7-8P.2 Paraşüt Adapter SDK Bridge

- 7-8I ConnectorAdapter interface uyumu
- AdapterSDK registration uyumu
- Provider independent OperationRequest / OperationResult köprüsü
- PULL_INVOICE operation simulation
- PUSH_INVOICE operation simulation
- SYNC_CUSTOMER operation simulation
- SYNC_PRODUCT operation simulation
- VERIFY_WEBHOOK operation simulation

### 7-8P.3 Paraşüt Data Mapping Foundation

- Invoice draft mapping modeli
- Tenant / customer / invoice no guard
- Amount minor unit guard
- Currency guard
- Provider payload hazırlık noktası

### 7-8P.4 Paraşüt Webhook Bridge

- 7-8I webhook intake runtime ile bridge
- HMAC SHA256 signature builder kullanımı
- Timestamp skew guard kullanımı
- Raw payload guard kullanımı
- Provider key guard

### 7-8P.5 Paraşüt Failure / Retry / DLQ Bridge

- Retryable provider timeout modeli
- Max attempt sonrası DLQ kararı
- Poison webhook/message DLQ kararı
- Tenant-safe failure record

### 7-8P.6 Paraşüt Connector Final Closure / Provider Handoff Gate

- Runtime code readiness
- Config readiness
- Docs readiness
- Tests readiness
- Real implementation audit readiness
- Production live gate closed
- Provider connector module foundation ready

## Bilinçli sınır

Bu modül aşağıdakileri yapmaz:

- Gerçek Paraşüt OAuth bağlantısı açmaz
- Gerçek Paraşüt API çağrısı yapmaz
- Gerçek müşteri verisi çekmez
- Gerçek fatura göndermez
- Production credential saklamaz

Bunlar provider-specific live integration aşamasında; hukuk, finans, KVKK, secret management, rate limit, rollback ve provider sözleşme onaylarından sonra açılacaktır.

## Final kapanış şartı

FAZ 7-8P final kapanışı şu kontroller geçtiğinde PASS olur:

- Go testleri PASS
- Paraşüt config artifact mevcut
- Paraşüt connector code mevcut
- Adapter SDK bridge mevcut
- Mapping foundation mevcut
- Webhook bridge mevcut
- Retry / DLQ bridge mevcut
- Provider module gate mevcut
- Real implementation audit PASS
- Production real provider gate kapalı
