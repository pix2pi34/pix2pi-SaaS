# FAZ 2-6.7 — Workflow State / Step / Approval Tables

## Amaç

Bu adım Pix2pi Platform Runtime Persistence katmanında workflow orchestration kayıtlarını kalıcı hale getirir.

## Oluşturulan tablolar

1. platform.workflow_states
2. platform.workflow_steps
3. platform.workflow_approval_records
4. platform.workflow_compensation_states
5. platform.workflow_audit_events

## Kapsam

- Workflow state
- Workflow step
- Approval record
- Compensation state
- Workflow audit

## Tenant güvenliği

Tüm ana workflow tablolarında:

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

- Migration: `db/migrations/faz2/20260506_185431_faz_2_6_7_workflow_state_step_approval_tables.sql`
- Rollback: `backups/faz2/faz_2_6_7_workflow_persistence_20260506_185431/20260506_185431_faz_2_6_7_workflow_state_step_approval_tables_rollback.sql`
- Audit: `scripts/audit/faz2/faz_2_6_7_workflow_persistence_audit.sh`
- Evidence: `docs/faz2/evidence/FAZ_2_6_7_WORKFLOW_PERSISTENCE_REAL_IMPLEMENTATION_AUDIT_20260506_185431.md`

