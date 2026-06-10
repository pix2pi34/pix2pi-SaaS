# FAZ 2-6.2 — Mission Control Action / Incident Log Tables

## Amaç

Bu adım Pix2pi Platform Runtime Persistence katmanında mission control operasyonlarını, incident kayıtlarını, operator action geçmişini, maintenance state ve quarantine state verilerini kalıcı hale getirir.

## Oluşturulan tablolar

1. platform.mission_control_action_logs
2. platform.incident_logs
3. platform.operator_actions
4. platform.maintenance_states
5. platform.quarantine_states

## Kapsam

- Action log
- Incident log
- Operator action
- Maintenance state
- Quarantine state

## Güvenlik kararı

Bu faz gerçek servis restart/stop/start yapmaz. Sadece mission control runtime persistence tabanını kurar.

Gerçek operator action execution, service registry entegrasyonu, maintenance orchestration ve quarantine enforcement sonraki runtime/service katmanlarında açılır.

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

- Migration: `db/migrations/faz2/20260506_191101_faz_2_6_2_mission_control_incident_tables.sql`
- Rollback: `backups/faz2/faz_2_6_2_mission_control_incident_persistence_20260506_191101/20260506_191101_faz_2_6_2_mission_control_incident_tables_rollback.sql`
- Audit: `scripts/audit/faz2/faz_2_6_2_mission_control_incident_audit.sh`
- Evidence: `docs/faz2/evidence/FAZ_2_6_2_MISSION_CONTROL_INCIDENT_REAL_IMPLEMENTATION_AUDIT_20260506_191101.md`

