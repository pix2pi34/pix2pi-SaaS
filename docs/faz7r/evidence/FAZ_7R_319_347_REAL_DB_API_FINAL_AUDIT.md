# FAZ 7-R / 319 + 347 REAL DB API FINAL AUDIT

Generated at: 20260512_195832

## Result

- PASS_COUNT=43
- FAIL_COUNT=0
- WARN_COUNT=0
- REQUIRED_FAIL=0
- OPTIONAL_WARN=0
- FINAL_STATUS=PASS

## Endpoint

- POST https://panel.pix2pi.com.tr/api/panel/onboarding/tenant-opening
- Local service: http://127.0.0.1:9319

## Migration evidence

```
tenant_onboarding.business_onboardings
tenant_onboarding.tenant_branches
tenant_onboarding.tenant_configs
tenant_onboarding.tenant_opening_audit_events
tenant_onboarding.tenant_registers
tenant_onboarding.tenant_user_roles
```

## Successful curl response

```json
{"ok": true, "tenant_id": "tenant-api-e2e-success", "tenant_slug": "api-e2e-success", "branch_id": "tenant-api-e2e-success-branch-main", "register_id": "tenant-api-e2e-success-register-main", "owner_user_id": "user-owner-e2e", "next_url": "/user-invite/?tenant_id=tenant-api-e2e-success"}
```

## Successful DB SELECT evidence

```
business_onboardings=1
tenant_configs=1
tenant_branches=1
tenant_registers=1
tenant_user_roles=1
audit_events=1
business_row=Test AŞ|9000000001|tr-TR|owner
config_row=api-e2e-success|pilot-free-controlled|tr-TR|opened
```

## Duplicate HTTP 409 response

```json
{"ok": false, "error": "duplicate_record", "detail": "DETAIL:  Key (country, tax_identity)=(TR, 9000000001) already exists."}
```

## Duplicate no partial DB SELECT evidence

```
duplicate_business=0
duplicate_config=0
duplicate_branch=0
duplicate_register=0
duplicate_role=0
duplicate_audit=0
```

## Validation HTTP 422 response

```json
{"ok": false, "error": "validation_error", "fields": {"business_name": "required"}}
```

## Validation no DB write evidence

```
validation_business=0
validation_config=0
```

## Rollback HTTP 500 response

```json
{"ok": false, "error": "db_transaction_failed", "detail": "ERROR:  division by zero\n"}
```

## Rollback no partial DB SELECT evidence

```
rollback_business=0
rollback_config=0
rollback_branch=0
rollback_register=0
rollback_role=0
rollback_audit=0
```

## Check log

```
backup directory prepared / OK ✅
required directories prepared / OK ✅
Postgres connection detected: docker / OK ✅
psql wrapper written / OK ✅
REAL_DB_MIGRATION_APPLIED / OK ✅
migration table exists: tenant_onboarding.business_onboardings / OK ✅
migration table exists: tenant_onboarding.tenant_configs / OK ✅
migration table exists: tenant_onboarding.tenant_branches / OK ✅
migration table exists: tenant_onboarding.tenant_registers / OK ✅
migration table exists: tenant_onboarding.tenant_user_roles / OK ✅
migration table exists: tenant_onboarding.tenant_opening_audit_events / OK ✅
real API file written / OK ✅
REAL_API_ENDPOINT_STATUS local service health / OK ✅
nginx config test status is PASS / OK ✅
nginx reloaded / OK ✅
live API route POST reaches API and returns validation 422 / OK ✅
frontend form bound to real POST API / OK ✅
test data cleanup completed / OK ✅
REAL_CURL_POST_STATUS success HTTP 201 / OK ✅
REDIRECT_STATUS next_url returned / OK ✅
REAL_DB_SELECT_STATUS business_onboardings=1 / OK ✅
REAL_DB_SELECT_STATUS tenant_configs=1 / OK ✅
REAL_DB_SELECT_STATUS tenant_branches=1 / OK ✅
REAL_DB_SELECT_STATUS tenant_registers=1 / OK ✅
REAL_DB_SELECT_STATUS tenant_user_roles=1 / OK ✅
REAL_DB_SELECT_STATUS audit_events=1 / OK ✅
DUPLICATE_CASE_STATUS HTTP 409 / OK ✅
PARTIAL_WRITE_STATUS duplicate blocked: duplicate_business=0 / OK ✅
PARTIAL_WRITE_STATUS duplicate blocked: duplicate_config=0 / OK ✅
PARTIAL_WRITE_STATUS duplicate blocked: duplicate_branch=0 / OK ✅
PARTIAL_WRITE_STATUS duplicate blocked: duplicate_register=0 / OK ✅
PARTIAL_WRITE_STATUS duplicate blocked: duplicate_role=0 / OK ✅
PARTIAL_WRITE_STATUS duplicate blocked: duplicate_audit=0 / OK ✅
VALIDATION_ERROR_STATUS HTTP 422 / OK ✅
VALIDATION_ERROR_STATUS no DB write / OK ✅
ROLLBACK_STATUS simulated failure returned HTTP 500 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_business=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_config=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_branch=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_register=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_role=0 / OK ✅
TRANSACTION_STATUS rollback no partial write: rollback_audit=0 / OK ✅
config semantic validation / OK ✅
```
