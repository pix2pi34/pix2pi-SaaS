# FAZ 5-R / 266 — FAZ 5-18.6.3 Teklif / Satış Akışı

## Amaç

Bu adım, CRM stage hattından gelen fırsatların teklif ve satış akışına dönüşmesini commercial ops contract seviyesinde hazırlar.

Bu çalışma production satış, gerçek müşteri satış operasyonu, otomatik teklif gönderimi veya otomatik sözleşme/tenant aktivasyonu açmaz. Amaç; teklif talebi, CRM stage doğrulama, müşteri profili, fiyat snapshot, iskonto onayı, teklif taslağı, ticari şart incelemesi, teklif onayı ve won handoff akışlarını tenant-safe, consent/KVKK uyumlu ve audit edilebilir hale getirmektir.

## Kapsam

1. quote_request_intake
2. crm_stage_verify
3. customer_profile_validate
4. pricing_snapshot_attach
5. discount_approval_queue
6. proposal_draft_create
7. commercial_terms_review
8. quote_approval_record
9. sales_won_handoff
10. sales_ops_report_deferred_marker

## Kritik kurallar

- Production sales kapalı kalır.
- Real customer sales open kapalı kalır.
- Auto quote send kapalı kalır.
- Auto contract activation kapalı kalır.
- tenant_id zorunludur.
- lead_id zorunludur.
- quote_id zorunludur.
- CRM stage zorunludur.
- customer profile zorunludur.
- pricing snapshot zorunludur.
- plan snapshot zorunludur.
- discount approval zorunludur.
- commercial terms zorunludur.
- owner approval zorunludur.
- audit trail zorunludur.
- consent check zorunludur.
- KVKK notice zorunludur.
- validity window zorunludur.
- rollback path zorunludur.
- onboarding handoff zorunludur.

## Final policy

INTERNAL_QUOTE_SALES_FLOW_READY=true  
PRODUCTION_SALES_ENABLED=false  
REAL_CUSTOMER_SALES_OPEN=false  
AUTO_QUOTE_SEND_ENABLED=false  
AUTO_CONTRACT_ACTIVATION_ENABLED=false  
SALES_OPS_REPORT_REQUIRED_NEXT=true  
NEXT_GATE=FAZ_5_18_6_4_SALES_OPS_RAPORU
