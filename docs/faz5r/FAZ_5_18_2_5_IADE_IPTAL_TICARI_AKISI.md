# FAZ 5-R / 259 — FAZ 5-18.2.5 İade / İptal Ticari Akışı

## Amaç

Bu adım, billing / tenant lifecycle hattında iade ve iptal ticari akışının contract seviyesini hazırlar.

Bu çalışma gerçek para iadesi, production provider refund, otomatik iptal, otomatik müşteri bildirimi veya production e-Belge iade/iptal belgesi üretimini açmaz. Amaç; iade talebi, eligibility policy, tutar hesaplama, iptal doğrulama, manual approval, accounting reversal, tenant entitlement adjustment ve provider/e-Belge deferred marker akışlarını tenant-safe, idempotent ve audit edilebilir şekilde tanımlamaktır.

## Kapsam

1. refund_request_validate
2. refund_eligibility_validate
3. refund_amount_calculate
4. cancel_request_validate
5. credit_note_deferred_marker
6. payment_refund_provider_deferred_marker
7. tenant_entitlement_adjustment_policy
8. manual_approval_queue
9. accounting_reversal_handoff
10. customer_notification_block_policy

## Kritik kurallar

- Production refund kapalı kalır.
- Gerçek para iadesi kapalı kalır.
- Otomatik iptal kapalı kalır.
- Otomatik müşteri bildirimi kapalı kalır.
- tenant_id zorunludur.
- invoice_id zorunludur.
- payment_attempt_id zorunludur.
- refund_request_id zorunludur.
- idempotency_key zorunludur.
- audit trail zorunludur.
- eligibility policy zorunludur.
- amount calculation zorunludur.
- manual approval zorunludur.
- billing owner zorunludur.
- accounting reversal zorunludur.
- credit note handoff zorunludur.
- provider refund handoff zorunludur.
- customer template zorunludur.
- Provider live refund ayrı live payment/refund modülüne defer edilir.
- e-Belge iade/iptal belgesi e-document live modülüne defer edilir.

## Final policy

INTERNAL_REFUND_CANCEL_FLOW_READY=true  
PRODUCTION_REFUND_ENABLED=false  
REAL_MONEY_REFUND_ENABLED=false  
AUTO_CANCEL_ENABLED=false  
AUTO_CUSTOMER_NOTIFICATION_ENABLED=false  
PROVIDER_LIVE_REFUND_DEFERRED=true  
E_DOCUMENT_REFUND_CANCEL_DEFERRED=true  
TENANT_SHUTDOWN_REQUIRED_NEXT=true  
NEXT_GATE=FAZ_5_18_5_4_TENANT_KAPATMA
