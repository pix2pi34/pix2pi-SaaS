# FAZ 1-3.7 — Partner / Customer / Vendor Cross-company Relation Modeli

## Kapsam

- Partner relation
- Customer/vendor relation
- Cross-company visibility
- Relation audit
- Tests

## Uygulama

Bu adım org.cross_company_relations tablosunu kurar.

Desteklenen relation_type:
- PARTNER
- CUSTOMER
- VENDOR
- CUSTOMER_VENDOR
- STRATEGIC_PARTNER
- ACCOUNTANT_CLIENT
- OTHER

Ana guard'lar:
- counterparty_entity_id veya counterparty_external_ref zorunlu
- self-relation engellenir
- CUSTOMER için is_customer=true zorunlu
- VENDOR için is_vendor=true zorunlu
- PARTNER/STRATEGIC_PARTNER için is_partner=true zorunlu
- CUSTOMER_VENDOR için is_customer=true ve is_vendor=true zorunlu
- CROSS_COMPANY_VISIBLE için cross_company_visibility_allowed=true ve visibility_rule_id veya approval_ref zorunlu
- TERMINATED/ARCHIVED için lifecycle_reason ve relation_audit_ref zorunlu

## Final Status

- FAZ_1_3_7_PARTNER_RELATION_STATUS=PASS
- FAZ_1_3_7_CUSTOMER_VENDOR_RELATION_STATUS=PASS
- FAZ_1_3_7_CROSS_COMPANY_VISIBILITY_STATUS=PASS
- FAZ_1_3_7_RELATION_AUDIT_STATUS=PASS
- FAZ_1_3_7_RELATION_FINAL_STATUS=PASS
- FAZ_1_3_7_RELATION_SEAL_STATUS=SEALED
