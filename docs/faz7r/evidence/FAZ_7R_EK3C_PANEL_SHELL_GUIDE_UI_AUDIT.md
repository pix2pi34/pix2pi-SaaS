# FAZ 7-R / EK3C — Panel Shell Guide UI Audit Evidence

GeneratedAt: 2026-05-14T19:51:58+03:00

## Scope

Bu iş müşteriye açılacak final ERP ekranı değil; panel shell'in ekip tarafından anlaşılması ve takip edilmesi için açıklamalı kullanım rehberidir.

## Fixed Issue

Önceki EK3B denemesinde nginx içinde duplicate location "/" oluştu. Bu script:
- pix2pi_customer_panel_routes.conf include satırlarını temizledi.
- Root route'a dokunmadı.
- Güvenli /panel-shell/ route'u ekledi.

## Live URL

- https://panel.pix2pi.com.tr/panel-shell/
- https://panel.pix2pi.com.tr/panel-shell/health.json

## Shell Explains

- Dashboard neresi?
- Cari ne işe yarar?
- Ürün / Stok neresi?
- Raporlar neresi?
- Ayarlar neresi?
- Panel sağlık kontrolü nasıl yapılır?
- Ekip hangi alanı nasıl takip eder?

## Required Markers

- FAZ_7R_EK3C_PANEL_SHELL_GUIDE_MARKER
- PIX2PI_SHELL_TRAINING_UI
- PANEL_SHELL_GUIDE_ROUTE_MARKER
- I18N_TR_MARKER
- I18N_OTA_ARAB_MARKER
- HUSREV_EKALEM_RTL_MARKER

## Test Result

PASS_COUNT=24
FAIL_COUNT=12
WARN_COUNT=0

DOC_STATUS=READY
WEB_STATUS=FAIL
NGINX_STATUS=CHECK_REQUIRED
SMOKE_STATUS=FAIL
SHELL_GUIDE_STATUS=FAIL
REAL_IMPLEMENTATION_STATUS=FAIL
FINAL_STATUS=FAIL

## Evidence Files

- Curl body: /root/pix2pi/pix2pi-SaaS/backups/faz7r/faz_7r_ek3c_panel_shell_guide_20260514_195158/curl_panel_shell_body.html
- Curl headers: /root/pix2pi/pix2pi-SaaS/backups/faz7r/faz_7r_ek3c_panel_shell_guide_20260514_195158/curl_panel_shell_headers.txt
- Curl health: /root/pix2pi/pix2pi-SaaS/backups/faz7r/faz_7r_ek3c_panel_shell_guide_20260514_195158/curl_panel_shell_health.json
- Nginx dump: /root/pix2pi/pix2pi-SaaS/backups/faz7r/faz_7r_ek3c_panel_shell_guide_20260514_195158/nginx_dump.log
- Backup dir: /root/pix2pi/pix2pi-SaaS/backups/faz7r/faz_7r_ek3c_panel_shell_guide_20260514_195158
