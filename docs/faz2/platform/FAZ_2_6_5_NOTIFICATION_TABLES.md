# FAZ 2-6.5 — Notification Tables

## Amaç

Bu adım Pix2pi Platform Runtime Persistence katmanında notification, channel delivery, email/SMS/push state, retry state ve delivery audit kayıtlarını kalıcı hale getirir.

## Oluşturulan tablolar

1. platform.notifications
2. platform.notification_channel_deliveries
3. platform.notification_channel_states
4. platform.notification_retry_states
5. platform.notification_delivery_audit_events

## Kapsam

- Notification
- Channel delivery
- Email/SMS/push state
- Retry state
- Delivery audit

## Güvenlik kararı

Bu faz gerçek email/SMS/push gönderimi yapmaz. Sadece notification persistence tabanını kurar.

Provider adapter, gerçek delivery worker, SMS/email provider credential yönetimi ve push notification runtime sonraki runtime/service katmanlarında açılır.

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

- Migration: `db/migrations/faz2/20260506_192251_faz_2_6_5_notification_tables.sql`
- Rollback: `backups/faz2/faz_2_6_5_notification_persistence_20260506_192251/20260506_192251_faz_2_6_5_notification_tables_rollback.sql`
- Audit: `scripts/audit/faz2/faz_2_6_5_notification_audit.sh`
- Evidence: `docs/faz2/evidence/FAZ_2_6_5_NOTIFICATION_REAL_IMPLEMENTATION_AUDIT_20260506_192251.md`

