# FAZ 7-R / EK3C — Panel Shell Guide UI FIX V2 Audit Evidence

GeneratedAt: 2026-05-14T20:02:55+03:00

## Problem

/panel-shell/ route HTTP 200 dönüyordu fakat markerlar gelmiyordu. Bu, aktif nginx server/location bloğunun shell HTML yerine eski panel cevabını döndürdüğünü gösterdi.

## Fix

- Hatalı customer root include temizlendi.
- Eski panel-shell include temizlendi.
- Aktif panel/default nginx server bloklarına inline /panel-shell route eklendi.
- Root "/" route ile çakışma yapılmadı.
- nginx -t, nginx -T, reload ve curl marker smoke tekrar çalıştırıldı.

## Live URL

- https://panel.pix2pi.com.tr/panel-shell/
- https://panel.pix2pi.com.tr/panel-shell/health.json

## Shell Purpose

Bu ekran müşterinin final ERP ekranı değil; panel shell'in ekip tarafından anlaşılması ve takip edilmesi için açıklamalı kullanım rehberidir.

## Required Markers

- FAZ_7R_EK3C_PANEL_SHELL_GUIDE_MARKER
- PIX2PI_SHELL_TRAINING_UI
- PANEL_SHELL_GUIDE_ROUTE_MARKER
- I18N_TR_MARKER
- I18N_OTA_ARAB_MARKER
- HUSREV_EKALEM_RTL_MARKER

## Test Result

PASS_COUNT=32
FAIL_COUNT=0
WARN_COUNT=0

DOC_STATUS=READY
WEB_STATUS=PASS
NGINX_STATUS=PASS
SMOKE_STATUS=PASS
SHELL_GUIDE_STATUS=PASS
REAL_IMPLEMENTATION_STATUS=PASS
FINAL_STATUS=PASS

## Evidence Files

- Curl body: /root/pix2pi/pix2pi-SaaS/backups/faz7r/faz_7r_ek3c_panel_shell_guide_fix_v2_20260514_200255/curl_panel_shell_body.html
- Curl headers: /root/pix2pi/pix2pi-SaaS/backups/faz7r/faz_7r_ek3c_panel_shell_guide_fix_v2_20260514_200255/curl_panel_shell_headers.txt
- Curl health: /root/pix2pi/pix2pi-SaaS/backups/faz7r/faz_7r_ek3c_panel_shell_guide_fix_v2_20260514_200255/curl_panel_shell_health.json
- Nginx dump: /root/pix2pi/pix2pi-SaaS/backups/faz7r/faz_7r_ek3c_panel_shell_guide_fix_v2_20260514_200255/nginx_dump.log
- Nginx patch result: /root/pix2pi/pix2pi-SaaS/backups/faz7r/faz_7r_ek3c_panel_shell_guide_fix_v2_20260514_200255/nginx_patch_result.txt
- Backup dir: /root/pix2pi/pix2pi-SaaS/backups/faz7r/faz_7r_ek3c_panel_shell_guide_fix_v2_20260514_200255
