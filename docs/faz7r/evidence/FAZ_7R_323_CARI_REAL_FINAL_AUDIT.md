# FAZ 7-R / 323 CARI REAL FINAL AUDIT

- PASS_COUNT=56
- FAIL_COUNT=0
- WARN_COUNT=0
- FINAL_STATUS=PASS

## Readiness SELECT
```
tenant_opened=1
owner_active=1
owner_role=1
tenant_b_opened=1
tenant_b_owner_role=1
no_role_count=0
```
## Create response
```json
{"ok": true, "party_id": "party-323-customer-a", "tenant_id": "tenant-api-e2e-success", "party_code": "CARI-323-001", "party_type": "customer", "current_balance": 1250.75}
```
## Create SELECT
```
party_created=1
opening_movement=1
create_audit=1
```
## Supplier response
```json
{"ok": true, "party_id": "party-323-supplier-a", "tenant_id": "tenant-api-e2e-success", "party_code": "TED-323-001", "party_type": "supplier", "current_balance": 0.0}
```
## Supplier list
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "count": 1, "items": [{"party_id": "party-323-supplier-a", "party_code": "TED-323-001", "party_type": "supplier", "display_name": "323 Test Tedarikçi Ltd", "tax_identity": "9100000002", "current_balance": "0.00"}]}
```
## Duplicate response
```json
{"ok": false, "error": "duplicate_record", "detail": "ERROR:  duplicate key value violates unique constraint \"ux_erp_party_tenant_country_tax\"\nDETAIL:  Key (tenant_id, country, lower(tax_identity))=(tenant-api-e2e-success, TR, 9100000001) already exists.\n"}
```
## Duplicate SELECT
```
duplicate_party=0
duplicate_movement=0
duplicate_audit=0
```
## Update response
```json
{"ok": true, "party_id": "party-323-customer-a", "tenant_id": "tenant-api-e2e-success", "updated": true}
```
## Update SELECT
```
party_updated=1
update_audit=1
```
## Movement response
```json
{"ok": true, "movement_id": "movement-4f8f884f-094e-40cb-b317-69380ac53dd1", "party_id": "party-323-customer-a", "tenant_id": "tenant-api-e2e-success", "balance_after": 1500.0}
```
## Movement SELECT
```
party_balance=1
movement_count=2
movement_audit=1
```
## List response
```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "count": 1, "items": [{"party_id": "party-323-customer-a", "party_code": "CARI-323-001", "party_type": "customer", "display_name": "323 Test Cari AŞ Güncel", "tax_identity": "9100000001", "current_balance": "1500.00"}]}
```
## No role response
```json
{"ok": false, "error": "actor_user_has_no_role"}
```
## Cross tenant response
```json
{"ok": false, "error": "cross_tenant_denied"}
```
## Cross tenant SELECT
```
tenant_b_unchanged=1
cross_bad_update=0
cross_deny_audit=1
```
## Rollback response
```json
{"ok": false, "error": "db_transaction_failed", "detail": "ERROR:  division by zero\n"}
```
## Rollback SELECT
```
rollback_party=0
rollback_movement=0
rollback_audit=0
```
## Final SELECT
```
tenant_a_parties=2
tenant_a_movements=3
tenant_a_audit=5
tenant_b_parties=1
```
## Check log
```
dependency PASS evidence: FAZ_7R_319_347_REAL_DB_API_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_350_PANEL_ACCESS_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_352_TENANT_ISOLATION_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_353_USER_PERMISSION_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_357_HELP_CENTER_REAL_FINAL_AUDIT.md / OK ✅
Postgres connection detected: docker/pix2pi_pg/pix2pi / OK ✅
REAL_DB_MIGRATION_APPLIED / OK ✅
table exists: erp_party.parties / OK ✅
table exists: erp_party.party_audit_events / OK ✅
table exists: erp_party.party_movements / OK ✅
API file written / OK ✅
REAL_API_ENDPOINT_STATUS / OK ✅
nginx route bind / OK ✅
party create route reaches API 422 / OK ✅
frontend parties page written / OK ✅
test cleanup and seed completed / OK ✅
READINESS_STATUS tenant_opened=1 / OK ✅
READINESS_STATUS owner_active=1 / OK ✅
READINESS_STATUS owner_role=1 / OK ✅
READINESS_STATUS tenant_b_opened=1 / OK ✅
READINESS_STATUS tenant_b_owner_role=1 / OK ✅
READINESS_STATUS no_role_count=0 / OK ✅
REAL_CURL_CREATE_STATUS HTTP 201 / OK ✅
REAL_DB_SELECT_STATUS party_created=1 / OK ✅
REAL_DB_SELECT_STATUS opening_movement=1 / OK ✅
REAL_DB_SELECT_STATUS create_audit=1 / OK ✅
SUPPLIER_CREATE_STATUS HTTP 201 / OK ✅
PARTY_TYPE_FILTER_STATUS supplier listed / OK ✅
DUPLICATE_CASE_STATUS HTTP 409 / OK ✅
PARTIAL_WRITE_STATUS duplicate blocked: duplicate_party=0 / OK ✅
PARTIAL_WRITE_STATUS duplicate blocked: duplicate_movement=0 / OK ✅
PARTIAL_WRITE_STATUS duplicate blocked: duplicate_audit=0 / OK ✅
REAL_CURL_UPDATE_STATUS HTTP 200 / OK ✅
REAL_DB_SELECT_STATUS party_updated=1 / OK ✅
REAL_DB_SELECT_STATUS update_audit=1 / OK ✅
REAL_CURL_MOVEMENT_STATUS HTTP 201 balance_after 1500 / OK ✅
REAL_DB_SELECT_STATUS party_balance=1 / OK ✅
REAL_DB_SELECT_STATUS movement_count=2 / OK ✅
REAL_DB_SELECT_STATUS movement_audit=1 / OK ✅
PARTY_LIST_SEARCH_STATUS HTTP 200 search found / OK ✅
NO_ROLE_DENY_STATUS HTTP 403 / OK ✅
TENANT_B_PARTY_CREATE_STATUS HTTP 201 / OK ✅
CROSS_TENANT_GUARD_STATUS update denied HTTP 403 / OK ✅
CROSS_TENANT_DB_STATUS tenant_b_unchanged=1 / OK ✅
CROSS_TENANT_DB_STATUS cross_bad_update=0 / OK ✅
CROSS_TENANT_DB_STATUS cross_deny_audit=1 / OK ✅
ROLLBACK_STATUS create HTTP 500 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_party=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_movement=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_audit=0 / OK ✅
ROUTE_SMOKE_STATUS /parties/ marker / OK ✅
FINAL_DB_STATUS tenant_a_parties >= 2 / OK ✅
FINAL_DB_STATUS tenant_a_movements >= 3 / OK ✅
FINAL_DB_STATUS tenant_a_audit >= 4 / OK ✅
FINAL_DB_STATUS tenant_b_parties=1 / OK ✅
config semantic validation / OK ✅
```
