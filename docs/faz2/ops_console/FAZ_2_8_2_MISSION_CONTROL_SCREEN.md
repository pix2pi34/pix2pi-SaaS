# FAZ 2-8.2 — Mission Control Ekranı

## Amaç

Bu adım WEB-L3 Platform Operations Console içinde Mission Control ekranını kurar.

## Kapsam

- Restart action görünümü
- Isolate action görünümü
- Quarantine action görünümü
- Maintenance mode görünümü
- Incident note görünümü
- Operator role guard
- Tenant-safe viewer guard
- Action / status filter
- Responsive HTML checkpoint

## Action modeli

```text
RESTART
ISOLATE
QUARANTINE
MAINTENANCE
INCIDENT_NOTE
```

## Status modeli

```text
REQUESTED
APPROVED
REJECTED
EXECUTED
```

## Güvenlik

Tenant dışı görüntüleme varsayılan olarak reddedilir.

VIEWER rolü mutating action oluşturamaz.

OPERATOR ve ADMIN rolleri action oluşturabilir.

## responsive trace

Bu ekran responsive shell, responsive metric grid, responsive mission actions table ve responsive control actions panel düzeniyle WEB-L3 Ops Console içinde mobil/tablet/desktop görünümüne hazırdır.

## Runtime dosyaları

- Runtime: `internal/platform/ops/console/mission_control_screen_console.go`
- Test: `internal/platform/ops/console/mission_control_screen_console_test.go`

## Web checkpoint

- HTML: `web/ops-console/mission-control/index.html`

## Final gate

Bu adım ancak Go test ve real implementation audit PASS olduğunda kapanır.

## Evidence

- Audit: `scripts/audit/faz2/faz_2_8_2_mission_control_screen_audit.sh`
- Evidence: `docs/faz2/evidence/FAZ_2_8_2_MISSION_CONTROL_SCREEN_REAL_IMPLEMENTATION_AUDIT_20260507_080754.md`
