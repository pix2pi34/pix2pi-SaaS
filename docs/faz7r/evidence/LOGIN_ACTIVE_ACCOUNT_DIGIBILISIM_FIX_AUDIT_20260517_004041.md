# Login Active Account + Missing Digibilisim Fix Audit

## User Report

- SERVET / telliogluservet90@gmail.com appears ACTIVE but cannot login.
- digibilisim@gmail.com does not appear in Phoenix list.

## Fix

1. Ensured active login account for:
   - telliogluservet90@gmail.com
2. Verified mail-code route:
   - direct activation API
   - panel external activation API
3. Searched digibilisim@gmail.com in applications.
4. If missing, created PENDING application for:
   - digibilisim@gmail.com
   - company: Digi Bilişim
5. Verified Phoenix companies API contains both emails.

## Runtime

- Applications dir: /root/pix2pi/pix2pi-SaaS/web/customer-register/data/applications
- Login accounts dir: /root/pix2pi/pix2pi-SaaS/web/customer-login/data/accounts
- Mail codes dir: /root/pix2pi/pix2pi-SaaS/web/customer-login/data/mail-codes
- Activation API port: 9039
- Owner API port: 9037

## Markers

- CUSTOMER_LOGIN_ACTIVE_ACCOUNT_MARKER
- CUSTOMER_LOGIN_MAIL_CODE_MARKER
- CUSTOMER_REGISTER_PENDING_APPLICATION_MARKER
- OWNER_REGISTER_COMPANIES_LIST_MARKER
- OWNER_REGISTER_APPROVALS_ADMIN_MARKER

## Tests

- Activation API health: PASS
- Active email found in applications: PASS
- Active login account ensured: PASS
- Active status API: PASS
- Direct send mail code: PASS
- Panel send mail code: PASS
- Digibilisim search/create: PASS
- Owner companies API contains both emails: PASS
- Phoenix external companies API contains both emails: PASS

## Counts

- PASS_COUNT=17
- FAIL_COUNT=0
- WARN_COUNT=0
