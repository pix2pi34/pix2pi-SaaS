# FAZ 3 / STEP 14.3A — Content-Type Header Diagnose Raporu

Tarih: 20260427_001443

## Amaç

Panel same-origin ERP Runtime API response header içinde görülen çift Content-Type değerinin kaynağını bulmak.

## Test Sonuçları

- Direct Gateway API code: 200
- Panel same-origin API code: 200
- Direct Content-Type: Content-Type: application/json; charset=utf-8
- Panel Content-Type: content-type: text/plain; charset=utf-8, application/json; charset=utf-8
- Direct duplicate: no
- Panel duplicate: yes
- Root cause: nginx_or_panel_proxy_header_merge

## Yorum

- Direct duplicate yes ise sorun gateway response writer / API handler tarafındadır.
- Direct no, panel yes ise sorun nginx/proxy header merge tarafındadır.
- İkisi de no ise mevcut durumda tekrar üretilemedi.

## Test Data

- Direct source no: CT-DIRECT-20260427_001443
- Panel source no: CT-PANEL-20260427_001443
- Test verisi temizlendi ✅

## Loglar

- Direct headers: backups/faz3_14_3a_content_type_header_diagnose_20260427_001443/logs/direct_headers.txt
- Panel headers: backups/faz3_14_3a_content_type_header_diagnose_20260427_001443/logs/panel_headers.txt
- Source scan: backups/faz3_14_3a_content_type_header_diagnose_20260427_001443/logs/content_type_source_scan.log

## Sonraki Adım

FAZ 3 / STEP 14.3B — Root cause sonucuna göre header cleanup fix.
