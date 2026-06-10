# FAZ 6-10 Edge Runtime Audit Evidence

Generated At: 2026-05-01T15:52:49+03:00  
Host: vm12827.ovadns.com  
Repo: /root/pix2pi/pix2pi-SaaS  
DOMAIN=pix2pi.com.tr  

Bu audit DNS/CDN/WAF/Edge runtime izlerini toplar. Degisiklik yapmaz.

FAZ_6_10_RUNTIME_AUDIT=STARTED ✅

---


## 6-10.1 Host / Kernel

```text
Linux vm12827.ovadns.com 5.15.0-176-generic #186-Ubuntu SMP Fri Mar 13 11:01:42 UTC 2026 x86_64 x86_64 x86_64 GNU/Linux
```

## 6-10.2 DNS Resolution Runtime

```text
===== A =====
141.98.48.42
===== AAAA =====
===== CNAME =====
===== NS =====
cass.ns.cloudflare.com.
elias.ns.cloudflare.com.
```

## 6-10.3 TLS Certificate Probe

```text
subject=CN = pix2pi.com.tr
issuer=C = US, O = Let's Encrypt, CN = R12
notBefore=Mar 14 04:37:10 2026 GMT
notAfter=Jun 12 04:37:09 2026 GMT
```

## 6-10.4 Public HTTPS Header Probe

```text
HTTP/2 200 
server: nginx/1.18.0 (Ubuntu)
date: Fri, 01 May 2026 12:52:50 GMT
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

```

## 6-10.5 Public GET Content Probe

```text
Pix2pi OK

HTTP_STATUS=200 SIZE=10 TIME=0.112315 REMOTE_IP=141.98.48.42
```

## 6-10.6 Public Pilot GET Content Probe

```text
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
      box-sizing: border-box;
    }

    body {
      margin: 0;
      font-family: Arial, Helvetica, sans-serif;
      color: var(--text);
      background: radial-gradient(circle at top left, #193f66, var(--bg) 54%);
    }

    .page {
      width: min(1180px, calc(100% - 32px));
      margin: 0 auto;
      padding: 28px 0 38px;
    }

    .hero {
      padding: 26px;
      border: 1px solid var(--line);
      border-radius: 22px;
      background: linear-gradient(135deg, rgba(56, 217, 150, 0.16), rgba(16, 29, 49, 0.94));
      box-shadow: 0 18px 40px rgba(0, 0, 0, 0.28);
    }

    .eyebrow {
      color: var(--ok);
      font-weight: 700;
      letter-spacing: 0.04em;
      text-transform: uppercase;
      font-size: 13px;
      margin-bottom: 10px;
    }

    h1 {
      margin: 0;
      font-size: clamp(28px, 4vw, 46px);
      line-height: 1.06;
    }

    .subtitle {
      margin: 14px 0 0;
      color: var(--muted);
      max-width: 900px;
      line-height: 1.6;
      font-size: 16px;
    }

    .status {
      display: flex;
      flex-wrap: wrap;
      gap: 10px;
      margin-top: 18px;
    }

    .pill {
      padding: 9px 12px;
      border-radius: 999px;
      border: 1px solid var(--line);
      background: rgba(255, 255, 255, 0.08);
      font-size: 14px;
    }

    .pill strong {
      color: var(--ok);
    }

    .pill.warn strong {
      color: var(--warn);
    }

    .pill.danger strong {
      color: var(--danger);
    }

    .grid {
      display: grid;
      grid-template-columns:```

## 6-10.7 HTTP Redirect Probe

```text
HTTP/1.1 301 Moved Permanently
Server: nginx/1.18.0 (Ubuntu)
Date: Fri, 01 May 2026 12:52:50 GMT
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

```

## 6-10.8 Nginx Edge Config Inventory

