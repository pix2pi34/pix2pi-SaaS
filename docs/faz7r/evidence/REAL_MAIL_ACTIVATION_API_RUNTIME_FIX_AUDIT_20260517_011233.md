# Real Mail Activation API Runtime Fix Audit

## Problem

Env file was correct, but health response still came from old activation API runtime:
- no real_mail_enabled
- no resend_key_present
- old mail marker: CUSTOMER_LOGIN_MAIL_CODE_MARKER

## Fix

- Rewrote customer-login activation API server.js to real Resend OTP runtime.
- Ensured systemd EnvironmentFile loads mail env.
- Ensured Nginx routes include send-mail-code and verify-mail-code.
- Restarted service and Nginx.
- Sent real mail to target email.

## Target

- digibilisim@gmail.com

## Tests

- Node syntax: PASS
- Service active: PASS
- nginx -t: PASS
- health real_mail_enabled=true: PASS
- health resend_key_present=true: PASS
- target ACTIVE: PASS
- real mail send: PASS
- test_code removed: PASS
- verify bad code rejected: PASS
- OTP raw code not stored: PASS

## Files

- API: /root/pix2pi/pix2pi-SaaS/services/customer-login-activation-api/server.js
- Env: /root/pix2pi/secrets/customer-login-mail.env
- Service: /etc/systemd/system/pix2pi-customer-login-activation-api.service
- Nginx snippet: /etc/nginx/snippets/pix2pi_customer_login_activation_locations.conf
- Mail record: /root/pix2pi/pix2pi-SaaS/web/customer-login/data/mail-codes/50e203bb2385627553a7d59ab329aebab6ad6a198ff85b08820fc38d36e0d964.json

## Counts

- PASS_COUNT=17
- FAIL_COUNT=0
- WARN_COUNT=0
