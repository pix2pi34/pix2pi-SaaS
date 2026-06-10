# FAZ 2-8.1 — Service Registry Ekranı

## Amaç

Bu adım WEB-L3 Platform Operations Console içinde Service Registry ekranını kurar.

## Kapsam

- Service instance kayıt modeli
- Tenant-aware service registry snapshot
- Status filter
- Visibility filter
- Tenant/platform/internal visibility ayrımı
- Stale heartbeat detection
- Tenant-safe viewer guard
- Responsive HTML checkpoint

## Status modeli

```text
HEALTHY
DEGRADED
DOWN
MAINTENANCE
```

## Visibility modeli

```text
TENANT
PLATFORM
INTERNAL
```

## Runtime dosyaları

- Runtime: `internal/platform/ops/console/service_registry_screen_console.go`
- Test: `internal/platform/ops/console/service_registry_screen_console_test.go`

## Web checkpoint

- HTML: `web/ops-console/service-registry/index.html`

## Güvenlik

Tenant dışı görüntüleme varsayılan olarak reddedilir.

Tenant viewer INTERNAL visibility servisleri göremez.

Platform viewer INTERNAL servisleri sadece include_internal=true olduğunda görebilir.

## responsive trace

Bu ekran responsive shell, responsive metric grid ve responsive service table düzeniyle WEB-L3 Ops Console içinde mobil/tablet/desktop görünümüne hazırdır.

## Final gate

Bu adım ancak Go test ve real implementation audit PASS olduğunda kapanır.

## Evidence

- Audit: `scripts/audit/faz2/faz_2_8_1_service_registry_screen_audit.sh`
- Evidence: `docs/faz2/evidence/FAZ_2_8_1_SERVICE_REGISTRY_SCREEN_REAL_IMPLEMENTATION_AUDIT_20260507_080514.md`
