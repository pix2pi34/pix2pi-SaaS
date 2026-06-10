# FAZ 2-6.6 — Webhook Delivery / Retry / DLQ Tables

## Amaç

Bu adım Pix2pi Platform Runtime Persistence katmanında webhook delivery, retry, DLQ, signature metadata ve delivery audit kayıtlarını kalıcı hale getirir.

## Oluşturulan tablolar

1. platform.webhook_deliveries
2. platform.webhook_retry_states
3. platform.webhook_dlq_states
4. platform.webhook_signature_metadata
5. platform.webhook_delivery_audit_events

## Kapsam

- Webhook delivery
- Retry state
- DLQ state
- Signature metadata
- Delivery audit

## Güvenlik kararı

Webhook secret raw değerleri bu fazda saklanmaz. Signature tarafında sadece secret_ref, payload_hash ve signature_hash tutulur.

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

- Migration: `db/migrations/faz2/20260506_190721_faz_2_6_6_webhook_delivery_retry_dlq_tables.sql`
- Rollback: `backups/faz2/faz_2_6_6_webhook_delivery_retry_dlq_persistence_20260506_190721/20260506_190721_faz_2_6_6_webhook_delivery_retry_dlq_tables_rollback.sql`
- Audit: `scripts/audit/faz2/faz_2_6_6_webhook_delivery_retry_dlq_audit.sh`
- Evidence: `docs/faz2/evidence/FAZ_2_6_6_WEBHOOK_DELIVERY_RETRY_DLQ_REAL_IMPLEMENTATION_AUDIT_20260506_190721.md`

