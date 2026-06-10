# Customer Register Submit Recovery + Navigation Fix Audit

## Problems

1. Previous submit smoke failed due to Bash history expansion:
   - event not found caused by "!" in inline JSON/password.
2. Customer login/register pages had no easy navigation:
   - no Ana Sayfa
   - no Giriş Yap
   - no Kayıt Ol

## Fix

- Disabled history expansion with set +H.
- Replaced unsafe inline JSON with payload files.
- Re-ran direct/local/external submit tests.
- Added customer auth navigation bar to:
  - customer-register React/Vue3
  - customer-login React/Vue3

## Runtime

- Submit service: pix2pi-customer-register-submit-api.service
- Submit port: 9040
- Data dir: /root/pix2pi/pix2pi-SaaS/web/customer-register/data/applications
- Nginx snippet: /etc/nginx/snippets/pix2pi_customer_register_submit_locations.conf

## Markers

- CUSTOMER_REGISTER_LIVE_SUBMIT_API_MARKER
- CUSTOMER_REGISTER_LIVE_SUBMIT_FRONTEND_BRIDGE_MARKER
- CUSTOMER_REGISTER_PENDING_APPLICATION_MARKER
- PIX2PI_CUSTOMER_AUTH_NAV_BAR_MARKER
- OWNER_REGISTER_APPROVALS_ADMIN_MARKER

## Tests

- Submit API syntax: PASS
- Submit API service active: PASS
- Submit API health: PASS
- nginx -t: PASS
- nginx reload: PASS
- direct submit creates PENDING: PASS
- panel local submit creates PENDING: PASS
- panel external submit creates PENDING: PASS
- register React submit/nav marker: PASS
- register Vue3 submit/nav marker: PASS
- login React nav marker: PASS
- login Vue3 nav marker: PASS
- PENDING_COUNT=3
- Owner API pending visibility: PASS

## Smoke emails

- direct: register-submit-recovery-20260517_001853@pix2pi.local
- panel local: register-submit-local-recovery-20260517_001853@pix2pi.local
- panel external: register-submit-external-recovery-20260517_001853@pix2pi.local

## Counts

- PASS_COUNT=21
- FAIL_COUNT=0
- WARN_COUNT=0
