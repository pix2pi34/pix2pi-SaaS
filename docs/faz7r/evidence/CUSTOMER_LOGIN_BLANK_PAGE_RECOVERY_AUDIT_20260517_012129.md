# Customer Login Blank Page Recovery Audit

## Problem

Customer login page came blank after frontend bridge patches.

## Recovery

Replaced live customer-login React/Vue3 index pages with standalone HTML login screen that does not depend on broken React/Vite bundle.

## Features

- E-posta + şifre formu
- Mail Kodu Gönder button
- Real Resend OTP integration
- 6-digit OTP input
- Kodu Doğrula ve Giriş Yap button
- Kayıt Ol link
- Ana Sayfa link
- Test code 123 removed

## Routes

- /customer-login/react/
- /customer-login/vue3/
- /customer-login/activation-api/status
- /customer-login/activation-api/send-mail-code
- /customer-login/activation-api/verify-mail-code

## Markers

- CUSTOMER_LOGIN_STANDALONE_REAL_OTP_MARKER
- CUSTOMER_LOGIN_REAL_MAIL_CODE_MARKER
- CUSTOMER_LOGIN_MAIL_CODE_VERIFY_MARKER

## Tests

- Real mail API health: PASS
- Deploy React/Vue3 standalone login: PASS
- nginx -t: PASS
- nginx reload: PASS
- React live HTTP 200: PASS
- React marker: PASS
- React has verify UI: PASS
- React has no Test kodu 123: PASS
- Vue3 live HTTP 200: PASS
- Vue3 marker: PASS
- Status route real_mail_enabled=true: PASS
- Verify route reachable: PASS

## Counts

- PASS_COUNT=12
- FAIL_COUNT=0
- WARN_COUNT=0
