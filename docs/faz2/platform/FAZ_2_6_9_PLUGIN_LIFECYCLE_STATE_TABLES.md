# FAZ 2-6.9 — Plugin Lifecycle / Plugin State Tables

## Amaç

Bu adım Pix2pi Platform Runtime Persistence katmanında plugin lifecycle, plugin version, tenant install, runtime state ve compatibility state kayıtlarını kalıcı hale getirir.

## Oluşturulan tablolar

1. platform.plugin_lifecycles
2. platform.plugin_versions
3. platform.tenant_plugin_installs
4. platform.plugin_states
5. platform.plugin_compatibility_states

## Kapsam

- Plugin lifecycle
- Plugin version
- Tenant plugin install
- Plugin state
- Compatibility state

## Güvenlik kararı

Bu faz gerçek provider çalıştırmaz. Sadece kalıcı runtime persistence tabanını kurar.

Production plugin execution, marketplace publish, provider live action ve tenant install orchestration sonraki runtime/service katmanlarında açılır.

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

- Migration: `db/migrations/faz2/20260506_190119_faz_2_6_9_plugin_lifecycle_state_tables.sql`
- Rollback: `backups/faz2/faz_2_6_9_plugin_lifecycle_state_persistence_20260506_190119/20260506_190119_faz_2_6_9_plugin_lifecycle_state_tables_rollback.sql`
- Audit: `scripts/audit/faz2/faz_2_6_9_plugin_lifecycle_state_audit.sh`
- Evidence: `docs/faz2/evidence/FAZ_2_6_9_PLUGIN_LIFECYCLE_STATE_REAL_IMPLEMENTATION_AUDIT_20260506_190119.md`

