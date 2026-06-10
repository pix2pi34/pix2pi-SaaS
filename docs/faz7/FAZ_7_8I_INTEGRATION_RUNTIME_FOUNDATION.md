# FAZ 7-8I Integration Runtime Foundation

## Amaç

FAZ 7-8I, FAZ 7-8 Marketplace / Integration Catalog Foundation sonrasında gelen gerçek entegrasyon çalışma çekirdeğidir.

Bu modül provider özel entegrasyon yazmaz. Bunun yerine Paraşüt, Logo, Mikro, Zirve, ETA, e-Belge, marketplace, payment provider ve benzeri ileriki entegrasyonların üzerinde koşacağı standart runtime temelini kurar.

## Kapsam

### 7-8I.1 Tenant Integration Install / Enablement Runtime

- Tenant bazlı entegrasyon kurulum modeli
- Provider / app / capability doğrulama
- Production real integration gate kapalı varsayılanı
- Tenant, requester ve correlation zorunluluğu
- Audit karar alanı

### 7-8I.2 Connector Runtime Foundation / Adapter SDK

- ConnectorAdapter interface
- Adapter registry
- Operation request / result sözleşmesi
- Tenant, provider, app, operation, idempotency ve correlation guard
- Provider bağımsız execute köprüsü

### 7-8I.3 Webhook / External Event Intake Foundation

- External event intake modeli
- HMAC SHA256 signature doğrulama
- Timestamp skew guard
- Tenant / provider / event id / correlation zorunluluğu
- Raw payload zorunluluğu

### 7-8I.4 Connector Operation Audit / Observability

- Connector audit event modeli
- Operation metric snapshot
- Webhook event metric
- Duplicate webhook metric
- Tenant bazlı audit trail okuma

### 7-8I.5 Connector Failure / Retry / DLQ Readiness

- Retry policy
- Retryable / non-retryable / poison failure sınıfları
- Max attempt guard
- DLQ message modeli
- Tenant-safe failure record

### 7-8I.6 Connector Final Closure / Provider Module Handoff Gate

- Runtime code readiness gate
- Config readiness gate
- Docs readiness gate
- Tests readiness gate
- Real implementation audit gate
- Real payment / real provider production gate kapalı kontrolü
- Provider specific module handoff kararı

## Bu modülün bilinçli sınırı

Bu modül gerçek provider bağlantısı açmaz.

Gerçek provider entegrasyonları ayrı modüllerde yapılacaktır:

- Paraşüt connector module
- Logo connector module
- Mikro connector module
- Zirve connector module
- ETA connector module
- e-Belge connector module
- Marketplace connector modules
- Payment provider specific modules

## Final kapanış şartı

FAZ 7-8I final kapanışı ancak şu kontroller geçtiğinde PASS olur:

- Go testleri PASS
- Runtime kodları mevcut
- Config artifact mevcut
- Dokümantasyon mevcut
- Webhook intake foundation mevcut
- Adapter SDK mevcut
- Retry / DLQ foundation mevcut
- Observability / audit foundation mevcut
- Provider module handoff gate mevcut
- Final durum test ve audit sayaçlarından türetilmiş olur
