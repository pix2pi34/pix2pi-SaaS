# Customer Login Unified Status Cleanup Fix Audit

## Problem

Login page showed duplicate/contradictory messages:
- Green old approval message
- Yellow activation message

Firefox also warned that the page was slowing down because multiple old MutationObserver-based bridge scripts were active.

## Fix

Removed old login bridge scripts:
- pix2pi-customer-login-approval-status-bridge
- pix2pi-customer-login-approved-error-suppress-fix
- pix2pi-customer-login-passive-approval-bridge-unlock
- pix2pi-customer-login-activation-frontend-bridge

Installed one unified bridge:
- pix2pi-customer-login-unified-status-bridge

## Unified Behavior

- ACTIVE: "Hesabınız aktif. Mail kodu gönderilebilir."
- ACTIVE + Mail Kodu Gönder: activation API sends test code 123
- APPROVED: "Başvurunuz onaylandı. Pix2pi aktivasyonu bekleniyor."
- PENDING: "Başvurunuz alındı. Pix2pi owner onayı bekleniyor."
- REJECTED: "Başvurunuz reddedildi."
- NOT_REGISTERED: no bridge message

## Tests

- nginx -t: PASS
- nginx reload: PASS
- old marker cleanup: PASS
- React login live marker: PASS
- Vue3 login live marker: PASS
- active status API JSON: PASS
- digibilisim application status API JSON: PASS

## Counts

- PASS_COUNT=10
- FAIL_COUNT=0
- WARN_COUNT=0
