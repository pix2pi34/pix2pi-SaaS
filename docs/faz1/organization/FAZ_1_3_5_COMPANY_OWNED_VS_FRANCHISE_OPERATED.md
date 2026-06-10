# FAZ 1-3.5 — Company-owned branch vs franchise-operated store ayrımı

## Kapsam

- Ownership type
- Operation type
- Reporting effect
- Permission effect
- Test

## Uygulama

Bu adım org.location_operation_profiles tablosunu kurar.

Model ayrımları:
- COMPANY_BRANCH
- FRANCHISE_STORE
- PARTNER_STORE
- HYBRID_OPERATION
- OTHER

Company-owned branch kuralı:
- ownership_type = COMPANY_OWNED
- operation_type = COMPANY_OPERATED
- reporting_effect = CONSOLIDATED
- permission_effect = INTERNAL_FULL_SCOPE
- franchise_agreement_id boş olmalı

Franchise-operated store kuralı:
- operation_type = FRANCHISE_OPERATED
- franchise_agreement_id zorunlu
- reporting_effect = FRANCHISE_REVENUE_SHARE veya FRANCHISE_SEPARATE_BOOKS
- permission_effect = FRANCHISE_OPERATOR_SCOPE

## Final Status

- FAZ_1_3_5_OWNERSHIP_TYPE_STATUS=PASS
- FAZ_1_3_5_OPERATION_TYPE_STATUS=PASS
- FAZ_1_3_5_REPORTING_EFFECT_STATUS=PASS
- FAZ_1_3_5_PERMISSION_EFFECT_STATUS=PASS
- FAZ_1_3_5_COMPANY_BRANCH_RULE_STATUS=PASS
- FAZ_1_3_5_FRANCHISE_STORE_RULE_STATUS=PASS
- FAZ_1_3_5_OPERATION_PROFILE_FINAL_STATUS=PASS
- FAZ_1_3_5_OPERATION_PROFILE_SEAL_STATUS=SEALED
