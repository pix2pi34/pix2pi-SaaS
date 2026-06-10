# FAZ 1-3.6 — Entity / Branch Visibility Rules Veri Modeli

## Kapsam

- Entity visibility
- Branch visibility
- Role-based visibility
- Accountant visibility
- Cross-branch tests

## Uygulama

Bu adım org.visibility_rules tablosunu kurar.

Desteklenen subject tipleri:
- USER
- ROLE
- LEGAL_ENTITY
- ACCOUNTANT
- SYSTEM

Desteklenen visibility scope:
- GLOBAL
- ENTITY
- BRANCH
- LOCATION
- ACCOUNTANT
- ROLE

Branch görünürlük modeli:
- NO_BRANCH
- ALL_BRANCHES
- SPECIFIC_BRANCH
- CROSS_BRANCH

Kritik guard'lar:
- ENTITY scope için target_entity_id zorunlu
- ROLE subject için subject_role zorunlu
- ACCOUNTANT subject için accountant_entity_id zorunlu
- ACCOUNTANT permission delete alamaz
- SPECIFIC_BRANCH için target_branch_id zorunlu
- CROSS_BRANCH_READ / CROSS_BRANCH_WRITE için approval_ref zorunlu
- CROSS_BRANCH_WRITE için can_update=true ve access_level WRITE/ADMIN zorunlu

## Final Status

- FAZ_1_3_6_ENTITY_VISIBILITY_STATUS=PASS
- FAZ_1_3_6_BRANCH_VISIBILITY_STATUS=PASS
- FAZ_1_3_6_ROLE_BASED_VISIBILITY_STATUS=PASS
- FAZ_1_3_6_ACCOUNTANT_VISIBILITY_STATUS=PASS
- FAZ_1_3_6_CROSS_BRANCH_TEST_STATUS=PASS
- FAZ_1_3_6_VISIBILITY_RULES_FINAL_STATUS=PASS
- FAZ_1_3_6_VISIBILITY_RULES_SEAL_STATUS=SEALED
