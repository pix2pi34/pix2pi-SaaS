# Pix2pi public root route bridge live audit

Generated at: 20260511_080525

## Result

- PASS_COUNT=23
- FAIL_COUNT=1
- WARN_COUNT=0
- REQUIRED_FAIL=1
- OPTIONAL_WARN=0
- FINAL_STATUS=FAIL

## Live URLs

- https://pix2pi.com.tr/
- https://panel.pix2pi.com.tr/password-login/
- https://panel.pix2pi.com.tr/onboarding/
- https://pos.pix2pi.com.tr/
- https://market.pix2pi.com.tr/

## Backup

- backups/faz7r/pix2pi_public_root_route_bridge_20260511_080525

## Audit check log

```
public root index file exists IMPLEMENTED_OR_PRESENT / OK ✅
public root contains Pix2pi brand IMPLEMENTED_OR_PRESENT / OK ✅
public root has public landing title IMPLEMENTED_OR_PRESENT / OK ✅
public root is not admin panel title IMPLEMENTED_OR_PRESENT / OK ✅
public route bridge marker IMPLEMENTED_OR_PRESENT / OK ✅
public root has panel login link IMPLEMENTED_OR_PRESENT / OK ✅
public root has onboarding link IMPLEMENTED_OR_PRESENT / OK ✅
public root has POS link IMPLEMENTED_OR_PRESENT / OK ✅
public root has market link IMPLEMENTED_OR_PRESENT / OK ✅
nginx config test status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
public root HTTPS smoke returned exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
public root smoke body has route bridge marker IMPLEMENTED_OR_PRESENT / OK ✅
public root smoke body has panel login link IMPLEMENTED_OR_PRESENT / OK ✅
public root smoke body has onboarding link IMPLEMENTED_OR_PRESENT / OK ✅
public root smoke body has POS link IMPLEMENTED_OR_PRESENT / OK ✅
public root smoke body has market link IMPLEMENTED_OR_PRESENT / OK ✅
panel_password_login live route smoke returned exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
panel_password_login live route body is non-empty IMPLEMENTED_OR_PRESENT / OK ✅
panel_onboarding live route smoke returned exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
panel_onboarding live route body is non-empty IMPLEMENTED_OR_PRESENT / OK ✅
pos_root live route smoke returned exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
pos_root live route body is non-empty IMPLEMENTED_OR_PRESENT / OK ✅
market_root live route smoke returned exact HTTP 200 REQUIRED_FAIL / FAIL ❌
STATUS_market_root=403
<html>
<head><title>403 Forbidden</title></head>
<body>
<center><h1>403 Forbidden</h1></center>
<hr><center>nginx/1.18.0 (Ubuntu)</center>
</body>
</html>
market_root live route body is non-empty IMPLEMENTED_OR_PRESENT / OK ✅
```