```text
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful

/etc/nginx/sites-available/pix2pi.bak_20260320_080106:2:    listen 80;
/etc/nginx/sites-available/pix2pi.bak_20260320_080106:3:    server_name _;
/etc/nginx/sites-available/pix2pi.bak_20260320_080106:8:        proxy_pass http://127.0.0.1:5858;
/etc/nginx/sites-available/pix2pi.bak_20260320_080106:10:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi.bak_20260320_080106:11:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi.bak_20260320_080106:12:        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
/etc/nginx/sites-available/pix2pi.bak_20260320_080106:13:        proxy_set_header X-Forwarded-Proto $scheme;
/etc/nginx/sites-available/pix2pi.bak_20260320_080106:19:        proxy_pass http://127.0.0.1:9001/health;
/etc/nginx/sites-available/pix2pi.bak_20260320_080106:21:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi.bak_20260320_080106:27:        proxy_pass http://127.0.0.1:9001;
/etc/nginx/sites-available/pix2pi.bak_20260320_080106:29:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi.bak_20260320_080106:30:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi.bak_20260320_080106:31:        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
/etc/nginx/sites-available/pix2pi.bak_20260320_080106:32:        proxy_set_header X-Forwarded-Proto $scheme;
/etc/nginx/sites-available/pix2pi.bak_20260320_080106:37:        proxy_pass http://127.0.0.1:9011;
/etc/nginx/sites-available/pix2pi.bak_20260320_080106:39:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi.bak_20260320_080106:40:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_1773945801:2:    listen 443 ssl;
/etc/nginx/sites-available/pix2pi_ssl.bak_1773945801:3:    server_name pix2pi.com.tr www.pix2pi.com.tr panel.pix2pi.com.tr;
/etc/nginx/sites-available/pix2pi_ssl.bak_1773945801:5:    ssl_certificate /etc/letsencrypt/live/pix2pi.com.tr/fullchain.pem;
/etc/nginx/sites-available/pix2pi_ssl.bak_1773945801:6:    ssl_certificate_key /etc/letsencrypt/live/pix2pi.com.tr/privkey.pem;
/etc/nginx/sites-available/pix2pi_ssl.bak_1773945801:16:        proxy_pass http://127.0.0.1:8080/api/health;
/etc/nginx/sites-available/pix2pi_ssl.bak_1773945801:17:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_1773945801:18:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_1773945801:22:        proxy_pass http://127.0.0.1:8080/dev/token;
/etc/nginx/sites-available/pix2pi_ssl.bak_1773945801:23:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_1773945801:24:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_1773945801:28:        proxy_pass http://127.0.0.1:9016/status;
/etc/nginx/sites-available/pix2pi_ssl.bak_1773945801:29:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_1773945801:30:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_1773945801:34:        proxy_pass http://127.0.0.1:9016/health;
/etc/nginx/sites-available/pix2pi_ssl.bak_1773945801:35:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_1773945801:36:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_1773945801:51:    listen 443 ssl;
/etc/nginx/sites-available/pix2pi_ssl.bak_1773945801:52:    server_name server.pix2pi.com.tr;
/etc/nginx/sites-available/pix2pi_ssl.bak_1773945801:54:    ssl_certificate /etc/letsencrypt/live/pix2pi.com.tr/fullchain.pem;
/etc/nginx/sites-available/pix2pi_ssl.bak_1773945801:55:    ssl_certificate_key /etc/letsencrypt/live/pix2pi.com.tr/privkey.pem;
/etc/nginx/sites-available/pix2pi_ssl.bak_1773945801:64:        proxy_pass http://127.0.0.1:8080/containers/;
/etc/nginx/sites-available/pix2pi_ssl.bak_1773945801:65:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_1773945801:66:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_215025:2:    listen 443 ssl;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_215025:3:    server_name pix2pi.com.tr www.pix2pi.com.tr panel.pix2pi.com.tr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_215025:6:    ssl_certificate /etc/letsencrypt/live/pix2pi.com.tr/fullchain.pem;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_215025:7:    ssl_certificate_key /etc/letsencrypt/live/pix2pi.com.tr/privkey.pem;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_215025:23:        proxy_pass http://127.0.0.1:8080/api/health;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_215025:24:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_215025:25:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_215025:29:        proxy_pass http://127.0.0.1:8080/dev/token;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_215025:30:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_215025:31:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_215025:35:        proxy_pass http://127.0.0.1:9016/status;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_215025:36:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_215025:37:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_215025:41:        proxy_pass http://127.0.0.1:9016/health;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_215025:42:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_215025:43:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_215025:58:    listen 443 ssl;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_215025:59:    server_name server.pix2pi.com.tr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_215025:67:    ssl_certificate /etc/letsencrypt/live/pix2pi.com.tr/fullchain.pem;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_215025:68:    ssl_certificate_key /etc/letsencrypt/live/pix2pi.com.tr/privkey.pem;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_215025:77:        proxy_pass http://127.0.0.1:8080/containers/;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_215025:78:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_215025:79:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_080805:2:    listen 443 ssl;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_080805:3:    server_name pix2pi.com.tr www.pix2pi.com.tr panel.pix2pi.com.tr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_080805:6:    ssl_certificate /etc/letsencrypt/live/pix2pi.com.tr/fullchain.pem;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_080805:7:    ssl_certificate_key /etc/letsencrypt/live/pix2pi.com.tr/privkey.pem;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_080805:24:        proxy_pass http://127.0.0.1:8080/api/health;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_080805:25:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_080805:26:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_080805:30:        proxy_pass http://127.0.0.1:8080/dev/token;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_080805:31:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_080805:32:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_080805:36:        proxy_pass http://127.0.0.1:9016/status;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_080805:37:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_080805:38:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_080805:42:        proxy_pass http://127.0.0.1:9016/health;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_080805:43:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_080805:44:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_080805:59:    listen 443 ssl;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_080805:60:    server_name server.pix2pi.com.tr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_080805:68:    ssl_certificate /etc/letsencrypt/live/pix2pi.com.tr/fullchain.pem;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_080805:69:    ssl_certificate_key /etc/letsencrypt/live/pix2pi.com.tr/privkey.pem;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_080805:78:        proxy_pass http://127.0.0.1:8080/containers/;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_080805:79:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_080805:80:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi:2:    listen 80;
/etc/nginx/sites-available/pix2pi:3:    server_name _;
/etc/nginx/sites-available/pix2pi:7:        proxy_pass http://127.0.0.1:8090/status;
/etc/nginx/sites-available/pix2pi:9:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi:10:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi:11:        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
/etc/nginx/sites-available/pix2pi:12:        proxy_set_header X-Forwarded-Proto $scheme;
/etc/nginx/sites-available/pix2pi:17:        proxy_pass http://127.0.0.1:8090/health;
/etc/nginx/sites-available/pix2pi:19:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi:20:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi:21:        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
/etc/nginx/sites-available/pix2pi:22:        proxy_set_header X-Forwarded-Proto $scheme;
/etc/nginx/sites-available/pix2pi:27:        proxy_pass http://127.0.0.1:5858;
/etc/nginx/sites-available/pix2pi:29:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi:30:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi:31:        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
/etc/nginx/sites-available/pix2pi:32:        proxy_set_header X-Forwarded-Proto $scheme;
/etc/nginx/sites-available/pix2pi:37:        proxy_pass http://127.0.0.1:9001/health;
/etc/nginx/sites-available/pix2pi:39:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi:45:        proxy_pass http://127.0.0.1:9001;
/etc/nginx/sites-available/pix2pi:47:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi:48:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi:49:        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
/etc/nginx/sites-available/pix2pi:50:        proxy_set_header X-Forwarded-Proto $scheme;
/etc/nginx/sites-available/pix2pi:55:        proxy_pass http://127.0.0.1:9011;
/etc/nginx/sites-available/pix2pi:57:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi:58:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi:64:        proxy_pass http://127.0.0.1:8090/status;
/etc/nginx/sites-available/pix2pi:66:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi:67:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi:68:        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
/etc/nginx/sites-available/pix2pi:69:        proxy_set_header X-Forwarded-Proto $scheme;
/etc/nginx/sites-available/pix2pi:71:        add_header Cache-Control "no-store, no-cache, must-revalidate" always;
/etc/nginx/sites-available/pix2pi_api_gateway:3:    server_name api.pix2pi.com.tr;
/etc/nginx/sites-available/pix2pi_api_gateway:6:        limit_req zone=pix2pi_limit_zone burst=40 nodelay;
/etc/nginx/sites-available/pix2pi_api_gateway:8:        proxy_pass http://127.0.0.1:9010;
/etc/nginx/sites-available/pix2pi_api_gateway:12:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_api_gateway:13:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_api_gateway:15:        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
/etc/nginx/sites-available/pix2pi_api_gateway:21:    listen 443 ssl; # managed by Certbot
/etc/nginx/sites-available/pix2pi_api_gateway:22:    ssl_certificate /etc/letsencrypt/live/api.pix2pi.com.tr/fullchain.pem; # managed by Certbot
/etc/nginx/sites-available/pix2pi_api_gateway:23:    ssl_certificate_key /etc/letsencrypt/live/api.pix2pi.com.tr/privkey.pem; # managed by Certbot
/etc/nginx/sites-available/pix2pi_api_gateway:35:    server_name api.pix2pi.com.tr;
/etc/nginx/sites-available/pix2pi_api_gateway:36:    listen 80;
/etc/nginx/sites-available/default.bak.2026-03-19-061610:22:	listen 80 default_server;
/etc/nginx/sites-available/default.bak.2026-03-19-061610:27:	# listen 443 ssl default_server;
/etc/nginx/sites-available/default.bak.2026-03-19-061610:46:	server_name _;
/etc/nginx/sites-available/default.bak.2026-03-19-061610:65:	# deny access to .htaccess files, if Apache's document root
/etc/nginx/sites-available/default.bak.2026-03-19-061610:69:	#	deny all;
/etc/nginx/sites-available/default.bak.2026-03-19-061610:80:#	listen 80;
/etc/nginx/sites-available/default.bak.2026-03-19-061610:83:#	server_name example.com;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_214713:2:    listen 443 ssl;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_214713:3:    server_name pix2pi.com.tr www.pix2pi.com.tr panel.pix2pi.com.tr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_214713:11:    ssl_certificate /etc/letsencrypt/live/pix2pi.com.tr/fullchain.pem;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_214713:12:    ssl_certificate_key /etc/letsencrypt/live/pix2pi.com.tr/privkey.pem;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_214713:22:        proxy_pass http://127.0.0.1:8080/api/health;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_214713:23:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_214713:24:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_214713:28:        proxy_pass http://127.0.0.1:8080/dev/token;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_214713:29:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_214713:30:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_214713:34:        proxy_pass http://127.0.0.1:9016/status;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_214713:35:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_214713:36:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_214713:40:        proxy_pass http://127.0.0.1:9016/health;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_214713:41:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_214713:42:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_214713:57:    listen 443 ssl;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_214713:58:    server_name server.pix2pi.com.tr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_214713:66:    ssl_certificate /etc/letsencrypt/live/pix2pi.com.tr/fullchain.pem;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_214713:67:    ssl_certificate_key /etc/letsencrypt/live/pix2pi.com.tr/privkey.pem;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_214713:76:        proxy_pass http://127.0.0.1:8080/containers/;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_214713:77:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_214713:78:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl:2:    listen 443 ssl;
/etc/nginx/sites-available/pix2pi_ssl:5:        proxy_pass http://127.0.0.1:8090/status;
/etc/nginx/sites-available/pix2pi_ssl:7:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl:8:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl:9:        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
/etc/nginx/sites-available/pix2pi_ssl:10:        proxy_set_header X-Forwarded-Proto $scheme;
/etc/nginx/sites-available/pix2pi_ssl:12:        add_header Cache-Control "no-store, no-cache, must-revalidate" always;
/etc/nginx/sites-available/pix2pi_ssl:16:    server_name pix2pi.com.tr www.pix2pi.com.tr panel.pix2pi.com.tr;
/etc/nginx/sites-available/pix2pi_ssl:21:        proxy_pass http://127.0.0.1:8090/status;
/etc/nginx/sites-available/pix2pi_ssl:23:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl:24:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl:25:        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
/etc/nginx/sites-available/pix2pi_ssl:26:        proxy_set_header X-Forwarded-Proto $scheme;
/etc/nginx/sites-available/pix2pi_ssl:30:    ssl_certificate /etc/letsencrypt/live/pix2pi.com.tr/fullchain.pem;
/etc/nginx/sites-available/pix2pi_ssl:31:    ssl_certificate_key /etc/letsencrypt/live/pix2pi.com.tr/privkey.pem;
/etc/nginx/sites-available/pix2pi_ssl:48:        proxy_pass http://127.0.0.1:8080/api/health;
/etc/nginx/sites-available/pix2pi_ssl:49:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl:50:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl:54:        proxy_pass http://127.0.0.1:8080/dev/token;
/etc/nginx/sites-available/pix2pi_ssl:55:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl:56:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl:60:        proxy_pass http://127.0.0.1:9016/status;
/etc/nginx/sites-available/pix2pi_ssl:61:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl:62:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl:66:        proxy_pass http://127.0.0.1:9016/health;
/etc/nginx/sites-available/pix2pi_ssl:67:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl:68:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl:83:    listen 443 ssl;
/etc/nginx/sites-available/pix2pi_ssl:84:    server_name server.pix2pi.com.tr;
/etc/nginx/sites-available/pix2pi_ssl:92:    ssl_certificate /etc/letsencrypt/live/pix2pi.com.tr/fullchain.pem;
/etc/nginx/sites-available/pix2pi_ssl:93:    ssl_certificate_key /etc/letsencrypt/live/pix2pi.com.tr/privkey.pem;
/etc/nginx/sites-available/pix2pi_ssl:102:        proxy_pass http://127.0.0.1:8080/containers/;
/etc/nginx/sites-available/pix2pi_ssl:103:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl:104:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_083931:2:    listen 443 ssl;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_083931:3:    server_name pix2pi.com.tr www.pix2pi.com.tr panel.pix2pi.com.tr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_083931:6:        proxy_pass http://127.0.0.1:8090/status;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_083931:8:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_083931:9:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_083931:10:        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_083931:11:        proxy_set_header X-Forwarded-Proto $scheme;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_083931:15:        proxy_pass http://127.0.0.1:8090/health;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_083931:17:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_083931:18:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_083931:19:        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_083931:20:        proxy_set_header X-Forwarded-Proto $scheme;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_083931:24:    ssl_certificate /etc/letsencrypt/live/pix2pi.com.tr/fullchain.pem;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_083931:25:    ssl_certificate_key /etc/letsencrypt/live/pix2pi.com.tr/privkey.pem;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_083931:42:        proxy_pass http://127.0.0.1:8080/api/health;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_083931:43:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_083931:44:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_083931:48:        proxy_pass http://127.0.0.1:8080/dev/token;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_083931:49:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_083931:50:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_083931:54:        proxy_pass http://127.0.0.1:9016/status;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_083931:55:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_083931:56:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_083931:60:        proxy_pass http://127.0.0.1:9016/health;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_083931:61:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_083931:62:        proxy_set_header X-Real-IP $remote_addr;
```

