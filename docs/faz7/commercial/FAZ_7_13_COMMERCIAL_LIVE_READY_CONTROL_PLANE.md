# FAZ 7-13 — Commercial Live-Ready Control Plane

## Amaç

Bu modül, FAZ 7 içinde live modüllerin merkezi activation beynini kurar.

Karar:
- Live modüller gelmesini beklemeyeceğiz.
- Sistem live varmış gibi hazırlanacak.
- Gerçek canlı işlem yine kapalı gate arkasında kalacak.

## Bu fazın görevi

Bu faz aşağıdaki live-ready başlıkları merkezi olarak yönetir:

- billing_live_ready
- payment_capture_live_ready
- provider_live_ready
- export_live_ready
- erp_sync_live_ready
- secrets_ready
- legal_approval_ready
- finance_approval_ready
- security_approval_ready
- operator_approval_ready
- rollback_ready
- observability_ready
- incident_response_ready
- tenant_isolation_ready

## Bu faz live activation değildir

Bu fazda aşağıdakiler kapalıdır:

- Gerçek para hareketi
- Gerçek billing
- Gerçek payment capture
- Gerçek provider API çağrısı
- Gerçek file delivery
- Gerçek ERP write
- Gerçek müşteri verisi export
- Gerçek operator provider action

## Production activation lock

FAZ 7-13 içinde production activation kilidi açılamaz.

Durum:
- PRODUCTION_ACTIVATION_ALLOWED=false
- REAL_MONEY_MOVEMENT_ALLOWED=false
- REAL_PROVIDER_API_CALL_ALLOWED=false
- REAL_CUSTOMER_DATA_EXPORT_ALLOWED=false
- REAL_ERP_WRITE_ALLOWED=false

## Sonraki modüller

Bu control plane başarılı olursa sıradaki live-ready modüller:

1. FAZ 7-14 Accountant Billing Live-Ready Runtime
2. FAZ 7-15 Payment Capture Live-Ready Runtime
3. FAZ 7-16 Provider Live Adapter Readiness
4. FAZ 7-17 Export Live-Ready Pipeline
5. FAZ 7-18 ERP Sync Worker Live-Ready Runtime
6. FAZ 7-19 Live Activation Guard / Approval Matrix
7. FAZ 7-20 Commercial Master Closure

## Acceptance criteria

- Runtime kodu var
- Test kodu var
- Config var
- Dokümantasyon var
- Audit script var
- Live-ready requirement matrix var
- Activation decision modeli var
- Production activation lock var
- Real billing blocker var
- Real payment blocker var
- Real provider API blocker var
- Real file delivery blocker var
- Real ERP write blocker var
- Real customer data export blocker var
- Next module planı var
- Audit trail var
- Go test PASS
- Real implementation audit PASS
