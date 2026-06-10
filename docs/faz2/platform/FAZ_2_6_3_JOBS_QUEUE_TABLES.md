# FAZ 2-6.3 — Jobs Queue Tables

## Amaç

Bu adım Pix2pi Platform Runtime Persistence katmanında job queue, retry/backoff, tenant job scope, job audit ve dead job state kayıtlarını kalıcı hale getirir.

## Oluşturulan tablolar

1. platform.job_queues
2. platform.job_retry_states
3. platform.tenant_job_scopes
4. platform.job_audit_events
5. platform.dead_job_states

## Kapsam

- Job queue
- Retry/backoff
- Tenant job scope
- Job audit
- Dead job state

## Güvenlik kararı

Bu faz gerçek worker execution başlatmaz. Sadece jobs queue persistence tabanını kurar.

Worker runtime, scheduler, retry executor, dead job replay ve tenant-level concurrency enforcement sonraki runtime/service katmanlarında açılır.

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

- Migration: `db/migrations/faz2/20260506_191740_faz_2_6_3_jobs_queue_tables.sql`
- Rollback: `backups/faz2/faz_2_6_3_jobs_queue_persistence_20260506_191740/20260506_191740_faz_2_6_3_jobs_queue_tables_rollback.sql`
- Audit: `scripts/audit/faz2/faz_2_6_3_jobs_queue_audit.sh`
- Evidence: `docs/faz2/evidence/FAZ_2_6_3_JOBS_QUEUE_REAL_IMPLEMENTATION_AUDIT_20260506_191740.md`