## 6-10.9 Origin / Internal Port Exposure Inventory

```text
LISTEN 0      4096         0.0.0.0:6379       0.0.0.0:*    users:(("docker-proxy",pid=3788,fd=8))                                                                                                                                                                                                                             
LISTEN 0      4096       127.0.0.1:9010       0.0.0.0:*    users:(("pix2pi-api-gate",pid=4016338,fd=7))                                                                                                                                                                                                                       
LISTEN 0      4096         0.0.0.0:8080       0.0.0.0:*    users:(("docker-proxy",pid=4033,fd=8))                                                                                                                                                                                                                             
LISTEN 0      511          0.0.0.0:8002       0.0.0.0:*    users:(("nginx",pid=4520,fd=12),("nginx",pid=4519,fd=12),("nginx",pid=4518,fd=12),("nginx",pid=4517,fd=12),("nginx",pid=4516,fd=12),("nginx",pid=4515,fd=12),("nginx",pid=4514,fd=12),("nginx",pid=4513,fd=12),("nginx",pid=2172,fd=12))                           
LISTEN 0      511          0.0.0.0:8000       0.0.0.0:*    users:(("nginx",pid=4520,fd=9),("nginx",pid=4519,fd=9),("nginx",pid=4518,fd=9),("nginx",pid=4517,fd=9),("nginx",pid=4516,fd=9),("nginx",pid=4515,fd=9),("nginx",pid=4514,fd=9),("nginx",pid=4513,fd=9),("nginx",pid=2172,fd=9))                                    
LISTEN 0      511          0.0.0.0:8001       0.0.0.0:*    users:(("nginx",pid=4520,fd=10),("nginx",pid=4519,fd=10),("nginx",pid=4518,fd=10),("nginx",pid=4517,fd=10),("nginx",pid=4516,fd=10),("nginx",pid=4515,fd=10),("nginx",pid=4514,fd=10),("nginx",pid=4513,fd=10),("nginx",pid=2172,fd=10))                           
LISTEN 0      4096         0.0.0.0:4222       0.0.0.0:*    users:(("docker-proxy",pid=1036365,fd=8))                                                                                                                                                                                                                          
LISTEN 0      4096         0.0.0.0:5433       0.0.0.0:*    users:(("docker-proxy",pid=1294029,fd=8))                                                                                                                                                                                                                          
LISTEN 0      4096         0.0.0.0:3001       0.0.0.0:*    users:(("docker-proxy",pid=2738,fd=8))                                                                                                                                                                                                                             
LISTEN 0      511          0.0.0.0:80         0.0.0.0:*    users:(("nginx",pid=2611616,fd=9),("nginx",pid=1299415,fd=9),("nginx",pid=1299414,fd=9),("nginx",pid=1299413,fd=9),("nginx",pid=1299412,fd=9),("nginx",pid=1299411,fd=9),("nginx",pid=1299410,fd=9),("nginx",pid=1299409,fd=9),("nginx",pid=1299407,fd=9))         
LISTEN 0      4096         0.0.0.0:8222       0.0.0.0:*    users:(("docker-proxy",pid=1036391,fd=8))                                                                                                                                                                                                                          
LISTEN 0      511          0.0.0.0:443        0.0.0.0:*    users:(("nginx",pid=2611616,fd=10),("nginx",pid=1299415,fd=10),("nginx",pid=1299414,fd=10),("nginx",pid=1299413,fd=10),("nginx",pid=1299412,fd=10),("nginx",pid=1299411,fd=10),("nginx",pid=1299410,fd=10),("nginx",pid=1299409,fd=10),("nginx",pid=1299407,fd=10))
LISTEN 0      4096       127.0.0.1:8007       0.0.0.0:*    users:(("nginx",pid=4520,fd=21),("nginx",pid=2172,fd=21))                                                                                                                                                                                                          
LISTEN 0      4096       127.0.0.1:8007       0.0.0.0:*    users:(("nginx",pid=4519,fd=20),("nginx",pid=2172,fd=20))                                                                                                                                                                                                          
LISTEN 0      4096       127.0.0.1:8007       0.0.0.0:*    users:(("nginx",pid=4518,fd=19),("nginx",pid=2172,fd=19))                                                                                                                                                                                                          
LISTEN 0      4096       127.0.0.1:8007       0.0.0.0:*    users:(("nginx",pid=4517,fd=18),("nginx",pid=2172,fd=18))                                                                                                                                                                                                          
LISTEN 0      4096       127.0.0.1:8007       0.0.0.0:*    users:(("nginx",pid=4516,fd=17),("nginx",pid=2172,fd=17))                                                                                                                                                                                                          
LISTEN 0      4096       127.0.0.1:8007       0.0.0.0:*    users:(("nginx",pid=4515,fd=16),("nginx",pid=2172,fd=16))                                                                                                                                                                                                          
LISTEN 0      4096       127.0.0.1:8007       0.0.0.0:*    users:(("nginx",pid=4514,fd=15),("nginx",pid=2172,fd=15))                                                                                                                                                                                                          
LISTEN 0      4096       127.0.0.1:8007       0.0.0.0:*    users:(("nginx",pid=4513,fd=11),("nginx",pid=2172,fd=11))                                                                                                                                                                                                          
LISTEN 0      511        127.0.0.1:8099       0.0.0.0:*    users:(("nginx",pid=2611616,fd=8),("nginx",pid=1299415,fd=8),("nginx",pid=1299414,fd=8),("nginx",pid=1299413,fd=8),("nginx",pid=1299412,fd=8),("nginx",pid=1299411,fd=8),("nginx",pid=1299410,fd=8),("nginx",pid=1299409,fd=8),("nginx",pid=1299407,fd=8))         
LISTEN 0      4096         0.0.0.0:9090       0.0.0.0:*    users:(("docker-proxy",pid=2893,fd=8))                                                                                                                                                                                                                             
LISTEN 0      4096         0.0.0.0:9100       0.0.0.0:*    users:(("docker-proxy",pid=3938,fd=8))                                                                                                                                                                                                                             
LISTEN 0      4096         0.0.0.0:9002       0.0.0.0:*    users:(("docker-proxy",pid=2986,fd=8))                                                                                                                                                                                                                             
LISTEN 0      4096            [::]:6379          [::]:*    users:(("docker-proxy",pid=3795,fd=8))                                                                                                                                                                                                                             
LISTEN 0      4096            [::]:8080          [::]:*    users:(("docker-proxy",pid=4051,fd=8))                                                                                                                                                                                                                             
LISTEN 0      4096               *:8091             *:*    users:(("query-read-mode",pid=6735,fd=3))                                                                                                                                                                                                                          
LISTEN 0      4096            [::]:4222          [::]:*    users:(("docker-proxy",pid=1036374,fd=8))                                                                                                                                                                                                                          
LISTEN 0      4096            [::]:5433          [::]:*    users:(("docker-proxy",pid=1294037,fd=8))                                                                                                                                                                                                                          
LISTEN 0      4096            [::]:3001          [::]:*    users:(("docker-proxy",pid=2778,fd=8))                                                                                                                                                                                                                             
LISTEN 0      4096            [::]:8222          [::]:*    users:(("docker-proxy",pid=1036398,fd=8))                                                                                                                                                                                                                          
LISTEN 0      4096            [::]:9090          [::]:*    users:(("docker-proxy",pid=2902,fd=8))                                                                                                                                                                                                                             
LISTEN 0      4096            [::]:9100          [::]:*    users:(("docker-proxy",pid=3958,fd=8))                                                                                                                                                                                                                             
LISTEN 0      4096            [::]:9002          [::]:*    users:(("docker-proxy",pid=3006,fd=8))                                                                                                                                                                                                                             
```

