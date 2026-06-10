# 172 — FAZ 3-12.6 — Portal Audit History Real Implementation Audit

## Counter Based Final Status

- PASS_COUNT=128
- FAIL_COUNT=0
- WARN_COUNT=0
- REQUIRED_FAIL=0
- FAZ_3_12_6_PORTAL_AUDIT_HISTORY_FINAL_STATUS=PASS
- FAZ_3_12_6_PORTAL_AUDIT_HISTORY_SEAL_STATUS=SEALED
- FAZ_3_12_7_READY=YES

## Scope

- Portal audit history visibility
- Append-only audit visibility
- COMPANY_SWITCH / PERMISSION_DECISION / EXPORT_REQUEST / SUBSCRIPTION_VALIDATE / ACCESS_DECISION event coverage
- ALLOW / REVIEW_REQUIRED / DENY / READ_ONLY decision coverage
- Actor / tenant / firm / accountant visibility
- Correlation ID / request ID / idempotency key visibility
- IP hash / user agent hash visibility
- Before / after state hash visibility
- Event hash / scope hash / chain hash / evidence hash traces
- Evidence file trace
- Hash timeline
- Source screen coverage: company switcher, permission screen, export workspace, subscription status

## Live Policy

- Append-only audit required: TRUE
- Audit delete allowed: FALSE
- Audit mutation allowed: FALSE
- Cross tenant audit read allowed: FALSE
- Evidence hash required: TRUE
- Actor required: TRUE
- Correlation required: TRUE
- Production approved: FALSE
- UI actions are detail/verify/export/evidence only.

## Audit Notes

Final status is derived from real screen/config/doc files and audit counters.
Hardcoded OK evidence is not accepted.
