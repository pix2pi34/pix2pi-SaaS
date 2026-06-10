# FAZ 7-14 — Accountant Billing Live-Ready Runtime

## Amaç

Bu modül, muhasebeci portalı için billing tarafını live-ready hale getirir.

Karar:
- Billing live gelmesini beklemeyeceğiz.
- Fatura/ödeme/abonelik bağı canlı varmış gibi modellenir.
- Gerçek fatura kesme ve para hareketi bu fazda açılmaz.

## Kapsam

- Billing live-ready requirement matrix
- Billing gate modeli
- Invoice issue plan modeli
- VAT hesaplama izleri
- Idempotency guard
- Audit trail
- Rollback / approval gate hazırlığı
- Gerçek invoice issue blocker
- Gerçek billing commit blocker
- Gerçek payment capture blocker
- Gerçek tax submission blocker
- Gerçek provider API blocker

## Bu faz live billing değildir

Bu fazda aşağıdakiler kapalıdır:

- Gerçek fatura kesme
- Gerçek billing commit
- Gerçek payment capture
- Gerçek para hareketi
- Gerçek tax submission
- Gerçek provider API çağrısı
- Gerçek müşteri verisi export

## Live-ready requirements

- plan_catalog_ready
- subscription_runtime_ready
- invoice_draft_runtime_ready
- tenant_account_binding_ready
- tax_config_ready
- billing_idempotency_ready
- billing_audit_ready
- billing_rollback_ready
- legal_approval_gate_ready
- finance_approval_gate_ready
- security_gate_ready
- billing_observability_ready

## Acceptance criteria

- Runtime kodu var
- Test kodu var
- Config var
- Dokümantasyon var
- Audit script var
- Billing live-ready report var
- Requirement matrix var
- Invoice issue plan var
- VAT hesaplama var
- Idempotency guard var
- Real invoice issue blocker var
- Real billing commit blocker var
- Real payment capture blocker var
- Real tax submission blocker var
- Real provider API blocker var
- Audit trail var
- Go test PASS
- Real implementation audit PASS
