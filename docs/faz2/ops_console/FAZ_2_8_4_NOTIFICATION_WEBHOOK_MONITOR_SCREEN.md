# FAZ 2-8.4 — Notification / Webhook İzleme Ekranı

## Amaç

Bu adım WEB-L3 Platform Operations Console içinde Notification / Webhook izleme ekranını kurar.

## Kapsam

- Email delivery görünümü
- SMS delivery görünümü
- Push delivery görünümü
- Webhook delivery görünümü
- Retry scheduled görünümü
- DLQ görünümü
- HMAC signature trace görünümü
- Tenant-safe viewer guard
- Channel / state filter
- Responsive HTML checkpoint

## Runtime dosyaları

- Runtime: `internal/platform/ops/console/notification_webhook_monitor_console.go`
- Test: `internal/platform/ops/console/notification_webhook_monitor_console_test.go`

## Web checkpoint

- HTML: `web/ops-console/notification-webhook-monitor/index.html`

## Güvenlik

Tenant dışı görüntüleme varsayılan olarak reddedilir.

Platform viewer sadece internal ops scope için izinli kabul edilir.

## responsive trace

Bu ekran responsive shell, responsive metric grid ve responsive iki kolon düzeniyle WEB-L3 Ops Console içinde mobil/tablet/desktop görünümüne hazırdır.

## Final gate

Bu adım ancak Go test ve real implementation audit PASS olduğunda kapanır.

## Evidence

- Audit: `scripts/audit/faz2/faz_2_8_4_notification_webhook_monitor_screen_audit.sh`
- Evidence: `docs/faz2/evidence/FAZ_2_8_4_NOTIFICATION_WEBHOOK_MONITOR_SCREEN_REAL_IMPLEMENTATION_AUDIT_20260507_075453.md`
