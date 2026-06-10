# FAZ 7-R / EK3B — Customer Real Panel UI Audit Evidence

GeneratedAt: 2026-05-14T19:37:38+03:00

## Scope

Bu iş EK3 shell sonrası müşterinin gerçekten kullanacağı işletme panelini canlı panel root route'a bağlar.

## Live URL

- https://panel.pix2pi.com.tr/
- http://panel.pix2pi.com.tr/
- /health.json

## Customer Screens

- Dashboard
- Ürün / Stok
- Cari
- Satış
- Raporlar
- Ayarlar
- i18n / RTL marker

## Runtime Behavior

- Ürün kaydı yapılır
- Cari kaydı yapılır
- Satış kaydı yapılır
- Stok satıştan düşer
- Dashboard istatistikleri hesaplanır
- Rapor özeti hesaplanır
- Ayarlar kaydedilir
- Tarayıcı localStorage üzerinde kalıcı çalışır
- Backend API bağlanınca aynı UI DB persistence'a taşınabilir

## Required Markers

- FAZ_7R_EK3B_CUSTOMER_REAL_PANEL_MARKER
- PIX2PI_CUSTOMER_REAL_RUNTIME
- CUSTOMER_PANEL_ROOT_ROUTE_MARKER
- I18N_TR_MARKER
- I18N_OTA_ARAB_MARKER
- HUSREV_EKALEM_RTL_MARKER

## Test Result

PASS_COUNT=21
FAIL_COUNT=10
WARN_COUNT=0

DOC_STATUS=READY
WEB_STATUS=FAIL
NGINX_STATUS=CHECK_REQUIRED
SMOKE_STATUS=FAIL
CUSTOMER_UI_STATUS=FAIL
REAL_IMPLEMENTATION_STATUS=FAIL
FINAL_STATUS=FAIL

## Evidence Files

- Curl root body: /root/pix2pi/pix2pi-SaaS/backups/faz7r/faz_7r_ek3b_customer_real_panel_20260514_193738/curl_customer_panel_root.html
- Curl headers: /root/pix2pi/pix2pi-SaaS/backups/faz7r/faz_7r_ek3b_customer_real_panel_20260514_193738/curl_customer_panel_headers.txt
- Curl health: /root/pix2pi/pix2pi-SaaS/backups/faz7r/faz_7r_ek3b_customer_real_panel_20260514_193738/curl_customer_panel_health.json
- Nginx dump: /root/pix2pi/pix2pi-SaaS/backups/faz7r/faz_7r_ek3b_customer_real_panel_20260514_193738/nginx_dump.log
- Backup dir: /root/pix2pi/pix2pi-SaaS/backups/faz7r/faz_7r_ek3b_customer_real_panel_20260514_193738
