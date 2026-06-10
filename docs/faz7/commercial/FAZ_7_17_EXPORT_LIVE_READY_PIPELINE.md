# FAZ 7-17 — Export Live-Ready Pipeline

## Amaç

Bu modül export pipeline hattını live-ready hale getirir.

Karar:
- Export live gelmesini beklemeyeceğiz.
- Export schema, manifest, package builder, delivery plan ve checksum yapısı canlı varmış gibi modellenir.
- Gerçek müşteri verisi export, gerçek file delivery, gerçek provider API ve gerçek ERP write bu fazda açılmaz.

## Kapsam

- Export live-ready requirement matrix
- Export gate modeli
- Supported provider / format set
- Export package plan
- Synthetic manifest
- Checksum / integrity guard
- Delivery plan
- Idempotency guard
- Audit trail
- Real customer data export blocker
- Real file delivery blocker
- Real provider API blocker
- Real ERP write blocker
- Real operator export action blocker

## Bu faz live export değildir

Bu fazda aşağıdakiler kapalıdır:

- Gerçek müşteri verisi export
- Gerçek müşteri payload
- Gerçek file delivery
- Gerçek provider API çağrısı
- Gerçek ERP write
- Gerçek operator export action

## Live-ready requirements

- provider_live_adapter_ready
- export_schema_ready
- export_manifest_ready
- export_package_builder_ready
- export_checksum_ready
- export_delivery_plan_ready
- customer_data_consent_gate_ready
- export_idempotency_ready
- export_retry_dlq_ready
- export_audit_ready
- export_rollback_ready
- legal_approval_gate_ready
- finance_approval_gate_ready
- security_gate_ready
- export_observability_ready

## Acceptance criteria

- Runtime kodu var
- Test kodu var
- Config var
- Dokümantasyon var
- Audit script var
- Export live-ready report var
- Requirement matrix var
- Export package plan var
- Manifest var
- Checksum var
- Delivery plan var
- Idempotency guard var
- Supported provider / format set var
- Real customer data export blocker var
- Real file delivery blocker var
- Real provider API blocker var
- Real ERP write blocker var
- Real operator export action blocker var
- Audit trail var
- Go test PASS
- Real implementation audit PASS
