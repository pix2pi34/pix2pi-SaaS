# Digibilisim Customer Login Activate Audit

## Problem

Login page showed:
- "digibilisim@gmail.com"
- "Başvurunuz onaylandı. Pix2pi aktivasyonu bekleniyor."

Meaning:
- Application existed or was approved
- But customer login account was not ACTIVE
- Therefore mail code could not be sent

## Fix

- Ensured application status ACTIVE for digibilisim@gmail.com
- Created/updated active login account
- Enabled login_allowed=true
- Enabled mail_code_allowed=true
- Verified mail code API returns test code 123

## Tests

- Local activation status: PASS
- Local send mail code: PASS
- Panel external status: PASS
- Panel external send mail code: PASS
- Phoenix companies contains email: PASS

## Expected Browser Result

- digibilisim@gmail.com shows: Hesabınız aktif. Mail kodu gönderilebilir.
- Mail Kodu Gönder returns: Mail kodu gönderildi. Test kodu: 123

## Counts

- PASS_COUNT=9
- FAIL_COUNT=0
- WARN_COUNT=0
