# FAZ 7-8L.8 — Logo Admin / Ops / Manual Review

## Amaç

Bu adım, Logo connector için admin/ops görünümü, manual review queue, assign/resolve/reject aksiyonları ve tenant-safe review sınırlarını kurar.

Bu adım gerçek Logo API çağrısı yapmaz.
Bu adım gerçek Logo dosya teslimi yapmaz.
Bu adım gerçek ERP write yapmaz.
Bu adım sadece dry-run ops runtime modeli ve review state machine kurar.

## Bağımlılık

FAZ 7-8L.1 Logo Connector Foundation / Provider Identity tamamlanmış olmalıdır.
FAZ 7-8L.2 Logo Live Contract / API-File Contract Readiness tamamlanmış olmalıdır.
FAZ 7-8L.3 Logo Credential / Secret Reference Readiness tamamlanmış olmalıdır.
FAZ 7-8L.4 Logo Export Mapping Contract tamamlanmış olmalıdır.
FAZ 7-8L.5 Logo File Generation Dry-Run tamamlanmış olmalıdır.
FAZ 7-8L.6 Logo Import Package / Delivery Contract tamamlanmış olmalıdır.
FAZ 7-8L.7 Logo Validation / Error Mapping / Retry-DLQ tamamlanmış olmalıdır.

Beklenen dosyalar:

internal/platform/integrations/providers/logo/logo_foundation.go
internal/platform/integrations/providers/logo/logo_live_contract.go
internal/platform/integrations/providers/logo/logo_credential.go
internal/platform/integrations/providers/logo/logo_export_mapping.go
internal/platform/integrations/providers/logo/logo_file_generation.go
internal/platform/integrations/providers/logo/logo_import_delivery.go
internal/platform/integrations/providers/logo/logo_validation_retry_dlq.go

## Dizin Standardı

Logo provider-specific dosyaları şu dizinde tutulur:

internal/platform/integrations/providers/logo/

Bu adımın dosyaları:

internal/platform/integrations/providers/logo/logo_admin_ops.go
internal/platform/integrations/providers/logo/logo_admin_ops_test.go

## Kapsam

- Logo admin / ops contract
- Manual review queue model
- Manual review item model
- Review status state machine
- Assign action
- Resolve action
- Reject action
- Tenant-safe list/read/update boundary
- Cross-tenant review protection
- Ops audit fields
- No external call guard
- No real file delivery guard
- No ERP write guard
- Config artifact
- Go runtime model
- Go unit tests
- Real implementation audit

## Modül Kimliği

- Module: FAZ_7_8L
- Step: FAZ_7_8L.8
- Provider code: LOGO
- Provider name: Logo
- Connector code: logo_connector
- Connector family: accounting_export_connector
- Runtime mode: DRY_RUN
- Admin ops mode: ADMIN_OPS_MANUAL_REVIEW_DRY_RUN_ONLY
- Target system: LOGO_ACCOUNTING_IMPORT_DRY_RUN

## Manual Review Status Set

- OPEN
- ASSIGNED
- RESOLVED
- REJECTED

## Manual Review Reason Set

- CHECKSUM_MISMATCH
- UNKNOWN_PROVIDER_ERROR
- TENANT_BOUNDARY_VIOLATION
- VALIDATION_DLQ
- RETRY_LIMIT_EXCEEDED

## Admin / Ops Actions

- CREATE_LOGO_MANUAL_REVIEW_ITEM
- LIST_LOGO_MANUAL_REVIEWS
- READ_LOGO_MANUAL_REVIEW
- ASSIGN_LOGO_MANUAL_REVIEW
- RESOLVE_LOGO_MANUAL_REVIEW
- REJECT_LOGO_MANUAL_REVIEW

## Tenant-Safe Review Boundary

Manual review item tenant_id ile oluşturulur.
List/read/update işlemleri tenant_id filtresi olmadan yapılamaz.
Farklı tenant review kaydına erişim reddedilir.

## Kapalı Tutulan Gerçek İşlemler

- LOGO_REAL_PROVIDER_API_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE
- LOGO_REAL_FILE_DELIVERY_STATUS=CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE
- LOGO_REAL_ERP_WRITE_STATUS=CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE
- LOGO_ADMIN_OPS_STATUS=READY
- LOGO_MANUAL_REVIEW_QUEUE_STATUS=READY

## Admin Ops Operation Set

- DECLARE_LOGO_ADMIN_OPS_CONTRACT
- CREATE_LOGO_MANUAL_REVIEW_ITEM
- LIST_LOGO_MANUAL_REVIEWS
- READ_LOGO_MANUAL_REVIEW
- ASSIGN_LOGO_MANUAL_REVIEW
- RESOLVE_LOGO_MANUAL_REVIEW
- REJECT_LOGO_MANUAL_REVIEW
- VALIDATE_LOGO_TENANT_REVIEW_BOUNDARY
- PREPARE_LOGO_E2E_DRY_RUN_HANDOFF

## Güvenlik Kararı

Bu adım admin/ops ve manual review state machine kurar.
Bu adım gerçek Logo API çağrısı yapmaz.
Bu adım gerçek Logo dosya teslimi yapmaz.
Bu adım Pix2pi ERP tarafına gerçek kayıt yazmaz.

## Bir Sonraki Adım

FAZ 7-8L.9 — Logo E2E Dry-Run Flow
