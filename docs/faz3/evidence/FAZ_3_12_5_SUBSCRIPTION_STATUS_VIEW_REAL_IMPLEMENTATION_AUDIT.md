# 171 — FAZ 3-12.5 — Subscription Status View Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=105
- FAIL_COUNT=0
- WARN_COUNT=0
- REQUIRED_FAIL=0
- FAZ_3_12_5_SUBSCRIPTION_STATUS_VIEW_FINAL_STATUS=PASS
- FAZ_3_12_5_SUBSCRIPTION_STATUS_VIEW_SEAL_STATUS=SEALED
- FAZ_3_12_6_READY=YES

## Scope

- Subscription status visibility
- Firm/accountant subscription visibility
- Monthly validation visibility
- Plan visibility
- ACTIVE / TRIAL / SUSPENDED / EXPIRED status coverage
- ACCOUNTANT_STARTER / ACCOUNTANT_PRO / ACCOUNTANT_ENTERPRISE plan coverage
- ACCESS_ALLOWED / READ_ONLY_ALLOWED / ACCESS_BLOCKED decision coverage
- Quota / firm limit / export quota visibility
- Renewal date / validation date visibility
- Billing mode visibility
- Subscription hash / quota hash / access hash / audit hash traces
- Evidence file trace
- Audit timeline

## Live Policy

- Real billing: CLOSED
- Real payment collection: CLOSED
- Real invoice issue: CLOSED
- Monthly validation required: TRUE
- Subscription access gate required: TRUE
- Quota hash required: TRUE
- Audit required: TRUE
- Production approved: FALSE
- UI actions are validate/quota/access/audit only.

## Audit Notes

Final status is derived from real screen/config/doc files and audit counters.
Hardcoded OK evidence is not accepted.
