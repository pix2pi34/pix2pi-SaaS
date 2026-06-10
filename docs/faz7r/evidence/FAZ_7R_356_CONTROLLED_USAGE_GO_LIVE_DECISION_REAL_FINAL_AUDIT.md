# FAZ 7-R / 356 CONTROLLED USAGE GO-LIVE DECISION REAL FINAL AUDIT

- PASS_COUNT=52
- FAIL_COUNT=0
- WARN_COUNT=0
- FINAL_STATUS=PASS
- DECISION_ID=go-live-356-20260513_074955
- DECISION_RESULT=GO_CONTROLLED_USAGE
- PUBLIC_LAUNCH_ALLOWED=false
- CONTROLLED_USAGE_ALLOWED=true

## Dependency gate SELECT
```
dependency_gates=9
dependency_gate_fail=0
```

## Runtime readiness SELECT
```
tenant_opened=1
tenant_default_language=1
owner_active=1
owner_role=1
cashier_active=1
cashier_role=1
branch_active=1
register_active=1
latest_355_smoke_pass=1
```

## Live route evidence
```json
{"ok": false, "error": "validation_error", "fields": {"tenant_id": "required", "user_id": "required"}}
{"ok": false, "error": "validation_error", "fields": {"tenant_id": "required", "user_id": "required", "store_id": "required", "register_id": "required"}}
{"ok": false, "error": "validation_error", "fields": {"tenant_id": "required", "user_id": "required", "action_code": "required"}}
{"ok": false, "error": "validation_error", "fields": {"actor_tenant_id": "required", "target_tenant_id": "required", "actor_user_id": "required"}}
I18N_CODE=200
```

## Decision page route
```
DECISION_PAGE_CODE=200
```

## Risk SELECT
```
risk_count=5
risk_blockers=0
public_launch_scope=false
```

## Rollback SELECT
```
rollback_gate=0
```

## Gate final SELECT
```
gate_total=17
gate_fail=0
risk_blocker_final=0
```

## Decision final SELECT
```
decision_final=go-live-356-20260513_074955|GO_CONTROLLED_USAGE|true|false|true
decision_audit=1
```

## Check log
```
dependency PASS evidence: FAZ_7R_319_347_REAL_DB_API_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_348_REAL_FINAL_V2_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_321_USER_ROLE_PERSONNEL_RBAC_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_350_PANEL_ACCESS_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_351_POS_ACCESS_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_352_TENANT_ISOLATION_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_353_USER_PERMISSION_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_354_LOCALIZATION_CUSTOMER_SMOKE_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_355_FIRST_REAL_USAGE_SMOKE_FINAL_AUDIT.md / OK ✅
Postgres connection detected: docker/pix2pi_pg/pix2pi / OK ✅
REAL_DB_MIGRATION_APPLIED / OK ✅
table exists: controlled_release.go_live_decision_audit_events / OK ✅
table exists: controlled_release.go_live_decisions / OK ✅
table exists: controlled_release.go_live_gate_checks / OK ✅
table exists: controlled_release.go_live_risk_register / OK ✅
decision draft created / OK ✅
REAL_DB_SELECT_STATUS decision_draft=1 / OK ✅
dependency gates inserted into DB / OK ✅
DEPENDENCY_GATE_STATUS 9 pass / OK ✅
DEPENDENCY_GATE_STATUS fail=0 / OK ✅
RUNTIME_READINESS_STATUS tenant_opened=1 / OK ✅
RUNTIME_READINESS_STATUS tenant_default_language=1 / OK ✅
RUNTIME_READINESS_STATUS owner_active=1 / OK ✅
RUNTIME_READINESS_STATUS owner_role=1 / OK ✅
RUNTIME_READINESS_STATUS cashier_active=1 / OK ✅
RUNTIME_READINESS_STATUS cashier_role=1 / OK ✅
RUNTIME_READINESS_STATUS branch_active >= 1 / OK ✅
RUNTIME_READINESS_STATUS register_active >= 1 / OK ✅
RUNTIME_READINESS_STATUS latest_355_smoke_pass >= 1 / OK ✅
runtime readiness gates inserted / OK ✅
LIVE_ROUTE_STATUS panel access API 422 / OK ✅
LIVE_ROUTE_STATUS POS access API 422 / OK ✅
LIVE_ROUTE_STATUS permission API 422 / OK ✅
LIVE_ROUTE_STATUS tenant isolation API 422 / OK ✅
LIVE_ROUTE_STATUS i18n runtime HTTP 200 / OK ✅
live route gates inserted / OK ✅
decision page written / OK ✅
DECISION_ROUTE_SMOKE_STATUS page marker / OK ✅
decision page gate inserted / OK ✅
risk register inserted / OK ✅
RISK_REGISTER_STATUS risk_count=5 / OK ✅
RISK_REGISTER_STATUS blockers=0 / OK ✅
PUBLIC_LAUNCH_SCOPE_STATUS false controlled only / OK ✅
ROLLBACK_STATUS simulated DB failure occurred / OK ✅
TRANSACTION_STATUS rollback no partial write / OK ✅
FINAL_GATE_STATUS gate_total >= 17 / OK ✅
FINAL_GATE_STATUS gate_fail=0 / OK ✅
FINAL_GATE_STATUS risk_blocker_final=0 / OK ✅
GO_LIVE_DECISION_STATUS GO_CONTROLLED_USAGE / OK ✅
REAL_DB_SELECT_STATUS decision GO controlled usage / OK ✅
REAL_DB_SELECT_STATUS decision_audit=1 / OK ✅
config semantic validation / OK ✅
```
