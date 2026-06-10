# FAZ 7-8Z.5 — Zirve Admin / Ops / Manual Review

## Amaç

Bu adım, FAZ 7-8Z.4 validation/retry-DLQ kararlarından gelen DLQ, MANUAL_REVIEW ve DENY sonuçlarını admin/ops manual review kuyruğuna alır.

Bu fazda gerçek Zirve API çağrısı, gerçek dosya gönderimi, gerçek delivery channel, gerçek ERP write ve gerçek operator provider action açılmaz.

## Kapsam

- Manual review queue runtime
- Validation retry-DLQ kararından review item açma
- DLQ kararını review kuyruğuna alma
- DENY kararını critical priority ile kuyruğa alma
- Tenant-safe review list/read
- Cross-tenant review read guard
- Assign action
- Resolve action
- Reject action
- Closed review mutation guard
- Dry-run-only action guard
- Real provider side-effect deny guard
- Audit decision zorunluluğu

## Uygun Upstream Kararlar

Aşağıdaki 7-8Z.4 outcome değerleri kuyruğa alınır:

- DLQ
- MANUAL_REVIEW
- DENY

Aşağıdaki outcome değerleri kuyruğa alınmaz:

- PASS
- RETRY

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

- ZIRVE_ADMIN_OPS_MODE=ADMIN_OPS_MANUAL_REVIEW_DRY_RUN_ONLY
- ZIRVE_ADMIN_OPS_STATUS=READY_DRY_RUN_ONLY
- ZIRVE_ADMIN_OPS_QUEUE_POLICY=QUEUE_VALIDATION_DLQ_AND_MANUAL_REVIEW_DECISIONS
- ZIRVE_ADMIN_OPS_ACTION_POLICY=ASSIGN_RESOLVE_REJECT_DRY_RUN_ONLY
- ZIRVE_ADMIN_OPS_AUDIT_POLICY=EVERY_REVIEW_ACTION_REQUIRES_AUDIT_DECISION
- ZIRVE_REAL_PROVIDER_API_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE
- ZIRVE_REAL_FILE_DELIVERY_STATUS=CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE
- ZIRVE_REAL_DELIVERY_CHANNEL_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE
- ZIRVE_REAL_ERP_WRITE_STATUS=CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE
- ZIRVE_REAL_OPERATOR_PROVIDER_ACTION_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE

## Dosyalar

- Runtime: `internal/platform/integrations/providers/zirve/zirve_admin_ops.go`
- Test: `internal/platform/integrations/providers/zirve/zirve_admin_ops_test.go`
- Config: `configs/faz7/integrations/zirve_admin_ops_manual_review.json`
- Audit: `scripts/faz7/audit_faz_7_8z_5_zirve_admin_ops_manual_review.sh`
- Evidence: `docs/faz7/evidence/FAZ_7_8Z_5_ZIRVE_ADMIN_OPS_MANUAL_REVIEW_REAL_IMPLEMENTATION_AUDIT.md`

## Sonraki Mantıklı Adım

FAZ 7-8Z.6 — Zirve E2E Dry-Run Flow.
