# 169 — FAZ 3-12.2 — Company Switcher Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=95
- FAIL_COUNT=0
- WARN_COUNT=0
- REQUIRED_FAIL=0
- FAZ_3_12_2_COMPANY_SWITCHER_FINAL_STATUS=PASS
- FAZ_3_12_2_COMPANY_SWITCHER_SEAL_STATUS=SEALED
- FAZ_3_12_3_READY=YES

## Scope

- Company switcher visibility
- Current firm context visibility
- Authorized company list visibility
- Switch decision visibility
- Active context visibility
- Tenant boundary visibility
- Firm scope visibility
- Context token visibility
- Target/export/finance route visibility
- Permission and subscription visibility
- Switch allowed / review / blocked coverage
- Permission view / export / manage / read only coverage
- Tenant boundary hash / firm scope hash / context hash / permission hash / audit hash traces
- Evidence file trace

## Live Policy

- Cross tenant access: CLOSED
- Accountant authorization required: TRUE
- Firm scope required: TRUE
- Context token required: TRUE
- Switch audit required: TRUE
- Production approved: FALSE
- UI actions are switch/validate/route/audit only.

## Audit Notes

Final status is derived from real screen/config/doc files and audit counters.
Hardcoded OK evidence is not accepted.
