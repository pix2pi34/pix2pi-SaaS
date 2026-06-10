# FAZ 5-R / 258 — FAZ 5-18.2.2 Faturalama Akışı

## Amaç

Bu adım, billing / tenant lifecycle hattında faturalama akışının ticari operasyon contract'ını hazırlar.

Bu çalışma gerçek müşteri faturası, production e-Belge veya otomatik fatura gönderimi açmaz. Amaç; fatura taslağı, billing profile validation, plan snapshot, line item, vergi hesaplama, due date, accounting export handoff ve e-Belge deferred marker akışını tenant-safe, idempotent ve audit edilebilir şekilde tanımlamaktır.

## Kapsam

1. invoice_draft_create
2. invoice_billing_profile_validate
3. invoice_plan_snapshot_attach
4. invoice_line_item_calculate
5. invoice_tax_calculate
6. invoice_finalize
7. invoice_due_schedule
8. invoice_delivery_block_policy
9. accounting_export_handoff
10. e_document_deferred_marker

## Kritik kurallar

- Production invoice kapalı kalır.
- Gerçek müşteri faturası kapalı kalır.
- Otomatik fatura gönderimi kapalı kalır.
- tenant_id zorunludur.
- invoice_id zorunludur.
- billing profile zorunludur.
- plan snapshot zorunludur.
- line item zorunludur.
- tax calculation zorunludur.
- due date zorunludur.
- currency zorunludur.
- audit trail zorunludur.
- idempotency key zorunludur.
- accounting export handoff zorunludur.
- e-Belge handoff zorunludur.
- e-Belge production gönderimi e-document provider/live modülüne defer edilir.

## Final policy

INTERNAL_INVOICE_FLOW_READY=true  
PRODUCTION_INVOICE_ENABLED=false  
REAL_CUSTOMER_INVOICE_ENABLED=false  
AUTO_INVOICE_DELIVERY_ENABLED=false  
E_DOCUMENT_LIVE_DEFERRED=true  
REFUND_CANCEL_FLOW_REQUIRED_NEXT=true  
NEXT_GATE=FAZ_5_18_2_5_IADE_IPTAL_TICARI_AKISI
