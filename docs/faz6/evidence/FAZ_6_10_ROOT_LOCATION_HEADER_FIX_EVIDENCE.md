# FAZ 6-10 Root Location Header Fix Evidence

Generated At: 2026-05-01T15:47:04+03:00

Target Conf: /etc/nginx/conf.d/pix2pi_faz4d_static.conf
Backup Dir: backups/faz6_10_root_location_header_fix_20260501_154704

Amac:
- Cloudflare gri oldugu icin CF-Ray / CF-Cache-Status beklenmez.
- Root / endpointinde eksik kalan Nginx security headerlari location seviyesinde eklenir.
- Pilot sayfasi zaten header donduruyordu; root / ayni standarda yaklastirilir.


## Root Location Header Inventory After Patch
```text
212:add_header X-Content-Type-Options "nosniff" always;
213:add_header X-Frame-Options "SAMEORIGIN" always;
214:add_header Referrer-Policy "strict-origin-when-cross-origin" always;
215:add_header X-XSS-Protection "0" always;
216:add_header Permissions-Policy "geolocation=(), microphone=(), camera=(), payment=(), usb=()" always;
217:add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
219:add_header Content-Security-Policy "default-src 'self'; base-uri 'self'; frame-ancestors 'self'; object-src 'none'; img-src 'self' data: https:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; connect-src 'self' https: wss:;" always;
223:add_header Cache-Control "public, max-age=300" always;
238:    location /health {
239:        return 200 'OK';
276:    location / {
295:    location /internal/ {
307:    location / {
328:    location /internal/ {
333:    location /api/ {
339:    location / {
360:    location /internal/ {
372:    location / {
393:    location /internal/ {
398:    location / {
423:add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
424:add_header X-Frame-Options "SAMEORIGIN" always;
425:add_header X-Content-Type-Options "nosniff" always;
426:add_header Referrer-Policy "strict-origin-when-cross-origin" always;
427:add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
428:add_header X-XSS-Protection "1; mode=block" always;
448:    return 200 '<html><body><h1>Request could not be completed.</h1></body></html>';
456:add_header X-Edge-Trusted-Proxy "127.0.0.1/32" always;
494:    server_name pix2pi.com.tr www.pix2pi.com.tr;
496:    location /faz4d/ {
500:    location / {
507:    server_name pix2pi.com.tr www.pix2pi.com.tr;
525:        add_header Cache-Control "no-store, no-cache, must-revalidate, max-age=0" always;
536:        add_header Cache-Control "no-store, no-cache, must-revalidate, max-age=0" always;
543:        add_header Cache-Control "no-store, no-cache, must-revalidate, max-age=0" always;
554:        add_header Cache-Control "no-store, no-cache, must-revalidate, max-age=0" always;
561:        add_header Cache-Control "no-store, no-cache, must-revalidate, max-age=0" always;
564:    location /faz4d/pilot-go-live/ {
570:    location / {
571:        return 200 "Pix2pi OK\n";
572:        add_header Content-Type text/plain;
```
OK ✅ nginx -t basarili
OK ✅ nginx reload basarili

## Root HTTPS Header Probe
```text
HTTP/2 200 
server: nginx/1.18.0 (Ubuntu)
date: Fri, 01 May 2026 12:47:04 GMT
content-type: application/octet-stream
content-length: 10
content-type: text/plain

```

## Pilot HTTPS Header Probe
```text
HTTP/2 200 
server: nginx/1.18.0 (Ubuntu)
date: Fri, 01 May 2026 12:47:04 GMT
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

## HTTP Redirect Header Probe
```text
HTTP/1.1 301 Moved Permanently
Server: nginx/1.18.0 (Ubuntu)
Date: Fri, 01 May 2026 12:47:04 GMT
Content-Type: text/html
Content-Length: 178
Connection: keep-alive
Location: https://pix2pi.com.tr/
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
Referrer-Policy: strict-origin-when-cross-origin
X-XSS-Protection: 0
Permissions-Policy: geolocation=(), microphone=(), camera=(), payment=(), usb=()
Strict-Transport-Security: max-age=31536000; includeSubDomains
Content-Security-Policy: default-src 'self'; base-uri 'self'; frame-ancestors 'self'; object-src 'none'; img-src 'self' data: https:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; connect-src 'self' https: wss:;
Cache-Control: public, max-age=300

HTTP/2 200 
server: nginx/1.18.0 (Ubuntu)
date: Fri, 01 May 2026 12:47:04 GMT
content-type: application/octet-stream
content-length: 10
content-type: text/plain

```
FAZ_6_10_ROOT_HEADER_WARN_STATUS=HAS_WARNINGS ⚠️
FAZ_6_10_ROOT_LOCATION_HEADER_FIX_STATUS=PASS_WITH_WARNINGS ⚠️
