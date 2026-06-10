# Customer Login Password Check + OTP Mail Fix Audit

## Amaç

- Mail Kodu Gönder butonunda önce şifre kontrolü yapmak.
- Şifre yanlışsa mail göndermemek.
- Şifre doğruysa 6 haneli OTP üretmek ve mail göndermek.
- Şifremi unuttum akışında e-postaya 6 haneli kod göndermek.
- Mail transport yoksa kodu outbox'a yazıp açık uyarı vermek.

## Servis

- Service: pix2pi-customer-login-otp-api.service
- Port: 9044
- API:
  - /customer-login/api/request-login-code
  - /customer-login/api/forgot-password-code
  - /customer-login/api/verify-code
  - /customer-login/api/health

## Mail

- Detected transport: sendmail
- Outbox dir: /root/pix2pi/pix2pi-SaaS/var/mail-outbox

## Test

- API health: 200
- wrong password response: 401
- correct password response: 200
- forgot password response: 200
- panel API route: 200
- login page: 200

## Güvenlik davranışı

- INVALID_PASSWORD durumunda mail_sent=false
- Doğru şifrede OTP üretilir.
- Forgot password için 6 haneli OTP üretilir.
- OTP hash olarak saklanır; mail gövdesi outbox .eml dosyasında tutulur.

## Backup

/root/pix2pi/pix2pi-SaaS/backups/customer-login-password-check-otp-mail-fix/20260518_081841

## Counts

PASS_COUNT=16
FAIL_COUNT=0
WARN_COUNT=0
