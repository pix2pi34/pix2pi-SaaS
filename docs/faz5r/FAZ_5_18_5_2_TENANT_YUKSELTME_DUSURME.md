# FAZ 5-R / 262 — FAZ 5-18.5.2 Tenant Yükseltme / Düşürme

## Amaç

Bu adım, tenant paket yükseltme/düşürme akışının commercial lifecycle contract seviyesini hazırlar.

Bu çalışma production plan change, gerçek müşteri plan değişikliği, otomatik entitlement switch veya otomatik proration billing açmaz. Amaç; plan change request, current plan snapshot, target plan validation, entitlement diff, billing impact, proration policy, downgrade safety check, owner approval, effective date ve deferred marker akışlarını tenant-safe ve audit edilebilir hale getirmektir.

## Kapsam

1. plan_change_request_intake
2. current_plan_snapshot
3. target_plan_validate
4. entitlement_diff_calculate
5. billing_impact_calculate
6. proration_policy_prepare
7. downgrade_safety_check
8. owner_approval_queue
9. effective_date_schedule
10. plan_change_deferred_marker

## Kritik kurallar

- Production plan change kapalı kalır.
- Real customer plan change kapalı kalır.
- Auto entitlement switch kapalı kalır.
- Auto proration billing kapalı kalır.
- tenant_id zorunludur.
- plan_change_request_id zorunludur.
- current_plan_id zorunludur.
- target_plan_id zorunludur.
- plan snapshot zorunludur.
- entitlement diff zorunludur.
- billing impact zorunludur.
- proration policy zorunludur.
- downgrade safety check zorunludur.
- owner approval zorunludur.
- effective date zorunludur.
- audit trail zorunludur.
- rollback plan zorunludur.
- support handoff zorunludur.
- customer template zorunludur.

## Final policy

INTERNAL_TENANT_PLAN_CHANGE_READY=true  
PRODUCTION_PLAN_CHANGE_ENABLED=false  
REAL_CUSTOMER_PLAN_CHANGE_ENABLED=false  
AUTO_ENTITLEMENT_SWITCH_ENABLED=false  
AUTO_PRORATION_BILLING_ENABLED=false  
TENANT_FREEZE_REQUIRED_NEXT=true  
NEXT_GATE=FAZ_5_18_5_3_TENANT_DONDURMA
