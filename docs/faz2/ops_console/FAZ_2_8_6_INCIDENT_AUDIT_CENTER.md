# FAZ 2-8.6 — Incident / Audit Center

## Amaç

Bu adım WEB-L3 Platform Operations Console içinde Incident / Audit Center ekranını kurar.

## Kapsam

- Incident kayıt modeli
- Audit kayıt modeli
- Incident snapshot
- Audit snapshot
- Severity filter
- Status filter
- Action filter
- Resolve incident lifecycle
- Security / operator / system audit görünümü
- Tenant-safe viewer guard
- Responsive HTML checkpoint

## Runtime dosyaları

- Runtime: `internal/platform/ops/console/incident_audit_center_console.go`
- Test: `internal/platform/ops/console/incident_audit_center_console_test.go`

## Web checkpoint

- HTML: `web/ops-console/incident-audit-center/index.html`

## Güvenlik

Tenant dışı görüntüleme varsayılan olarak reddedilir.

Platform viewer sadece internal ops scope için izinli kabul edilir.

## responsive trace

Bu ekran responsive shell, responsive metric grid ve responsive iki kolon düzeniyle WEB-L3 Ops Console içinde mobil/tablet/desktop görünümüne hazırdır.

## Final gate

Bu adım ancak Go test ve real implementation audit PASS olduğunda kapanır.

## Evidence

- Audit: `scripts/audit/faz2/faz_2_8_6_incident_audit_center_audit.sh`
- Evidence: `docs/faz2/evidence/FAZ_2_8_6_INCIDENT_AUDIT_CENTER_REAL_IMPLEMENTATION_AUDIT_20260507_075716.md`
