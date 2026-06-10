# FAZ 7-8L.3 — Logo Credential / Secret Reference Readiness

## Amaç

Bu adım, Logo Connector için gerçek credential değerlerini sisteme yazmadan secret reference ve credential vault sözleşmesini kurar.

Bu adımda gerçek Logo API key, username, password, token, certificate veya secret value yazılmaz.
Bu adımda gerçek Logo bağlantısı açılmaz.
Bu adımda gerçek dosya gönderimi yapılmaz.
Bu adımda gerçek ERP write yapılmaz.

## Bağımlılık

FAZ 7-8L.1 Logo Connector Foundation / Provider Identity tamamlanmış olmalıdır.
FAZ 7-8L.2 Logo Live Contract / API-File Contract Readiness tamamlanmış olmalıdır.

Beklenen dosyalar:

internal/platform/integrations/providers/logo/logo_foundation.go
internal/platform/integrations/providers/logo/logo_live_contract.go

## Dizin Standardı

Logo provider-specific dosyaları şu dizinde tutulur:

internal/platform/integrations/providers/logo/

Bu adımın dosyaları:

internal/platform/integrations/providers/logo/logo_credential.go
internal/platform/integrations/providers/logo/logo_credential_test.go

## Kapsam

- Logo credential profile
- Secret reference modeli
- Tenant-safe credential boundary
- Vault provider contract
- Credential usage policy
- Credential rotation readiness
- Credential audit readiness
- No raw secret guard
- Production/live provider kapısı kapalı
- Config artifact
- Go runtime model
- Go unit tests
- Real implementation audit

## Modül Kimliği

- Module: FAZ_7_8L
- Step: FAZ_7_8L.3
- Provider code: LOGO
- Provider name: Logo
- Connector code: logo_connector
- Connector family: accounting_export_connector
- Runtime mode: DRY_RUN
- Credential mode: SECRET_REFERENCE_ONLY

## Credential Güvenlik Kararı

Bu adımda credential değerleri saklanmaz.

Sadece şu tip referanslar saklanabilir:

- secret_ref
- vault_path_ref
- credential_profile_id
- tenant_id
- environment
- rotation_policy
- audit_policy

Saklanması yasak olan alanlar:

- raw_api_key
- raw_password
- raw_token
- raw_refresh_token
- raw_certificate
- raw_private_key
- raw_client_secret

## Kapalı Tutulan Gerçek İşlemler

- LOGO_REAL_PROVIDER_API_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE
- LOGO_REAL_FILE_DELIVERY_STATUS=CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE
- LOGO_REAL_ERP_WRITE_STATUS=CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE
- LOGO_REAL_SECRET_VALUE_STATUS=FORBIDDEN_IN_CODE_CONFIG_DOCS

## Credential Operation Set

- DECLARE_LOGO_CREDENTIAL_PROFILE
- DECLARE_LOGO_SECRET_REFERENCE
- VALIDATE_LOGO_NO_RAW_SECRET
- VALIDATE_LOGO_TENANT_CREDENTIAL_BOUNDARY
- PREPARE_LOGO_CREDENTIAL_ROTATION_POLICY
- PREPARE_LOGO_CREDENTIAL_AUDIT_POLICY
- PREPARE_LOGO_PROVIDER_LIVE_SECRET_HANDOFF

## Provider Live Handoff Ön Şartları

Gerçek provider/live modülüne geçmeden önce ayrıca açılması gereken kapılar:

- Legal/finance/security onayı
- Provider dokümantasyonu doğrulama
- Vault provider seçimi
- Secret injection policy
- Rotation policy
- Revocation policy
- Audit trail policy
- Break-glass policy
- Real provider live module
- Production secret approval

## Güvenlik Kararı

Bu adım gerçek secret içermez.
Bu adım gerçek provider credential kullanmaz.
Bu adım gerçek Logo API çağrısı yapmaz.
Bu adım gerçek Logo dosya teslimi yapmaz.
Bu adım Pix2pi ERP tarafına gerçek kayıt yazmaz.

## Bir Sonraki Adım

FAZ 7-8L.4 — Logo Export Mapping Contract
