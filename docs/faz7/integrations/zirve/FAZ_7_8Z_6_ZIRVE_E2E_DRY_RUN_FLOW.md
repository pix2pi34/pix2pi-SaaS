# FAZ 7-8Z.6 — Zirve E2E Dry-Run Flow

## Amaç

Bu adım, Zirve dry-run connector ailesinin uçtan uca zincirini gerçek Zirve sistemine temas etmeden doğrular.

## E2E Zincir

1. Foundation identity validation
2. File generation dry-run package
3. Import delivery contract
4. Validation / Retry-DLQ decision
5. Admin / Ops manual review if eligible
6. Final real-operation guard verification

## Kapsam

- FAZ 7-8Z foundation identity kullanımı
- FAZ 7-8Z.2 file generation dry-run package kullanımı
- FAZ 7-8Z.3 import delivery contract kullanımı
- FAZ 7-8Z.4 validation/retry-DLQ decision kullanımı
- FAZ 7-8Z.5 admin/ops manual review kullanımı
- PASS flow için manual review skip
- MANUAL_REVIEW flow için review açma
- DLQ flow için review açma
- DENY flow için critical review açma
- Chain evidence step list
- Tenant/correlation/run id doğrulaması
- Dry-run-only guard
- Real provider API deny guard
- Real file delivery deny guard
- Real delivery channel deny guard
- Real ERP write deny guard
- Real operator provider action deny guard

## Bilinçli Kapalı Kalan Gerçek İşlemler

Aşağıdaki gerçek işlemler bu fazda açılmaz:

- Gerçek Zirve API çağrısı
- Gerçek Zirve dosya gönderimi
- Gerçek delivery channel
- Gerçek ERP write
- Gerçek operator provider action
- Gerçek provider side effect
- Gerçek external delivery attempt
- Gerçek secret value kullanımı

## Gate Durumu

- ZIRVE_E2E_DRY_RUN_MODE=E2E_DRY_RUN_FLOW_ONLY
- ZIRVE_E2E_DRY_RUN_STATUS=READY_DRY_RUN_ONLY
- ZIRVE_E2E_CHAIN_POLICY=FOUNDATION_TO_ADMIN_OPS_DRY_RUN_CHAIN
- ZIRVE_E2E_EVIDENCE_POLICY=CHAIN_EVIDENCE_REQUIRED_FOR_EVERY_STEP
- ZIRVE_REAL_PROVIDER_API_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE
- ZIRVE_REAL_FILE_DELIVERY_STATUS=CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE
- ZIRVE_REAL_DELIVERY_CHANNEL_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE
- ZIRVE_REAL_ERP_WRITE_STATUS=CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE
- ZIRVE_REAL_OPERATOR_PROVIDER_ACTION_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE

## Dosyalar

- Runtime: `internal/platform/integrations/providers/zirve/zirve_e2e_dry_run.go`
- Test: `internal/platform/integrations/providers/zirve/zirve_e2e_dry_run_test.go`
- Config: `configs/faz7/integrations/zirve_e2e_dry_run_flow.json`
- Audit: `scripts/faz7/audit_faz_7_8z_6_zirve_e2e_dry_run_flow.sh`
- Evidence: `docs/faz7/evidence/FAZ_7_8Z_6_ZIRVE_E2E_DRY_RUN_FLOW_REAL_IMPLEMENTATION_AUDIT.md`

## Sonraki Mantıklı Adım

FAZ 7-8Z.7 — Zirve Connector Final Closure / Provider Live Handoff Gate.
