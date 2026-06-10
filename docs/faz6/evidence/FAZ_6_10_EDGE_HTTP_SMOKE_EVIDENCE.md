# FAZ 6-10 Edge HTTP Smoke Evidence

Generated At: 2026-05-01T16:13:31+03:00  
Repo: /root/pix2pi/pix2pi-SaaS  
DOMAIN=pix2pi.com.tr  
EXTRA_PATHS=/ /faz4d/pilot-go-live/  

Bu script DNS, Cloudflare veya Nginx ayari degistirmez. Sadece public GET content check evidence uretir.

Cloudflare note:
- Cloudflare gri bulut modundaysa CF-Ray / CF-Cache-Status beklenmez.
- Bu nedenle CF header yoklugu WARN degil INFO kabul edilir.
- Zorunlu kontrol origin/Nginx security/cache headerlaridir.

FAZ_6_10_EDGE_HTTP_SMOKE=STARTED ✅

---

===== EDGE HTTP SMOKE: root https =====
URL=https://pix2pi.com.tr/
http_code=200 time_total=0.083974 size=10 remote_ip=141.98.48.42
--- headers first 100 lines ---
HTTP/2 200 
server: nginx/1.18.0 (Ubuntu)
date: Fri, 01 May 2026 13:13:31 GMT
content-type: application/octet-stream
content-length: 10
content-type: text/plain
x-content-type-options: nosniff
x-frame-options: SAMEORIGIN
referrer-policy: strict-origin-when-cross-origin
x-xss-protection: 0
permissions-policy: geolocation=(), microphone=(), camera=(), payment=(), usb=()
strict-transport-security: max-age=31536000; includeSubDomains
content-security-policy: default-src 'self'; base-uri 'self'; frame-ancestors 'self'; object-src 'none'; img-src 'self' data: https:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; connect-src 'self' https: wss:;
cache-control: public, max-age=300

--- body first 500 chars ---
Pix2pi OK

--- curl error if any ---
root https EDGE_HTTP_OK ✅
root https CLOUDFLARE_PROXY_HEADERS_NOT_EXPECTED_GRAY_CLOUD ℹ️
root https EDGE_SECURITY_HEADERS_PRESENT ✅
x-content-type-options: nosniff
x-frame-options: SAMEORIGIN
referrer-policy: strict-origin-when-cross-origin
permissions-policy: geolocation=(), microphone=(), camera=(), payment=(), usb=()
strict-transport-security: max-age=31536000; includeSubDomains
content-security-policy: default-src 'self'; base-uri 'self'; frame-ancestors 'self'; object-src 'none'; img-src 'self' data: https:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; connect-src 'self' https: wss:;
cache-control: public, max-age=300

===== EDGE HTTP SMOKE: https path / =====
URL=https://pix2pi.com.tr/
http_code=200 time_total=0.112095 size=10 remote_ip=141.98.48.42
--- headers first 100 lines ---
HTTP/2 200 
server: nginx/1.18.0 (Ubuntu)
date: Fri, 01 May 2026 13:13:31 GMT
content-type: application/octet-stream
content-length: 10
content-type: text/plain
x-content-type-options: nosniff
x-frame-options: SAMEORIGIN
referrer-policy: strict-origin-when-cross-origin
x-xss-protection: 0
permissions-policy: geolocation=(), microphone=(), camera=(), payment=(), usb=()
strict-transport-security: max-age=31536000; includeSubDomains
content-security-policy: default-src 'self'; base-uri 'self'; frame-ancestors 'self'; object-src 'none'; img-src 'self' data: https:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; connect-src 'self' https: wss:;
cache-control: public, max-age=300

--- body first 500 chars ---
Pix2pi OK

--- curl error if any ---
https path / EDGE_HTTP_OK ✅
https path / CLOUDFLARE_PROXY_HEADERS_NOT_EXPECTED_GRAY_CLOUD ℹ️
https path / EDGE_SECURITY_HEADERS_PRESENT ✅
x-content-type-options: nosniff
x-frame-options: SAMEORIGIN
referrer-policy: strict-origin-when-cross-origin
permissions-policy: geolocation=(), microphone=(), camera=(), payment=(), usb=()
strict-transport-security: max-age=31536000; includeSubDomains
content-security-policy: default-src 'self'; base-uri 'self'; frame-ancestors 'self'; object-src 'none'; img-src 'self' data: https:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; connect-src 'self' https: wss:;
cache-control: public, max-age=300

