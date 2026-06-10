# FAZ 5-R / 257 — FAZ 5-18.2.3 Tahsilat / Başarısız Ödeme Akışı

## Amaç

Bu adım, billing / tenant lifecycle hattında tahsilat ve başarısız ödeme akışının ticari operasyon contract'ını hazırlar.

Bu çalışma gerçek ödeme sağlayıcı production tahsilatını açmaz. Amaç; invoice due, collection attempt, payment failed, retry schedule, grace period, manual review ve tenant action block politikalarının tenant-safe, idempotent ve audit edilebilir şekilde tanımlanmasıdır.

## Kapsam

1. invoice_due_marker
2. collection_attempt_create
3. payment_failed_capture
4. retry_schedule_policy
5. grace_period_policy
6. manual_review_queue
7. tenant_action_block_policy
8. provider_live_deferred_marker

## Kritik kurallar

- Production payment kapalı kalır.
- Gerçek müşteri tahsilatı kapalı kalır.
- Otomatik tenant suspension kapalı kalır.
- tenant_id zorunludur.
- invoice_id zorunludur.
- attempt_id zorunludur.
- idempotency_key zorunludur.
- audit trail zorunludur.
- retry policy zorunludur.
- dunning template zorunludur.
- manual review zorunludur.
- billing owner zorunludur.
- Production charging block zorunludur.
- Auto tenant suspension block zorunludur.
- Gerçek provider live tahsilatı provider-specific live module içine defer edilir.

## Final policy

INTERNAL_COLLECTION_FLOW_READY=true  
PRODUCTION_PAYMENT_ENABLED=false  
REAL_CUSTOMER_CHARGING_ENABLED=false  
AUTO_TENANT_SUSPENSION_ENABLED=false  
REAL_PROVIDER_LIVE_DEFERRED=true  
INVOICE_FLOW_REQUIRED_NEXT=true  
NEXT_GATE=FAZ_5_18_2_2_FATURALAMA_AKISI
