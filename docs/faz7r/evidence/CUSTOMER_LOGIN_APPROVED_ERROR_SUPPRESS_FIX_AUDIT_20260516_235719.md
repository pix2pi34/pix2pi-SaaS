# Customer Login Approved Error Suppress Fix Audit

## Problem

Approved application status bridge was working and showing the green message:
- "Başvurunuz onaylandı. Pix2pi aktivasyon/tenant açılışı tamamlanınca giriş açılacak."

But old login frontend still displayed:
- "Bu e-posta sistemde tanımlı değil."

## Fix

- Added approved error suppressor script to customer-login React/Vue3 live and repo index files.
- Suppresses old not-registered error when application status is APPROVED/PENDING/REJECTED.
- Intercepts submit/click for login/mail-code button when login_allowed=false.
- Keeps tenant create disabled.
- Keeps approval handoff behavior.

## Target email checked

- telliogluservet90@gmail.com

## Markers

- CUSTOMER_LOGIN_APPROVED_ERROR_SUPPRESS_FIX_MARKER
- CUSTOMER_LOGIN_APPROVAL_STATUS_BRIDGE_MARKER
- OWNER_REGISTER_APPROVALS_ADMIN_MARKER
- REGISTER_APPROVAL_HANDOFF_MARKER

## Tests

- Status API service active: PASS
- Status API health: PASS
- Test email status API: PASS/WARN according to returned status
- Nginx test: PASS
- Nginx reload: PASS
- Frontend marker grep: PASS
- React live index curl 200 marker: PASS
- Vue3 live index curl 200 marker: PASS
- External status API marker: PASS
- Runtime suppressor semantic checks: PASS

## Counts

- PASS_COUNT=13
- FAIL_COUNT=0
- WARN_COUNT=1
