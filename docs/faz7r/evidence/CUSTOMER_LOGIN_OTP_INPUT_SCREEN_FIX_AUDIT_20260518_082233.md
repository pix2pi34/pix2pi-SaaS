# Customer Login OTP Input Screen Fix Audit

## Amaç

Mail kodu gönderildikten sonra kullanıcıya 6 haneli kodu gireceği ekranı göstermek.

## Yapılanlar

- Login sayfasına OTP input paneli eklendi.
- Kodu Doğrula butonu eklendi.
- /customer-login/api/verify-code endpointine bağlandı.
- Başarılı login doğrulamasında /customer-panel.html yönlendirmesi eklendi.
- Outbox kodu ile gerçek API verify testi yapıldı.

## Test

- customer-login.html HTTP: 200
- request-login-code HTTP: 200
- verify-code HTTP: 200
- OTP input marker: PIX2PI_LOGIN_OTP_INPUT_SCREEN_MARKER

## Backup

/root/pix2pi/pix2pi-SaaS/backups/customer-login-otp-input-screen-fix/20260518_082233

## Counts

PASS_COUNT=6
FAIL_COUNT=0
WARN_COUNT=0
