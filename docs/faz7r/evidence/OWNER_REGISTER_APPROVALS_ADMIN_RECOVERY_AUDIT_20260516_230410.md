# Owner Register Approvals Admin Recovery Audit

## Fix

- npm package invalid tag fixed
- removed invalid ^latest
- used valid latest dist-tag
- npm run dev not added

## Route

- panel.pix2pi.com.tr/owner-panel/register-approvals/

## Rules

- customer_visible=false
- owner_only=true
- pending_only=true
- approve_status=APPROVED
- reject_status=REJECTED
- tenant_create_real_create=false
- approval_handoff=true

## Markers

- OWNER_REGISTER_APPROVALS_ADMIN_MARKER
- PIX2PI_OWNER_APPROVAL_RUNTIME
- REGISTER_APPROVAL_HANDOFF_MARKER

## Tests

- npm install: PASS
- npm run build: PASS
- API service active: PASS
- nginx -t: PASS
- nginx reload: PASS
- index curl 200 marker: PASS
- pending list curl: PASS
- approve file mutation: PASS
- reject file mutation: PASS
- pending filter: PASS
- basic auth 401 guard: PASS

## Counts

- PASS_COUNT=23
- FAIL_COUNT=0
- WARN_COUNT=0
