# FAZ 6-10 Edge Header Diagnostic

Generated At: 2026-05-01T15:41:22+03:00

Bu diagnostic degisiklik yapmaz.
Amac: Edge header WARN sebebini bulmak.


## 1) nginx.conf include kontrolu
```text
/etc/nginx/nginx.conf:60:	include /etc/nginx/conf.d/*.conf;
/etc/nginx/conf.d/00-pix2pi-edge-security-headers.conf:5:# include edilen /etc/nginx/conf.d/*.conf kapsaminda calisir.
/etc/nginx/nginx.conf:60:	include /etc/nginx/conf.d/*.conf;
```

## 2) Header conf dosyasi
```text
-rw-r--r-- 1 root root 1435 May  1 15:38 /etc/nginx/conf.d/00-pix2pi-edge-security-headers.conf

# Pix2pi Edge Security Headers
# FAZ 6-10 Edge Header Hardening
#
# Bu dosya /etc/nginx/nginx.conf icindeki http context altinda
# include edilen /etc/nginx/conf.d/*.conf kapsaminda calisir.
#
# Amac:
# - Public route response'larinda temel security header standardi saglamak
# - Edge smoke testlerinde header evidence uretmek
# - Mevcut server block'lara minimum mudahale ile global guvenlik standardi eklemek
#
# Not:
# - "always" parametresi 2xx/3xx disi response'larda da header gonderir.
# - CSP bilincli olarak makul/genis tutuldu; inline CSS kullanan mevcut public HTML'i bozmaz.

add_header X-Content-Type-Options "nosniff" always;
add_header X-Frame-Options "SAMEORIGIN" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header X-XSS-Protection "0" always;
add_header Permissions-Policy "geolocation=(), microphone=(), camera=(), payment=(), usb=()" always;
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

add_header Content-Security-Policy "default-src 'self'; base-uri 'self'; frame-ancestors 'self'; object-src 'none'; img-src 'self' data: https:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; connect-src 'self' https: wss:;" always;

# Static/public sayfalar icin makul varsayilan.
# Hassas API response'lari ayri server/location seviyesinde no-store ile override edilebilir.
add_header Cache-Control "public, max-age=300" always;
```

## 3) Tum nginx add_header envanteri
```text
/etc/nginx/sites-available/pix2pi:71:        add_header Cache-Control "no-store, no-cache, must-revalidate" always;
/etc/nginx/sites-available/pix2pi_ssl:12:        add_header Cache-Control "no-store, no-cache, must-revalidate" always;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_084317:12:        add_header Cache-Control "no-store, no-cache, must-revalidate" always;
/etc/nginx/snippets/pix2pi_gateway_internal_block.conf:3:    add_header Cache-Control "no-store" always;
/etc/nginx/snippets/pix2pi_gateway_internal_block.conf:4:    add_header X-Ingress-Policy "public-internal-deny" always;
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:34:        add_header Cache-Control "no-store, no-cache, must-revalidate, max-age=0" always;
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:45:        add_header Cache-Control "no-store, no-cache, must-revalidate, max-age=0" always;
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:52:        add_header Cache-Control "no-store, no-cache, must-revalidate, max-age=0" always;
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:63:        add_header Cache-Control "no-store, no-cache, must-revalidate, max-age=0" always;
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:70:        add_header Cache-Control "no-store, no-cache, must-revalidate, max-age=0" always;
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:81:        add_header Content-Type text/plain;
/etc/nginx/conf.d/00-pix2pi-edge-security-headers.conf:16:add_header X-Content-Type-Options "nosniff" always;
/etc/nginx/conf.d/00-pix2pi-edge-security-headers.conf:17:add_header X-Frame-Options "SAMEORIGIN" always;
/etc/nginx/conf.d/00-pix2pi-edge-security-headers.conf:18:add_header Referrer-Policy "strict-origin-when-cross-origin" always;
/etc/nginx/conf.d/00-pix2pi-edge-security-headers.conf:19:add_header X-XSS-Protection "0" always;
/etc/nginx/conf.d/00-pix2pi-edge-security-headers.conf:20:add_header Permissions-Policy "geolocation=(), microphone=(), camera=(), payment=(), usb=()" always;
/etc/nginx/conf.d/00-pix2pi-edge-security-headers.conf:21:add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
/etc/nginx/conf.d/00-pix2pi-edge-security-headers.conf:23:add_header Content-Security-Policy "default-src 'self'; base-uri 'self'; frame-ancestors 'self'; object-src 'none'; img-src 'self' data: https:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; connect-src 'self' https: wss:;" always;
/etc/nginx/conf.d/00-pix2pi-edge-security-headers.conf:27:add_header Cache-Control "public, max-age=300" always;
```