===== EDGE HTTP SMOKE: https path /faz4d/pilot-go-live/ =====
URL=https://pix2pi.com.tr/faz4d/pilot-go-live/
http_code=200 time_total=0.103225 size=8452 remote_ip=141.98.48.42
--- headers first 100 lines ---
HTTP/2 200 
server: nginx/1.18.0 (Ubuntu)
date: Fri, 01 May 2026 13:13:31 GMT
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

--- body first 500 chars ---
<!doctype html>
<html lang="tr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Pix2pi Controlled Pilot Go-Live</title>
  <style>
    :root {
      --bg: #07111f;
      --card: #101d31;
      --card-2: #152640;
      --text: #eef6ff;
      --muted: #a8b8cc;
      --line: rgba(255, 255, 255, 0.12);
      --accent: #41b8ff;
      --ok: #38d996;
      --warn: #ffcf5a;
      --danger: #ff7d7d;
    }

    * {
      box-sizing: border-bo
--- curl error if any ---
https path /faz4d/pilot-go-live/ EDGE_HTTP_OK ✅
https path /faz4d/pilot-go-live/ CLOUDFLARE_PROXY_HEADERS_NOT_EXPECTED_GRAY_CLOUD ℹ️
https path /faz4d/pilot-go-live/ EDGE_SECURITY_HEADERS_PRESENT ✅
x-content-type-options: nosniff
x-frame-options: SAMEORIGIN
referrer-policy: strict-origin-when-cross-origin
permissions-policy: geolocation=(), microphone=(), camera=(), payment=(), usb=()
strict-transport-security: max-age=31536000; includeSubDomains
content-security-policy: default-src 'self'; base-uri 'self'; frame-ancestors 'self'; object-src 'none'; img-src 'self' data: https:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; connect-src 'self' https: wss:;
cache-control: public, max-age=300

===== EDGE HTTP SMOKE: http redirect/root =====
URL=http://pix2pi.com.tr/
http_code=200 time_total=0.150080 size=10 remote_ip=141.98.48.42
--- headers first 100 lines ---
HTTP/1.1 301 Moved Permanently
Server: nginx/1.18.0 (Ubuntu)
Date: Fri, 01 May 2026 13:13:32 GMT
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
date: Fri, 01 May 2026 13:13:32 GMT
content-type: application/octet-stream
content-length: 10
content-type: text/plain
x-content-type-options: nosniff
x-frame-options: SAMEORIGIN
referrer-policy: strict-origin-when-cross-origin
x-xss-protection: 0
permissions-policy: geolocation=(), microphone=(), camera=(), payment=(), usb=()
strict-transport-security: max-age=31536000; includeSubDomains
content-security-policy: default-src 'self'; base-uri 'self'; frame-ancestors 'self'; object-src 'none'; img-src 'self' data: https:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; connect-src 'self' https: wss:;
cache-control: public, max-age=300

--- body first 500 chars ---
Pix2pi OK

--- curl error if any ---
http redirect/root EDGE_HTTP_OK ✅
http redirect/root CLOUDFLARE_PROXY_HEADERS_NOT_EXPECTED_GRAY_CLOUD ℹ️
http redirect/root EDGE_SECURITY_HEADERS_PRESENT ✅
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: geolocation=(), microphone=(), camera=(), payment=(), usb=()
Strict-Transport-Security: max-age=31536000; includeSubDomains
Content-Security-Policy: default-src 'self'; base-uri 'self'; frame-ancestors 'self'; object-src 'none'; img-src 'self' data: https:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; connect-src 'self' https: wss:;
Cache-Control: public, max-age=300
x-content-type-options: nosniff
x-frame-options: SAMEORIGIN
referrer-policy: strict-origin-when-cross-origin
permissions-policy: geolocation=(), microphone=(), camera=(), payment=(), usb=()
strict-transport-security: max-age=31536000; includeSubDomains
content-security-policy: default-src 'self'; base-uri 'self'; frame-ancestors 'self'; object-src 'none'; img-src 'self' data: https:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; connect-src 'self' https: wss:;
cache-control: public, max-age=300


## Edge HTTP Smoke Final Seal

```text
PASS_COUNT=8
WARN_COUNT=0
INFO_COUNT=4
FAZ_6_10_EDGE_HTTP_SMOKE_STATUS=COMPLETE ✅
FAZ_6_10_CLOUDFLARE_PROXY_STATUS=DISABLED_OR_NOT_DETECTED_INFO ✅
FAZ_6_10_EDGE_HTTP_WARN_STATUS=CLEAR ✅
```
