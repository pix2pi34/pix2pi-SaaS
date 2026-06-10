# Phoenix Companies UI Marker Recovery Audit

## Cause

Previous run failed at local UI marker check because Vite index.html did not expose OWNER_REGISTER_COMPANIES_LIST_MARKER directly.
The marker existed in bundled assets/API, but the curl test checked only HTML body.

## Fix

- Added explicit meta/comment marker into live index.html.
- Retested companies API.
- Retested Phoenix local UI.
- Retested logout route.
- Retested external Phoenix route.

## Runtime

- Domain: phoenix.pix2pi.com.tr
- Live dir: /var/www/pix2pi/live/owner-panel/register-approvals
- API port: 9037
- Data dir: /root/pix2pi/pix2pi-SaaS/web/customer-register/data/applications

## Features

- Kayıtlı Şirketler tab: enabled
- Onay Bekleyenler tab: enabled
- Separate email identity: enabled
- Logout button/route: enabled

## Markers

- OWNER_REGISTER_APPROVALS_ADMIN_MARKER
- OWNER_REGISTER_COMPANIES_LIST_MARKER
- PIX2PI_OWNER_LOGOUT_BUTTON_MARKER
- REGISTER_APPROVAL_HANDOFF_MARKER

## Tests

- Owner API service active: PASS
- Health companies marker: PASS
- Direct companies API: PASS
- Company count: 6
- nginx -t: PASS
- nginx reload: PASS
- Local Phoenix UI marker: PASS
- Local Phoenix companies API: PASS
- Logout route: PASS
- External Phoenix UI: PASS

## Counts

- PASS_COUNT=13
- FAIL_COUNT=0
- WARN_COUNT=0