## 4) server_name / location / root / proxy_pass envanteri
```text
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:2:    listen 80;
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:3:    server_name pix2pi.com.tr www.pix2pi.com.tr;
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:5:    location /faz4d/ {
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:9:    location / {
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:15:    listen 443 ssl http2;
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:16:    server_name pix2pi.com.tr www.pix2pi.com.tr;
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:21:    location = /faz4d/pilot-go-live {
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:26:    location = /faz5 {
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:30:    location = /faz5/ {
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:31:        root /var/www/pix2pi;
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:33:        try_files /faz5/index.html =404;
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:37:    location = /faz5/pricing {
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:41:    location = /faz5/pricing/ {
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:42:        root /var/www/pix2pi;
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:44:        try_files /faz5/pricing/index.html =404;
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:48:    location ^~ /faz5/pricing/ {
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:49:        root /var/www/pix2pi;
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:51:        try_files $uri /faz5/pricing/index.html =404;
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:55:    location = /faz5/developer {
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:59:    location = /faz5/developer/ {
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:60:        root /var/www/pix2pi;
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:62:        try_files /faz5/developer/index.html =404;
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:66:    location ^~ /faz5/developer/ {
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:67:        root /var/www/pix2pi;
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:69:        try_files $uri /faz5/developer/index.html =404;
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:73:    location /faz4d/pilot-go-live/ {
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:76:        try_files $uri $uri/ /faz4d/pilot-go-live/index.html;
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:79:    location / {
/etc/nginx/conf.d/00-pix2pi-edge-security-headers.conf:20:add_header Permissions-Policy "geolocation=(), microphone=(), camera=(), payment=(), usb=()" always;
/etc/nginx/conf.d/00-pix2pi-edge-security-headers.conf:26:# Hassas API response'lari ayri server/location seviyesinde no-store ile override edilebilir.
/etc/nginx/conf.d/pix2pi_edge_live.conf:24:    listen 80;
/etc/nginx/conf.d/pix2pi_edge_live.conf:25:    server_name api.pix2pi.com.tr panel.pix2pi.com.tr auth.pix2pi.com.tr pos.pix2pi.com.tr;
/etc/nginx/conf.d/pix2pi_edge_live.conf:29:    location ^~ /.well-known/acme-challenge/ {
/etc/nginx/conf.d/pix2pi_edge_live.conf:33:    location / {
/etc/nginx/conf.d/pix2pi_edge_live.conf:39:    listen 443 ssl http2;
/etc/nginx/conf.d/pix2pi_edge_live.conf:40:    server_name api.pix2pi.com.tr;
/etc/nginx/conf.d/pix2pi_edge_live.conf:52:    location /internal/ {
/etc/nginx/conf.d/pix2pi_edge_live.conf:57:    location = /health {
/etc/nginx/conf.d/pix2pi_edge_live.conf:61:        proxy_pass http://pix2pi_api_upstream/health;
/etc/nginx/conf.d/pix2pi_edge_live.conf:64:    location / {
/etc/nginx/conf.d/pix2pi_edge_live.conf:67:        proxy_pass http://pix2pi_api_upstream;
/etc/nginx/conf.d/pix2pi_edge_live.conf:72:    listen 443 ssl http2;
/etc/nginx/conf.d/pix2pi_edge_live.conf:73:    server_name panel.pix2pi.com.tr;
/etc/nginx/conf.d/pix2pi_edge_live.conf:85:    location /internal/ {
/etc/nginx/conf.d/pix2pi_edge_live.conf:90:    location /api/ {
/etc/nginx/conf.d/pix2pi_edge_live.conf:92:        proxy_pass http://pix2pi_api_upstream;
/etc/nginx/conf.d/pix2pi_edge_live.conf:96:    location / {
/etc/nginx/conf.d/pix2pi_edge_live.conf:99:        proxy_pass http://pix2pi_panel_upstream;
/etc/nginx/conf.d/pix2pi_edge_live.conf:104:    listen 443 ssl http2;
/etc/nginx/conf.d/pix2pi_edge_live.conf:105:    server_name auth.pix2pi.com.tr;
/etc/nginx/conf.d/pix2pi_edge_live.conf:117:    location /internal/ {
/etc/nginx/conf.d/pix2pi_edge_live.conf:122:    location = /health {
/etc/nginx/conf.d/pix2pi_edge_live.conf:126:        proxy_pass http://pix2pi_auth_upstream/health;
/etc/nginx/conf.d/pix2pi_edge_live.conf:129:    location / {
/etc/nginx/conf.d/pix2pi_edge_live.conf:132:        proxy_pass http://pix2pi_auth_upstream;
/etc/nginx/conf.d/pix2pi_edge_live.conf:137:    listen 443 ssl http2;
/etc/nginx/conf.d/pix2pi_edge_live.conf:138:    server_name pos.pix2pi.com.tr;
/etc/nginx/conf.d/pix2pi_edge_live.conf:150:    location /internal/ {
/etc/nginx/conf.d/pix2pi_edge_live.conf:155:    location / {
/etc/nginx/conf.d/pix2pi_edge_live.conf:158:        proxy_pass http://pix2pi_pos_upstream;
/etc/nginx/conf.d/health.conf:4:    location /health {
```