## 6-10.10 Edge Logs Inventory

```text
===== /var/log/nginx/access.log =====
93.158.90.66 - - [01/May/2026:14:08:36 +0300] "GET /robots.txt HTTP/1.1" 301 178 "-" "Mozilla/5.0 (iPhone; CPU iPhone OS 16_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/122.0.6261.89 Mobile/15E148 Safari/604"
93.158.90.65 - - [01/May/2026:14:08:37 +0300] "GET /robots.txt HTTP/1.1" 200 10 "http://pix2pi.com.tr/robots.txt" "Mozilla/5.0 (iPhone; CPU iPhone OS 16_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/122.0.6261.89 Mobile/15E148 Safari/604"
141.98.48.42 - - [01/May/2026:15:29:43 +0300] "" 400 0 "-" "-"
141.98.48.42 - - [01/May/2026:15:38:21 +0300] "" 400 0 "-" "-"
74.7.175.189 - - [01/May/2026:15:43:19 +0300] "GET /robots.txt HTTP/2.0" 200 10 "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36; compatible; OAI-SearchBot/1.3; robots.txt; +https://openai.com/searchbot"
74.7.241.15 - - [01/May/2026:15:43:20 +0300] "GET / HTTP/2.0" 200 10 "-" "Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; GPTBot/1.3; +https://openai.com/gptbot)"
141.98.48.42 - - [01/May/2026:15:47:08 +0300] "" 400 0 "-" "-"
141.98.48.42 - - [01/May/2026:15:52:50 +0300] "" 400 0 "-" "-"
===== /var/log/nginx/error.log =====
===== /var/log/fail2ban.log =====
===== /var/log/auth.log =====
Apr 26 03:36:44 vm12827 sshd[3306936]: Invalid user bot from 87.251.64.147 port 12380
Apr 26 03:36:44 vm12827 sshd[3306936]: Connection reset by invalid user bot 87.251.64.147 port 12380 [preauth]
Apr 26 08:46:38 vm12827 sshd[3506238]: Invalid user bot from 182.253.156.173 port 60442
Apr 26 08:46:38 vm12827 sshd[3506238]: Disconnected from invalid user bot 182.253.156.173 port 60442 [preauth]
Apr 26 13:34:26 vm12827 sshd[3669900]: Invalid user bot from 152.244.204.158 port 46804
Apr 26 13:34:27 vm12827 sshd[3669900]: Disconnected from invalid user bot 152.244.204.158 port 46804 [preauth]
```

