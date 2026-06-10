# FAZ 7-R / 316 — panel.pix2pi.com.tr altyapısı

## Amaç

Pix2pi müşteri kullanım yüzeyi için `panel.pix2pi.com.tr` merchant panel altyapısını kurar.

## Kapsam

316.1 Panel subdomain routing  
316.2 Nginx route standardı  
316.3 Panel app shell  
316.4 Sidebar / topbar  
316.5 Breadcrumb  
316.6 Tenant indicator  
316.7 Responsive shell  
316.8 Panel health check  
316.9 Panel smoke test  

## FIX V3 Notu

V2'de nginx dosyası diskte hazır olmasına rağmen smoke test `301 Moved Permanently` body dönmüştür.

Bu durum şunu gösterir:

- Panel route dosyası nginx tarafından yüklenmemiş olabilir.
- Ya da panel host'u global/wildcard HTTP→HTTPS redirect route'una düşmüş olabilir.

FIX V3 ile:

- Panel route `nginx -T` çıktısında gerçekten yüklendi mi kontrol edilir.
- Gerekirse route `/etc/nginx/sites-enabled/00_pix2pi_panel` içine alınır.
- Curl kontrolü artık sadece `curl -f` ile değil, gerçek HTTP status `200` ve gerçek body marker'ları ile yapılır.
- 301 response artık PASS sayılmaz.

## Kullanım yüzeyleri

- Müşteri paneli: `panel.pix2pi.com.tr`
- POS: `pos.pix2pi.com.tr`
- Market: `market.pix2pi.com.tr` veya `pix2pi.com.tr/market`
