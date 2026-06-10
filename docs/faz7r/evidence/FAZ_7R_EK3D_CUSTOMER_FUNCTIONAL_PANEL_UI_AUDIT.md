# FAZ 7-R / EK3D — Customer Functional Panel UI Audit Evidence

GeneratedAt: 2026-05-14T20:18:39+03:00

## Scope

Bu iş, shell guide sonrası müşterinin gerçek işlem akışını göreceği fonksiyonel panel UI'yi canlı route'a bağlar.

## Live URL

- https://panel.pix2pi.com.tr/customer-panel/
- https://panel.pix2pi.com.tr/customer-panel/health.json

## Customer Functional Screens

- Dashboard
- Ürün / Stok
- Cari
- Satış
- Raporlar
- Ayarlar
- Nasıl Kullanılır?

## Runtime Behavior

- Ürün kaydı yapılır.
- Cari kaydı yapılır.
- Satış kaydı yapılır.
- Satış sonrası stok düşer.
- Dashboard istatistikleri hesaplanır.
- Rapor özeti hesaplanır.
- Ayarlar kaydedilir.
- Veri tarayıcı localStorage üzerinde kalıcıdır.
- DB/API bağlantısı sonraki kapanışa ayrılmıştır.

## Required Markers

- FAZ_7R_EK3D_CUSTOMER_FUNCTIONAL_PANEL_MARKER
- PIX2PI_CUSTOMER_FUNCTIONAL_RUNTIME
- CUSTOMER_PANEL_FUNCTIONAL_ROUTE_MARKER
- CUSTOMER_PRODUCT_STOCK_UI_MARKER
- CUSTOMER_CARI_UI_MARKER
- CUSTOMER_SALES_UI_MARKER
- CUSTOMER_REPORTS_UI_MARKER
- CUSTOMER_SETTINGS_UI_MARKER
- LOCAL_PERSISTENCE_MARKER
- I18N_TR_MARKER
- I18N_OTA_ARAB_MARKER
- HUSREV_EKALEM_RTL_MARKER

## Test Result

PASS_COUNT=28
FAIL_COUNT=17
WARN_COUNT=0

DOC_STATUS=READY
WEB_STATUS=FAIL
NGINX_STATUS=CHECK_REQUIRED
SMOKE_STATUS=FAIL
CUSTOMER_UI_STATUS=FAIL
REAL_IMPLEMENTATION_STATUS=FAIL
FINAL_STATUS=FAIL

## Evidence Files

- Curl body: /root/pix2pi/pix2pi-SaaS/backups/faz7r/faz_7r_ek3d_customer_functional_panel_20260514_201839/curl_customer_panel_body.html
- Curl headers: /root/pix2pi/pix2pi-SaaS/backups/faz7r/faz_7r_ek3d_customer_functional_panel_20260514_201839/curl_customer_panel_headers.txt
- Curl health: /root/pix2pi/pix2pi-SaaS/backups/faz7r/faz_7r_ek3d_customer_functional_panel_20260514_201839/curl_customer_panel_health.json
- Nginx dump: /root/pix2pi/pix2pi-SaaS/backups/faz7r/faz_7r_ek3d_customer_functional_panel_20260514_201839/nginx_dump.log
- Backup dir: /root/pix2pi/pix2pi-SaaS/backups/faz7r/faz_7r_ek3d_customer_functional_panel_20260514_201839
