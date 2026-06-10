# FAZ 2-8.5 — Early Warning / Alert Dashboard

## Amaç

Bu adım WEB-L3 Platform Operations Console içinde Early Warning / Alert Dashboard ekranını kurar.

## Kapsam

- Alert rule modeli
- Alert event modeli
- Runtime health alert görünümü
- Job queue alert görünümü
- Webhook alert görünümü
- Database alert görünümü
- Security alert görünümü
- Event bus alert görünümü
- Acknowledge / resolve lifecycle
- Tenant-safe viewer guard
- Source / severity / status filter
- Responsive HTML checkpoint

## Alert kaynakları

```text
RUNTIME_HEALTH
JOB_QUEUE
WEBHOOK
NOTIFICATION
DATABASE
SECURITY
EVENT_BUS
```

## Alert statüleri

```text
OPEN
ACKNOWLEDGED
RESOLVED
SUPPRESSED
```

## Güvenlik

Tenant dışı görüntüleme varsayılan olarak reddedilir.

Alert acknowledge / resolve için operator_id zorunludur.

## responsive trace

Bu ekran responsive shell, responsive metric grid, responsive alert stream ve responsive alert rules panel düzeniyle WEB-L3 Ops Console içinde mobil/tablet/desktop görünümüne hazırdır.

## Runtime dosyaları

- Runtime: `internal/platform/ops/console/early_warning_alert_dashboard_console.go`
- Test: `internal/platform/ops/console/early_warning_alert_dashboard_console_test.go`

## Web checkpoint

- HTML: `web/ops-console/early-warning-alert-dashboard/index.html`

## Final gate

Bu adım ancak Go test ve real implementation audit PASS olduğunda kapanır.

## Evidence

- Audit: `scripts/audit/faz2/faz_2_8_5_early_warning_alert_dashboard_audit.sh`
- Evidence: `docs/faz2/evidence/FAZ_2_8_5_EARLY_WARNING_ALERT_DASHBOARD_REAL_IMPLEMENTATION_AUDIT_20260507_080952.md`
