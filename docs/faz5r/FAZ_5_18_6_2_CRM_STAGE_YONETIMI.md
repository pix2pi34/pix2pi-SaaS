# FAZ 5-R / 265 — FAZ 5-18.6.2 CRM Stage Yönetimi

## Amaç

Bu adım, CRM stage yönetiminin commercial ops contract seviyesini hazırlar.

Bu çalışma production CRM, gerçek müşteri CRM operasyonu, external CRM provider veya otomatik satış aksiyonu açmaz. Amaç; lead intake, discovery, qualified, demo, proposal, won/lost ve onboarding handoff stage geçişlerini tenant-safe, consent/KVKK uyumlu, audit edilebilir ve rollback path ile kontrol edilebilir hale getirmektir.

## Kapsam

1. lead_to_discovery
2. discovery_to_qualified
3. qualified_to_demo
4. demo_to_proposal_requested
5. proposal_requested_to_proposal_sent
6. proposal_sent_to_won
7. proposal_sent_to_lost
8. won_to_onboarding_handoff
9. quote_sales_flow_deferred_marker

## Kritik kurallar

- Production CRM kapalı kalır.
- Real customer CRM open kapalı kalır.
- Auto sales action kapalı kalır.
- External CRM provider kapalı kalır.
- tenant_id zorunludur.
- lead_id zorunludur.
- stage reason zorunludur.
- owner assignment zorunludur.
- audit trail zorunludur.
- consent check zorunludur.
- KVKK notice zorunludur.
- next action zorunludur.
- SLA zorunludur.
- rollback path zorunludur.
- duplicate guard zorunludur.
- manual review zorunludur.
- Teklif / satış akışı sıradaki iş 266 içinde açılır.

## Final policy

INTERNAL_CRM_STAGE_READY=true  
PRODUCTION_CRM_ENABLED=false  
REAL_CUSTOMER_CRM_OPEN=false  
AUTO_SALES_ACTION_ENABLED=false  
EXTERNAL_CRM_PROVIDER_ENABLED=false  
QUOTE_SALES_FLOW_REQUIRED_NEXT=true  
NEXT_GATE=FAZ_5_18_6_3_TEKLIF_SATIS_AKISI