## 5) nginx -T header/server dump
```text
24:	# server_names_hash_bucket_size 64;
25:	# server_name_in_redirect off;
61:	include /etc/nginx/conf.d/*.conf;
201:# include edilen /etc/nginx/conf.d/*.conf kapsaminda calisir.
212:add_header X-Content-Type-Options "nosniff" always;
213:add_header X-Frame-Options "SAMEORIGIN" always;
214:add_header Referrer-Policy "strict-origin-when-cross-origin" always;
215:add_header X-XSS-Protection "0" always;
216:add_header Permissions-Policy "geolocation=(), microphone=(), camera=(), payment=(), usb=()" always;
217:add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
219:add_header Content-Security-Policy "default-src 'self'; base-uri 'self'; frame-ancestors 'self'; object-src 'none'; img-src 'self' data: https:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; connect-src 'self' https: wss:;" always;
222:# Hassas API response'lari ayri server/location seviyesinde no-store ile override edilebilir.
223:add_header Cache-Control "public, max-age=300" always;
238:    location /health {
267:    listen 80;
268:    server_name api.pix2pi.com.tr panel.pix2pi.com.tr auth.pix2pi.com.tr pos.pix2pi.com.tr;
272:    location ^~ /.well-known/acme-challenge/ {
276:    location / {
282:    listen 443 ssl http2;
283:    server_name api.pix2pi.com.tr;
295:    location /internal/ {
300:    location = /health {
304:        proxy_pass http://pix2pi_api_upstream/health;
307:    location / {
310:        proxy_pass http://pix2pi_api_upstream;
315:    listen 443 ssl http2;
316:    server_name panel.pix2pi.com.tr;
328:    location /internal/ {
333:    location /api/ {
335:        proxy_pass http://pix2pi_api_upstream;
339:    location / {
342:        proxy_pass http://pix2pi_panel_upstream;
347:    listen 443 ssl http2;
348:    server_name auth.pix2pi.com.tr;
360:    location /internal/ {
365:    location = /health {
369:        proxy_pass http://pix2pi_auth_upstream/health;
372:    location / {
375:        proxy_pass http://pix2pi_auth_upstream;
380:    listen 443 ssl http2;
381:    server_name pos.pix2pi.com.tr;
393:    location /internal/ {
398:    location / {
401:        proxy_pass http://pix2pi_pos_upstream;
410:root /var/www/certbot;
423:add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
424:add_header X-Frame-Options "SAMEORIGIN" always;
425:add_header X-Content-Type-Options "nosniff" always;
426:add_header Referrer-Policy "strict-origin-when-cross-origin" always;
427:add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
428:add_header X-XSS-Protection "1; mode=block" always;
445:location = /__pix2pi_error_minimal__.html {
456:add_header X-Edge-Trusted-Proxy "127.0.0.1/32" always;
493:    listen 80;
494:    server_name pix2pi.com.tr www.pix2pi.com.tr;
496:    location /faz4d/ {
500:    location / {
506:    listen 443 ssl http2;
507:    server_name pix2pi.com.tr www.pix2pi.com.tr;
512:    location = /faz4d/pilot-go-live {
517:    location = /faz5 {
521:    location = /faz5/ {
522:        root /var/www/pix2pi;
525:        add_header Cache-Control "no-store, no-cache, must-revalidate, max-age=0" always;
528:    location = /faz5/pricing {
532:    location = /faz5/pricing/ {
533:        root /var/www/pix2pi;
536:        add_header Cache-Control "no-store, no-cache, must-revalidate, max-age=0" always;
539:    location ^~ /faz5/pricing/ {
540:        root /var/www/pix2pi;
543:        add_header Cache-Control "no-store, no-cache, must-revalidate, max-age=0" always;
546:    location = /faz5/developer {
550:    location = /faz5/developer/ {
551:        root /var/www/pix2pi;
554:        add_header Cache-Control "no-store, no-cache, must-revalidate, max-age=0" always;
557:    location ^~ /faz5/developer/ {
558:        root /var/www/pix2pi;
561:        add_header Cache-Control "no-store, no-cache, must-revalidate, max-age=0" always;
564:    location /faz4d/pilot-go-live/ {
570:    location / {
572:        add_header Content-Type text/plain;
```

