# Customer OTP TTL 40 Seconds Audit

## Amaç

OTP/mail kodu geçerlilik süresini 10 dakikadan 40 saniyeye indirmek.

## Yeni ayar

- OTP TTL: 40 saniye
- Systemd env: PIX2PI_OTP_TTL_SECONDS=40
- Mail metni: 40 saniye
- Login UI metni: 40 saniye

## Test

- API health HTTP: 200
- request-login-code HTTP: 200
- immediate verify HTTP: 200
- expired verify after 43 seconds HTTP: 401
- login page HTTP: 200

## Beklenen güvenlik davranışı

- 40 saniye içinde kod doğrulanır.
- 40 saniye geçince kod INVALID_OR_EXPIRED_CODE döner.

## Backup

/root/pix2pi/pix2pi-SaaS/backups/customer-otp-ttl-40-seconds/20260518_180630

## Counts

PASS_COUNT=10
FAIL_COUNT=0
WARN_COUNT=0
