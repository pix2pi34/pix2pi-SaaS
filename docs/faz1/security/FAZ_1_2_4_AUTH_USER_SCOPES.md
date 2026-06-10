# FAZ 1-2.4 Auth User Scopes Model

## Kapsam

- Tenant scope
- Legal entity scope
- Branch scope
- Accountant assigned-company scope
- Scope expiration
- Scope audit

## Strict Reseal

Bu strict reseal adımı auth.user_scopes ve auth.user_scope_audit tablolarını, RLS/forced RLS/policy kapsamını, runtime function setini, DB kolonlarını ve repo izlerini doğrular.

## Final Status

- FAZ_1_2_4_TENANT_SCOPE_STATUS=PASS
- FAZ_1_2_4_LEGAL_ENTITY_SCOPE_STATUS=PASS
- FAZ_1_2_4_BRANCH_SCOPE_STATUS=PASS
- FAZ_1_2_4_ACCOUNTANT_ASSIGNED_COMPANY_SCOPE_STATUS=PASS
- FAZ_1_2_4_SCOPE_EXPIRATION_STATUS=PASS
- FAZ_1_2_4_SCOPE_AUDIT_STATUS=PASS
- FAZ_1_2_4_AUTH_USER_SCOPES_SEAL_STATUS=SEALED
