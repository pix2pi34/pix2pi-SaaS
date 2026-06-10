# Customer Login Unlock Passive Bridge Fix Audit

## Problem

Previous approved-error suppressor intercepted submit/click and locked the login page.
User reported:
- "sayfayı kitliyor"
- "mail kodu göndermiyor"

## Fix

- Removed locking approved-error suppressor script.
- Installed passive approval bridge.
- Passive bridge does not call preventDefault.
- Passive bridge does not call stopPropagation.
- Passive bridge does not call stopImmediatePropagation.
- Mail code button click is allowed to continue.
- Wrong not-registered message is only replaced after frontend/backend response.

## Important Runtime Rule

Approval alone does not create tenant/user.
If tenant/user is not activated yet, real mail code sending may still fail from login backend.
That is expected until tenant activation step is implemented.

## Target email checked

- telliogluservet90@gmail.com

## Markers

- CUSTOMER_LOGIN_PASSIVE_APPROVAL_BRIDGE_UNLOCK_MARKER
- CUSTOMER_LOGIN_APPROVAL_STATUS_BRIDGE_MARKER
- OWNER_REGISTER_APPROVALS_ADMIN_MARKER
- REGISTER_APPROVAL_HANDOFF_MARKER

## Tests

- Status API service active: PASS
- Status API health: PASS
- Test email status API: PASS/WARN according to status
- Nginx test: PASS
- Nginx reload: PASS
- Passive marker grep: PASS
- Old lock marker removal: PASS/WARN
- React live index curl 200 marker: PASS
- Vue3 live index curl 200 marker: PASS
- External status API marker: PASS

## Counts

- PASS_COUNT=15
- FAIL_COUNT=0
- WARN_COUNT=0
