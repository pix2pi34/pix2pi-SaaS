# 170 — FAZ 3-12.3 — Company Based Permission Screen Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=110
- FAIL_COUNT=0
- WARN_COUNT=0
- REQUIRED_FAIL=0
- FAZ_3_12_3_COMPANY_BASED_PERMISSION_SCREEN_FINAL_STATUS=PASS
- FAZ_3_12_3_COMPANY_BASED_PERMISSION_SCREEN_SEAL_STATUS=SEALED
- FAZ_3_12_5_READY=YES

## Scope

- Company permission matrix visibility
- Firm based role visibility
- VIEW / EXPORT / MANAGE / READ_ONLY permission visibility
- ALLOW / REVIEW_REQUIRED / DENY / READ_ONLY_ALLOW decision visibility
- ACCOUNTANT_MANAGER / ACCOUNTANT_EXPORTER / ACCOUNTANT_VIEWER / ACCOUNTANT_READ_ONLY role coverage
- Allowed / denied resources visibility
- Tenant boundary visibility
- Firm scope visibility
- Subscription status visibility
- Permission hash / decision hash / audit hash traces
- Evidence file trace
- Audit timeline

## Live Policy

- Cross tenant access: CLOSED
- Tenant boundary required: TRUE
- Firm scope required: TRUE
- Subscription status required: TRUE
- Permission hash required: TRUE
- Audit required: TRUE
- Production approved: FALSE
- UI actions are validate/scope/review/audit only.

## Audit Notes

Final status is derived from real screen/config/doc files and audit counters.
Hardcoded OK evidence is not accepted.
