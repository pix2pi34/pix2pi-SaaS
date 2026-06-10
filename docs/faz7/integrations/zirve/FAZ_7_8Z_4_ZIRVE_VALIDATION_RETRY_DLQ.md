# FAZ 7-8Z.4 — Zirve Validation / Error Mapping / Retry-DLQ

## Amaç

Bu adım, Zirve dry-run connector ailesinde import delivery contract sonrası oluşabilecek doğrulama ve hata durumlarını standart karar modeline bağlar.

Bu fazda gerçek Zirve API çağrısı, gerçek dosya gönderimi, gerçek delivery channel ve gerçek ERP write açılmaz.

## Kapsam

- 7-8Z.3 import delivery contract doğrulaması
- Validation decision runtime
- Error code mapping
- Retryable / non-retryable kararları
- Max attempt sonrası DLQ kararı
- Blocker hata için DLQ kararı
- Manual review yönlendirme kararı
- Real delivery attempt için deny + DLQ + manual review kararı
- Tenant/export/delivery/correlation/validation run zorunlu alanları
- Real provider API deny guard
- Real file delivery deny guard
- Real delivery channel deny guard
- Real ERP write deny guard
- Real operator provider action deny guard

## Error Mapping

| Error Code | Karar |
|---|---|
| ZIRVE_ERR_PROVIDER_TEMPORARY | Attempt < max ise RETRY, max attempt sonrası DLQ |
| ZIRVE_ERR_PROVIDER_RATE_LIMIT | Attempt < max ise RETRY, max attempt sonrası DLQ |
| ZIRVE_ERR_SCHEMA_MISMATCH | MANUAL_REVIEW |
| ZIRVE_ERR_OBJECT_UNSUPPORTED | MANUAL_REVIEW |
| ZIRVE_ERR_PROVIDER_AUTH | MANUAL_REVIEW |
| ZIRVE_ERR_PACKAGE_MISSING | DLQ + MANUAL_REVIEW |
| ZIRVE_ERR_PACKAGE_ARTIFACT_MISSING | DLQ + MANUAL_REVIEW |
| ZIRVE_ERR_REAL_DELIVERY_ATTEMPTED | DENY + DLQ + MANUAL_REVIEW |
| ZIRVE_ERR_UNKNOWN | MANUAL_REVIEW |

## Bilinçli Kapalı Kalan Gerçek İşlemler

Aşağıdaki gerçek işlemler bu fazda açılmaz:

- Gerçek Zirve API çağrısı
- Gerçek Zirve dosya gönderimi
- Gerçek delivery channel
- Gerçek ERP write
- Gerçek operator provider action
- Gerçek external delivery attempt
- Gerçek secret value kullanımı

## Gate Durumu

- ZIRVE_VALIDATION_RETRY_DLQ_MODE=VALIDATION_RETRY_DLQ_DRY_RUN_ONLY
- ZIRVE_VALIDATION_RETRY_DLQ_STATUS=READY_DRY_RUN_ONLY
- ZIRVE_RETRY_POLICY=MAX_ATTEMPT_THEN_DLQ
- ZIRVE_DLQ_POLICY=DLQ_FOR_EXHAUSTED_RETRY_OR_BLOCKER
- ZIRVE_MANUAL_REVIEW_POLICY=MANUAL_REVIEW_FOR_BUSINESS_OR_SCHEMA_FAILURE
- ZIRVE_REAL_PROVIDER_API_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE
- ZIRVE_REAL_FILE_DELIVERY_STATUS=CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE
- ZIRVE_REAL_DELIVERY_CHANNEL_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE
- ZIRVE_REAL_ERP_WRITE_STATUS=CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE
- ZIRVE_REAL_OPERATOR_PROVIDER_ACTION_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE

## Dosyalar

- Runtime: `internal/platform/integrations/providers/zirve/zirve_validation_retry_dlq.go`
- Test: `internal/platform/integrations/providers/zirve/zirve_validation_retry_dlq_test.go`
- Config: `configs/faz7/integrations/zirve_validation_retry_dlq.json`
- Audit: `scripts/faz7/audit_faz_7_8z_4_zirve_validation_retry_dlq.sh`
- Evidence: `docs/faz7/evidence/FAZ_7_8Z_4_ZIRVE_VALIDATION_RETRY_DLQ_REAL_IMPLEMENTATION_AUDIT.md`

## Sonraki Mantıklı Adım

FAZ 7-8Z.5 — Zirve Admin / Ops / Manual Review.
