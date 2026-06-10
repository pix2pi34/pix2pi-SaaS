# FAZ 2-6.1 — Service Registry Tables

## Amaç

Bu adım Pix2pi Platform Runtime Persistence katmanında service registry kayıtlarını kalıcı hale getirir.

## Oluşturulan tablolar

1. platform.service_instances
2. platform.service_instance_heartbeats
3. platform.service_instance_metadata
4. platform.service_tenant_visibility
5. platform.service_stale_instance_markers

## Kapsam

- Service instance
- Heartbeat
- Metadata
- Tenant visibility
- Stale instance marker

## Güvenlik kararı

Bu faz gerçek service discovery runtime veya process restart yapmaz. Sadece service registry persistence tabanını kurar.

Mission control, health aggregation, stale detection, service routing ve ops console entegrasyonları sonraki runtime/service katmanlarında açılır.

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

- Migration: `db/migrations/faz2/20260506_191430_faz_2_6_1_service_registry_tables.sql`
- Rollback: `backups/faz2/faz_2_6_1_service_registry_persistence_20260506_191430/20260506_191430_faz_2_6_1_service_registry_tables_rollback.sql`
- Audit: `scripts/audit/faz2/faz_2_6_1_service_registry_audit.sh`
- Evidence: `docs/faz2/evidence/FAZ_2_6_1_SERVICE_REGISTRY_REAL_IMPLEMENTATION_AUDIT_20260506_191430.md`

