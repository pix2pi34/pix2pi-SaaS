# Customer Login Activation Audit

## Problem

Approval screen changed application status to APPROVED, but customer login could not send mail code because no active customer login account existed.

## Fix

- Added customer login activation API.
- Created active login account from APPROVED application.
- Added mail-code API for active account.
- Patched customer login frontend to use activation mail-code API for active accounts.
- Converted test email to ACTIVE:
  - telliogluservet90@gmail.com

## Runtime

- Activation API service: pix2pi-customer-login-activation-api.service
- Activation API port: 9039
- Applications dir: /root/pix2pi/pix2pi-SaaS/web/customer-register/data/applications
- Login accounts dir: /root/pix2pi/pix2pi-SaaS/web/customer-login/data/accounts
- Mail codes dir: /root/pix2pi/pix2pi-SaaS/web/customer-login/data/mail-codes

## Routes

- /customer-login/activation-api/health
- /customer-login/activation-api/status?email=EMAIL
- /customer-login/activation-api/activate
- /customer-login/activation-api/send-mail-code

## Markers

- CUSTOMER_LOGIN_ACTIVATION_API_MARKER
- CUSTOMER_LOGIN_ACTIVE_ACCOUNT_MARKER
- CUSTOMER_LOGIN_MAIL_CODE_MARKER
- CUSTOMER_LOGIN_ACTIVATION_FRONTEND_BRIDGE_MARKER
- REGISTER_APPROVAL_HANDOFF_MARKER

## Tests

- API syntax: PASS
- systemd active: PASS
- API health: PASS
- nginx -t: PASS
- nginx reload: PASS
- activate test email: PASS
- active status: PASS
- send mail code direct: PASS
- panel external active status: PASS
- panel external send mail code: PASS
- React frontend marker: PASS
- Vue3 frontend marker: PASS
- account file count: 1
- mail code file count: 1

## Counts

- PASS_COUNT=18
- FAIL_COUNT=0
- WARN_COUNT=0
