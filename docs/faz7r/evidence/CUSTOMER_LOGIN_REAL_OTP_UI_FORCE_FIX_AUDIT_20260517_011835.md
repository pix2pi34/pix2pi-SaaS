# Customer Login Real OTP UI Force Fix Audit

## Problem

Backend sent real email successfully, but frontend still showed old test message:
- "Mail kodu gönderildi. Test kodu: 123"
And OTP input page did not appear.

## Fix

- Removed old injected login bridge scripts.
- Added force real OTP UI bridge.
- Captures Mail Kodu Gönder before old test handler.
- Calls real API:
  - /customer-login/activation-api/send-mail-code
- Shows OTP input immediately for ACTIVE accounts.
- Verifies code through:
  - /customer-login/activation-api/verify-mail-code
- Hides old Test kodu / Test şifresi UI text.

## Target

- digibilisim@gmail.com

## Tests

- API real mail health: PASS
- nginx -t: PASS
- nginx reload: PASS
- React marker: PASS
- Vue3 marker: PASS
- target ACTIVE + real mail enabled: PASS
- real mail send returns MAIL_CODE_SENT_REAL: PASS
- response has no test_code: PASS
- verify endpoint bad-code rejection: PASS

## Counts

- PASS_COUNT=11
- FAIL_COUNT=0
- WARN_COUNT=0
