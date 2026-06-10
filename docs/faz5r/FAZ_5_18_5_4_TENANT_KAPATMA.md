# FAZ 5-R / 260 — FAZ 5-18.5.4 Tenant Kapatma

## Amaç

Bu adım, tenant kapatma akışının ticari ve operasyonel contract seviyesini hazırlar.

Bu çalışma gerçek tenant kapatma, veri silme, otomatik erişim kesme veya production shutdown açmaz. Amaç; kapatma talebi, billing kontrolü, ödenmemiş fatura kontrolü, veri export teklifi, legal hold kontrolü, owner approval, erişim dondurma planı, billing stop planı ve final shutdown deferred marker akışlarını tenant-safe ve audit edilebilir şekilde tanımlamaktır.

## Kapsam

1. shutdown_request_intake
2. billing_status_validate
3. unpaid_invoice_check
4. data_export_offer
5. legal_hold_check
6. owner_approval_queue
7. tenant_access_freeze_plan
8. billing_stop_plan
9. final_shutdown_deferred_marker

## Kritik kurallar

- Production shutdown kapalı kalır.
- Gerçek tenant closure kapalı kalır.
- Data deletion kapalı kalır.
- Auto access cutoff kapalı kalır.
- tenant_id zorunludur.
- shutdown_request_id zorunludur.
- billing status check zorunludur.
- unpaid invoice check zorunludur.
- data export offer zorunludur.
- legal hold check zorunludur.
- owner approval zorunludur.
- support handoff zorunludur.
- customer template zorunludur.
- audit trail zorunludur.
- rollback window zorunludur.
- backup snapshot zorunludur.
- entitlement freeze zorunludur.
- billing stop plan zorunludur.
- Final shutdown production approval ve veri export/devir tamamlanmadan açılmaz.

## Final policy

INTERNAL_TENANT_SHUTDOWN_READY=true  
PRODUCTION_SHUTDOWN_ENABLED=false  
REAL_TENANT_CLOSURE_ENABLED=false  
DATA_DELETION_ENABLED=false  
AUTO_ACCESS_CUTOFF_ENABLED=false  
DATA_EXPORT_FLOW_REQUIRED_NEXT=true  
FINAL_SHUTDOWN_DEFERRED_TO_PRODUCTION_APPROVAL=true  
NEXT_GATE=FAZ_5_18_5_5_VERI_EXPORT_DEVIR_AKISI
