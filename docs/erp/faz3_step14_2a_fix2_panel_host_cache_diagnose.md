# FAZ 3 / STEP 14.2A-FIX2 — Panel Host / Cache Diagnose

Tarih: 20260426_235335

## Amaç

Lokal panel dosyasına eklenen ERP Runtime Smoke UI'nin neden public panel response içinde görünmediğini ayırmak.

## Sonuç

Karar: local_nginx_not_serving_panel_file

## HTTP Kodları

- Local HTTP Host panel: 301
- Local HTTPS Host panel: 200
- Public panel: 200

## Block Görünürlüğü

- Local HTTPS body smoke block: no
- Public body smoke block: no

## Yorum

Eğer local HTTPS Host testinde block var ama public panelde yoksa problem kod değil; büyük ihtimalle Cloudflare/edge cache veya dış proxy eski HTML dönüyordur.

Eğer local HTTPS Host testinde de block yoksa aktif Nginx server block beklenen panel_index.html dosyasını servis etmiyordur.

## Loglar

- backups/faz3_14_2a_fix2_panel_host_cache_diagnose_20260426_235335/logs/sites_enabled_active.log
- backups/faz3_14_2a_fix2_panel_host_cache_diagnose_20260426_235335/logs/body_compare.log
- backups/faz3_14_2a_fix2_panel_host_cache_diagnose_20260426_235335/logs/asset_candidates.txt

## Sonraki Adım

Karara göre:
- edge_cache_or_external_proxy ise cache-bypass / cache-control / purge yönü
- local_nginx_not_serving_panel_file ise aktif Nginx config düzeltmesi
