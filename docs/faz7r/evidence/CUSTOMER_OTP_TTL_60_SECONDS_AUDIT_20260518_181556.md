# Customer OTP TTL 60 Seconds Audit

## Amaç

OTP/mail kodu geçerlilik süresini 60 saniyeye ayarlamak.

## Yeni ayar

- OTP TTL: 60 saniye
- Systemd env: PIX2PI_OTP_TTL_SECONDS=60
- Mail metni: 60 saniye
- Login UI / geri sayım metni: 60 saniye

## Test

- API health HTTP: 200
- request-login-code HTTP: 200
- immediate verify HTTP: 200
- expired verify after 63 seconds HTTP: 401
- login page HTTP: 200

## Beklenen güvenlik davranışı

- 60 saniye içinde kod doğrulanır.
- 60 saniye geçince kod INVALID_OR_EXPIRED_CODE döner.

## Backup

/root/pix2pi/pix2pi-SaaS/backups/customer-otp-ttl-60-seconds/20260518_181556

## Counts

PASS_COUNT=10
FAIL_COUNT=0
WARN_COUNT=0
