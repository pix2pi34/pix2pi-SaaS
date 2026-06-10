# FAZ 2-8.3 — Job Queue / Worker Monitor Ekranı

## Amaç

Bu adım WEB-L3 Platform Operations Console içinde Job Queue / Worker Monitor ekranını kurar.

## Kapsam

- Tenant-aware job queue görünümü
- Worker monitor görünümü
- Queue filter
- Failed / DLQ görünürlüğü
- Worker heartbeat stale detection
- Tenant-safe viewer guard
- Responsive HTML checkpoint
- Console runtime model ve testleri

## Runtime dosyaları

- Runtime: `internal/platform/ops/console/job_queue_worker_monitor_console.go`
- Test: `internal/platform/ops/console/job_queue_worker_monitor_console_test.go`

## Web checkpoint

- HTML: `web/ops-console/job-worker-monitor/index.html`

## Güvenlik

Tenant dışı görüntüleme varsayılan olarak reddedilir.

Platform viewer sadece internal ops scope için izinli kabul edilir.

## Final gate

Bu adım ancak Go test ve real implementation audit PASS olduğunda kapanır.

## Evidence

- Audit: `scripts/audit/faz2/faz_2_8_3_job_queue_worker_monitor_screen_audit.sh`
- Evidence: `docs/faz2/evidence/FAZ_2_8_3_JOB_QUEUE_WORKER_MONITOR_SCREEN_REAL_IMPLEMENTATION_AUDIT_20260507_075007.md`

## responsive trace

Bu ekran responsive shell, responsive metric grid ve responsive iki kolon düzeniyle WEB-L3 Ops Console içinde mobil/tablet/desktop görünümüne hazırdır.
