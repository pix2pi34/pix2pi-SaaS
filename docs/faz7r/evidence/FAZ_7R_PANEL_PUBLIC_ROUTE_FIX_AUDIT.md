# FAZ 7-R Panel Public Route Fix Audit

Generated at: 20260510_204753

- PASS_COUNT=33
- FAIL_COUNT=0
- FINAL_STATUS=PASS
- PANEL_DOMAIN=panel.pix2pi.com.tr
- PANEL_WEB_ROOT=/var/www/pix2pi/panel
- NGINX_ROUTE=/etc/nginx/conf.d/00_pix2pi_panel_public.conf
- SSL_CERT=/etc/letsencrypt/live/pix2pi.com.tr/fullchain.pem

## Audit log

```
panel root index exists IMPLEMENTED_OR_PRESENT / OK ✅
panel login index exists IMPLEMENTED_OR_PRESENT / OK ✅
panel tenant-select index exists IMPLEMENTED_OR_PRESENT / OK ✅
panel i18n-demo index exists IMPLEMENTED_OR_PRESENT / OK ✅
panel onboarding index exists IMPLEMENTED_OR_PRESENT / OK ✅
active public nginx route exists IMPLEMENTED_OR_PRESENT / OK ✅
panel exact server_name exists IMPLEMENTED_OR_PRESENT / OK ✅
panel web root bound IMPLEMENTED_OR_PRESENT / OK ✅
public route marker exists IMPLEMENTED_OR_PRESENT / OK ✅
https panel route enabled IMPLEMENTED_OR_PRESENT / OK ✅
nginx config test PASS IMPLEMENTED_OR_PRESENT / OK ✅
nginx reload PASS IMPLEMENTED_OR_PRESENT / OK ✅
nginx loaded public panel route IMPLEMENTED_OR_PRESENT / OK ✅
panel home http exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
panel home http marker ok IMPLEMENTED_OR_PRESENT / OK ✅
panel login http exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
panel login http marker ok IMPLEMENTED_OR_PRESENT / OK ✅
panel tenant select http exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
panel tenant select http marker ok IMPLEMENTED_OR_PRESENT / OK ✅
panel i18n demo http exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
panel i18n demo http marker ok IMPLEMENTED_OR_PRESENT / OK ✅
panel onboarding http exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
panel onboarding http marker ok IMPLEMENTED_OR_PRESENT / OK ✅
panel home https exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
panel home https marker ok IMPLEMENTED_OR_PRESENT / OK ✅
panel login https exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
panel login https marker ok IMPLEMENTED_OR_PRESENT / OK ✅
panel tenant select https exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
panel tenant select https marker ok IMPLEMENTED_OR_PRESENT / OK ✅
panel i18n demo https exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
panel i18n demo https marker ok IMPLEMENTED_OR_PRESENT / OK ✅
panel onboarding https exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
panel onboarding https marker ok IMPLEMENTED_OR_PRESENT / OK ✅
```
