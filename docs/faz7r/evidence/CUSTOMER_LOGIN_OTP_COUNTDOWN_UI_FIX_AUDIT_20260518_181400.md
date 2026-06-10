# Customer Login OTP Countdown UI Fix Audit

## Amaç

OTP kod giriş kutusunda 40 saniyelik süreyi görünür yapmak.

## Yapılanlar

- Kod kutusuna "Kod süresi" geri sayımı eklendi.
- Kod gönderilince sayaç 40 saniyeden başlar.
- Son 10 saniyede uyarı stili uygulanır.
- Süre bitince kod inputu ve doğrulama butonu kilitlenir.
- Kod doğrulanınca sayaç "Kod doğrulandı" durumuna geçer.

## Test

- customer-login.html HTTP: 200
- marker: PIX2PI_OTP_COUNTDOWN_UI_MARKER
- TTL: 40 saniye

## Backup

/root/pix2pi/pix2pi-SaaS/backups/customer-login-otp-countdown-ui-fix/20260518_181400

## Counts

PASS_COUNT=4
FAIL_COUNT=0
WARN_COUNT=0
