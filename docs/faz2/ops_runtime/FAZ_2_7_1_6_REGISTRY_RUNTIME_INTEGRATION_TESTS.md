# FAZ 2-7.1.6 — Registry Runtime Integration Tests

## Amaç

Bu adım FAZ 2-7.1 service registry runtime ailesinin ilk integration closure testlerini kapatır.

## Kapanan alt runtime işleri

- FAZ 2-7.1.3 Instance metadata persistence
- FAZ 2-7.1.4 Stale instance auto-cleanup job
- FAZ 2-7.1.5 Tenant-aware registry visibility runtime

## Final test kapsamı

- Instance metadata final test
- Stale instance cleanup final test
- Registry visibility final test
- Cross-tenant registry deny final test
- Registry runtime integration closure

## Final gate

Bu adım ancak Go test ve audit sonucu PASS olduğunda kapanır.

## Dosyalar

- Final test: `internal/platform/ops/runtime/registry_runtime_integration_final_test.go`
- Config: `configs/faz2/ops_runtime/registry_runtime_integration_tests.v1.json`
- Audit: `scripts/audit/faz2/faz_2_7_1_6_registry_runtime_integration_tests_audit.sh`
- Evidence: `docs/faz2/evidence/FAZ_2_7_1_6_REGISTRY_RUNTIME_INTEGRATION_TESTS_REAL_IMPLEMENTATION_AUDIT_20260507_070124.md`
