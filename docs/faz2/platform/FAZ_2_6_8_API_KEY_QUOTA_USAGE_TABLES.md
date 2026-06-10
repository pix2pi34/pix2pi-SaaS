# FAZ 2-6.8 — API Key / Quota / Usage Tables

## Amaç

Bu adım Pix2pi Platform Runtime Persistence katmanında API key, kota, kullanım ölçümü, app auth ilişkisi ve usage audit altyapısını kalıcı hale getirir.

## Oluşturulan tablolar

1. platform.api_keys
2. platform.api_quota_policies
3. platform.app_auth_relations
4. platform.api_usage_meters
5. platform.api_usage_audit_events

## Kapsam

- API key table
- Quota table
- Usage meter table
- App auth relation
- Usage audit

## Güvenlik kararı

Raw API key asla saklanmaz.

Saklanan alanlar:

- key_prefix
- key_hash

## Tenant güvenliği

Tüm tablolarda:

- tenant_id zorunlu
- Row Level Security aktif
- FORCE ROW LEVEL SECURITY aktif
- tenant isolation policy aktif

Desteklenen DB session tenant anahtarları:

- pix2pi.tenant_id
- app.tenant_id
- request.tenant_id

## Final gate

Bu adım ancak migration ve real implementation audit PASS olduğunda kapanır.

## Dosyalar

- Migration: `db/migrations/faz2/20260506_185818_faz_2_6_8_api_key_quota_usage_tables.sql`
- Rollback: `backups/faz2/faz_2_6_8_api_key_quota_usage_persistence_20260506_185818/20260506_185818_faz_2_6_8_api_key_quota_usage_tables_rollback.sql`
- Audit: `scripts/audit/faz2/faz_2_6_8_api_key_quota_usage_audit.sh`
- Evidence: `docs/faz2/evidence/FAZ_2_6_8_API_KEY_QUOTA_USAGE_REAL_IMPLEMENTATION_AUDIT_20260506_185818.md`