## 6-10.11 Edge Guard Scripts Probe

```text
===== PIX2PI EDGE DNS PROBE BASLADI =====
===== DNS PROBE: pix2pi.com.tr =====
--- A ---
141.98.48.42
--- AAAA ---
--- CNAME ---
--- TTL/SOA TRACE ---
pix2pi.com.tr.		295	IN	A	141.98.48.42
pix2pi.com.tr DNS_RESOLVES OK ✅

===== DNS PROBE: www.pix2pi.com.tr =====
--- A ---
141.98.48.42
--- AAAA ---
--- CNAME ---
--- TTL/SOA TRACE ---
www.pix2pi.com.tr.	296	IN	A	141.98.48.42
www.pix2pi.com.tr DNS_RESOLVES OK ✅

===== DNS PROBE: api.pix2pi.com.tr =====
--- A ---
141.98.48.42
--- AAAA ---
--- CNAME ---
--- TTL/SOA TRACE ---
api.pix2pi.com.tr.	296	IN	A	141.98.48.42
api.pix2pi.com.tr DNS_RESOLVES OK ✅

===== DNS PROBE: panel.pix2pi.com.tr =====
--- A ---
141.98.48.42
--- AAAA ---
--- CNAME ---
--- TTL/SOA TRACE ---
panel.pix2pi.com.tr.	296	IN	A	141.98.48.42
panel.pix2pi.com.tr DNS_RESOLVES OK ✅

===== DNS PROBE: auth.pix2pi.com.tr =====
--- A ---
141.98.48.42
--- AAAA ---
--- CNAME ---
--- TTL/SOA TRACE ---
auth.pix2pi.com.tr.	296	IN	A	141.98.48.42
auth.pix2pi.com.tr DNS_RESOLVES OK ✅

===== DNS PROBE: pos.pix2pi.com.tr =====
--- A ---
141.98.48.42
--- AAAA ---
--- CNAME ---
--- TTL/SOA TRACE ---
pos.pix2pi.com.tr.	296	IN	A	141.98.48.42
pos.pix2pi.com.tr DNS_RESOLVES OK ✅

PASS_COUNT=6
WARN_COUNT=0
FAZ_6_10_EDGE_DNS_PROBE_STATUS=COMPLETE ✅
FAZ_6_10_EDGE_DNS_WARN_STATUS=CLEAR ✅
OK ✅ evidence yazildi: docs/faz6/evidence/FAZ_6_10_EDGE_DNS_PROBE_EVIDENCE.md

===== PIX2PI EDGE HTTP SMOKE BASLADI =====
===== EDGE HTTP SMOKE: root https =====
URL=https://pix2pi.com.tr/
http_code=200 time_total=0.092643 size=10 remote_ip=141.98.48.42
--- headers first 100 lines ---
HTTP/2 200 
server: nginx/1.18.0 (Ubuntu)
date: Fri, 01 May 2026 12:52:52 GMT
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
http_code=200 time_total=0.120182 size=10 remote_ip=141.98.48.42
--- headers first 100 lines ---
HTTP/2 200 
server: nginx/1.18.0 (Ubuntu)
date: Fri, 01 May 2026 12:52:52 GMT
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
http_code=200 time_total=0.150347 size=8452 remote_ip=141.98.48.42
--- headers first 100 lines ---
HTTP/2 200 
server: nginx/1.18.0 (Ubuntu)
date: Fri, 01 May 2026 12:52:52 GMT
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
http_code=200 time_total=0.164141 size=10 remote_ip=141.98.48.42
--- headers first 100 lines ---
HTTP/1.1 301 Moved Permanently
Server: nginx/1.18.0 (Ubuntu)
Date: Fri, 01 May 2026 12:52:52 GMT
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
date: Fri, 01 May 2026 12:52:52 GMT
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

PASS_COUNT=8
WARN_COUNT=0
INFO_COUNT=4
FAZ_6_10_EDGE_HTTP_SMOKE_STATUS=COMPLETE ✅
FAZ_6_10_CLOUDFLARE_PROXY_STATUS=DISABLED_OR_NOT_DETECTED_INFO ✅
FAZ_6_10_EDGE_HTTP_WARN_STATUS=CLEAR ✅
OK ✅ evidence yazildi: docs/faz6/evidence/FAZ_6_10_EDGE_HTTP_SMOKE_EVIDENCE.md
```

## 6-10.12 Runtime Audit Interpretation

```text
6-10.1 Host inventory collected OK ✅
6-10.2 DNS resolution runtime collected OK ✅
6-10.3 TLS certificate probe collected OK ✅
6-10.4 Public HTTPS header probe collected OK ✅
6-10.5 Public GET content probe collected OK ✅
6-10.6 Public pilot GET content probe collected OK ✅
6-10.7 HTTP redirect probe collected OK ✅
6-10.8 Nginx edge config inventory collected OK ✅
6-10.9 Origin/internal port exposure inventory collected OK ✅
6-10.10 Edge logs inventory collected OK ✅
6-10.11 Edge guard scripts probe collected OK ✅
FAZ_6_10_RUNTIME_AUDIT=COMPLETE ✅
```