## 6) Local host header HTTPS test
```text
HTTP/2 200 
server: nginx/1.18.0 (Ubuntu)
date: Fri, 01 May 2026 12:41:22 GMT
content-type: application/octet-stream
content-length: 10
content-type: text/plain

```

## 7) Public HTTPS header test
```text
HTTP/2 200 
server: nginx/1.18.0 (Ubuntu)
date: Fri, 01 May 2026 12:41:22 GMT
content-type: application/octet-stream
content-length: 10
content-type: text/plain


HTTP/2 200 
server: nginx/1.18.0 (Ubuntu)
date: Fri, 01 May 2026 12:41:22 GMT
content-type: text/html
content-length: 8452
last-modified: Fri, 01 May 2026 07:31:54 GMT
etag: "69f456ea-2104"
x-content-type-options: nosniff
x-frame-options: SAMEORIGIN
referrer-policy: strict-origin-when-cross-origin
x-xss-protection: 0
permissions-policy: geolocation=(), microphone=(), camera=(), payment=(), usb=()
strict-transport-security: max-age=31536000; includeSubDomains
content-security-policy: default-src 'self'; base-uri 'self'; frame-ancestors 'self'; object-src 'none'; img-src 'self' data: https:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; connect-src 'self' https: wss:;
cache-control: public, max-age=300
accept-ranges: bytes

```

## 8) Son edge smoke warn satirlari
```text
30:root https EDGE_HEADERS_WARN ⚠️
48:https path / EDGE_HEADERS_WARN ⚠️
96:https path /faz4d/pilot-go-live/ EDGE_HEADERS_PRESENT ✅
114:X-Content-Type-Options: nosniff
115:X-Frame-Options: SAMEORIGIN
119:Strict-Transport-Security: max-age=31536000; includeSubDomains
121:Cache-Control: public, max-age=300
135:http redirect/root EDGE_HEADERS_PRESENT ✅
136:X-Content-Type-Options: nosniff
137:X-Frame-Options: SAMEORIGIN
138:Strict-Transport-Security: max-age=31536000; includeSubDomains
140:Cache-Control: public, max-age=300
147:WARN_COUNT=2
149:FAZ_6_10_EDGE_HTTP_WARN_STATUS=HAS_WARNINGS ⚠️
```
