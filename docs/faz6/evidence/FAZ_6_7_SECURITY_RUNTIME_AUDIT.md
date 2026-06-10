# FAZ 6-7 Security Runtime Audit Evidence

Generated At: 2026-05-01T14:58:40+03:00  
Host: vm12827.ovadns.com  
Repo: /root/pix2pi/pix2pi-SaaS  

Bu audit runtime ortaminda security hardening / production guardrail izlerini toplar. Destructive islem yapmaz.

FAZ_6_7_RUNTIME_AUDIT=STARTED ✅

---


## 6-7.1 Host / Kernel

```text
Linux vm12827.ovadns.com 5.15.0-176-generic #186-Ubuntu SMP Fri Mar 13 11:01:42 UTC 2026 x86_64 x86_64 x86_64 GNU/Linux
```

## 6-7.2 User / Permission Context

```text
uid=0(root) gid=0(root) groups=0(root),998(ollama)
0022
/root/pix2pi/pix2pi-SaaS
```

## 6-7.3 Env / Secret File Permission Inventory

```text
===== .env =====
-rw------- 1 root root 410 Apr 27 07:52 .env
DB_HOST=localhost
DB_PORT=5433
DB_USER=pix2pi
DB_PASSWORD=***MASKED***
DB_NAME=pix2pi
REDIS_HOST=localhost
REDIS_PORT=6379
JWT_SECRET=***MASKED***
DB_READ_DSN=postgres://user:pass@localhost:5433/dbname?sslmode=disable
DB_WRITE_DSN=postgres://pix2pi:pix2pi@127.0.0.1:5433/pix2pi?sslmode=disable
DB_DSN=postgres://pix2pi:pix2pi@127.0.0.1:5433/pix2pi?sslmode=disable
WARN ⚠️ missing: .env.production
===== /etc/pix2pi/ports.env =====
-rw------- 1 root root 1023 Apr 25 00:43 /etc/pix2pi/ports.env
===== /opt/pix2pi/orchestrator/env/common.env =====
-rw-r--r-- 1 root root 398 Apr 18 09:11 /opt/pix2pi/orchestrator/env/common.env
DB_WRITE_DSN="host=localhost port=5433 user=pix2pi password=***MASKED*** dbname=pix2pi sslmode=disable"
DB_READ_DSN="host=localhost port=5433 user=pix2pi password=***MASKED*** dbname=pix2pi sslmode=disable"
JWT_SECRET=***MASKED***
```

## 6-7.4 Nginx Syntax / Security Inventory

```text
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful

===== nginx security grep =====
/etc/nginx/sites-available/pix2pi.bak_20260320_080106:10:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi.bak_20260320_080106:11:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi.bak_20260320_080106:12:        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
/etc/nginx/sites-available/pix2pi.bak_20260320_080106:13:        proxy_set_header X-Forwarded-Proto $scheme;
/etc/nginx/sites-available/pix2pi.bak_20260320_080106:21:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi.bak_20260320_080106:29:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi.bak_20260320_080106:30:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi.bak_20260320_080106:31:        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
/etc/nginx/sites-available/pix2pi.bak_20260320_080106:32:        proxy_set_header X-Forwarded-Proto $scheme;
/etc/nginx/sites-available/pix2pi.bak_20260320_080106:39:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi.bak_20260320_080106:40:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_1773945801:8:    ssl_protocols TLSv1.2 TLSv1.3;
/etc/nginx/sites-available/pix2pi_ssl.bak_1773945801:17:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_1773945801:18:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_1773945801:23:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_1773945801:24:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_1773945801:29:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_1773945801:30:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_1773945801:35:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_1773945801:36:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_1773945801:57:    ssl_protocols TLSv1.2 TLSv1.3;
/etc/nginx/sites-available/pix2pi_ssl.bak_1773945801:65:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_1773945801:66:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_215025:9:    ssl_protocols TLSv1.2 TLSv1.3;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_215025:24:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_215025:25:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_215025:30:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_215025:31:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_215025:36:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_215025:37:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_215025:42:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_215025:43:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_215025:70:    ssl_protocols TLSv1.2 TLSv1.3;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_215025:78:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_215025:79:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_080805:9:    ssl_protocols TLSv1.2 TLSv1.3;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_080805:25:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_080805:26:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_080805:31:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_080805:32:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_080805:37:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_080805:38:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_080805:43:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_080805:44:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_080805:71:    ssl_protocols TLSv1.2 TLSv1.3;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_080805:79:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_080805:80:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi:9:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi:10:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi:11:        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
/etc/nginx/sites-available/pix2pi:12:        proxy_set_header X-Forwarded-Proto $scheme;
/etc/nginx/sites-available/pix2pi:19:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi:20:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi:21:        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
/etc/nginx/sites-available/pix2pi:22:        proxy_set_header X-Forwarded-Proto $scheme;
/etc/nginx/sites-available/pix2pi:29:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi:30:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi:31:        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
/etc/nginx/sites-available/pix2pi:32:        proxy_set_header X-Forwarded-Proto $scheme;
/etc/nginx/sites-available/pix2pi:39:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi:47:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi:48:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi:49:        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
/etc/nginx/sites-available/pix2pi:50:        proxy_set_header X-Forwarded-Proto $scheme;
/etc/nginx/sites-available/pix2pi:57:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi:58:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi:66:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi:67:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi:68:        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
/etc/nginx/sites-available/pix2pi:69:        proxy_set_header X-Forwarded-Proto $scheme;
/etc/nginx/sites-available/pix2pi:71:        add_header Cache-Control "no-store, no-cache, must-revalidate" always;
/etc/nginx/sites-available/pix2pi_api_gateway:6:        limit_req zone=pix2pi_limit_zone burst=40 nodelay;
/etc/nginx/sites-available/pix2pi_api_gateway:12:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_api_gateway:13:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_api_gateway:15:        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
/etc/nginx/sites-available/default.bak.2026-03-19-061610:33:	# Read up on ssl_ciphers to ensure a secure configuration.
/etc/nginx/sites-available/default.bak.2026-03-19-061610:65:	# deny access to .htaccess files, if Apache's document root
/etc/nginx/sites-available/default.bak.2026-03-19-061610:69:	#	deny all;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_214713:14:    ssl_protocols TLSv1.2 TLSv1.3;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_214713:23:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_214713:24:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_214713:29:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_214713:30:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_214713:35:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_214713:36:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_214713:41:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_214713:42:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_214713:69:    ssl_protocols TLSv1.2 TLSv1.3;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_214713:77:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_214713:78:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl:7:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl:8:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl:9:        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
/etc/nginx/sites-available/pix2pi_ssl:10:        proxy_set_header X-Forwarded-Proto $scheme;
/etc/nginx/sites-available/pix2pi_ssl:12:        add_header Cache-Control "no-store, no-cache, must-revalidate" always;
/etc/nginx/sites-available/pix2pi_ssl:23:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl:24:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl:25:        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
/etc/nginx/sites-available/pix2pi_ssl:26:        proxy_set_header X-Forwarded-Proto $scheme;
/etc/nginx/sites-available/pix2pi_ssl:33:    ssl_protocols TLSv1.2 TLSv1.3;
/etc/nginx/sites-available/pix2pi_ssl:49:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl:50:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl:55:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl:56:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl:61:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl:62:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl:67:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl:68:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl:95:    ssl_protocols TLSv1.2 TLSv1.3;
/etc/nginx/sites-available/pix2pi_ssl:103:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl:104:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_083931:8:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_083931:9:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_083931:10:        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_083931:11:        proxy_set_header X-Forwarded-Proto $scheme;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_083931:17:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_083931:18:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_083931:19:        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_083931:20:        proxy_set_header X-Forwarded-Proto $scheme;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_083931:27:    ssl_protocols TLSv1.2 TLSv1.3;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_083931:43:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_083931:44:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_083931:49:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_083931:50:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_083931:55:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_083931:56:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_083931:61:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_083931:62:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_083931:89:    ssl_protocols TLSv1.2 TLSv1.3;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_083931:97:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_083931:98:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi.bak_20260304_115445:8:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi.bak_20260304_115445:19:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi.bak_20260320_083246:9:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi.bak_20260320_083246:10:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi.bak_20260320_083246:11:        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
/etc/nginx/sites-available/pix2pi.bak_20260320_083246:12:        proxy_set_header X-Forwarded-Proto $scheme;
/etc/nginx/sites-available/pix2pi.bak_20260320_083246:19:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi.bak_20260320_083246:20:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi.bak_20260320_083246:21:        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
/etc/nginx/sites-available/pix2pi.bak_20260320_083246:22:        proxy_set_header X-Forwarded-Proto $scheme;
/etc/nginx/sites-available/pix2pi.bak_20260320_083246:29:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi.bak_20260320_083246:30:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi.bak_20260320_083246:31:        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
/etc/nginx/sites-available/pix2pi.bak_20260320_083246:32:        proxy_set_header X-Forwarded-Proto $scheme;
/etc/nginx/sites-available/pix2pi.bak_20260320_083246:39:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi.bak_20260320_083246:47:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi.bak_20260320_083246:48:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi.bak_20260320_083246:49:        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
/etc/nginx/sites-available/pix2pi.bak_20260320_083246:50:        proxy_set_header X-Forwarded-Proto $scheme;
/etc/nginx/sites-available/pix2pi.bak_20260320_083246:57:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi.bak_20260320_083246:58:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/default:33:	# Read up on ssl_ciphers to ensure a secure configuration.
/etc/nginx/sites-available/default:67:	# deny access to .htaccess files, if Apache's document root
/etc/nginx/sites-available/default:71:	#	deny all;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_084317:7:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_084317:8:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_084317:9:        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_084317:10:        proxy_set_header X-Forwarded-Proto $scheme;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_084317:12:        add_header Cache-Control "no-store, no-cache, must-revalidate" always;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_084317:19:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_084317:20:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_084317:21:        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_084317:22:        proxy_set_header X-Forwarded-Proto $scheme;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_084317:29:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_084317:30:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_084317:31:        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_084317:32:        proxy_set_header X-Forwarded-Proto $scheme;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_084317:38:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_084317:39:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_084317:40:        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_084317:41:        proxy_set_header X-Forwarded-Proto $scheme;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_084317:48:    ssl_protocols TLSv1.2 TLSv1.3;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_084317:64:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_084317:65:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_084317:70:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_084317:71:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_084317:76:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_084317:77:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_084317:82:        proxy_set_header Host $host;
```

## 6-7.5 Listening Port Inventory

```text
LISTEN 0      128          0.0.0.0:22         0.0.0.0:*    users:(("sshd",pid=3420905,fd=3))                                                                                                                                                                                                                          
LISTEN 0      128          0.0.0.0:4383       0.0.0.0:*    users:(("sshd",pid=3420905,fd=5))                                                                                                                                                                                                                          
LISTEN 0      128             [::]:22            [::]:*    users:(("sshd",pid=3420905,fd=4))                                                                                                                                                                                                                          
LISTEN 0      128             [::]:4383          [::]:*    users:(("sshd",pid=3420905,fd=6))                                                                                                                                                                                                                          
LISTEN 0      4096         0.0.0.0:3001       0.0.0.0:*    users:(("docker-proxy",pid=2738,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096         0.0.0.0:3100       0.0.0.0:*    users:(("docker-proxy",pid=3328,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096         0.0.0.0:3200       0.0.0.0:*    users:(("docker-proxy",pid=3535,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096         0.0.0.0:4222       0.0.0.0:*    users:(("docker-proxy",pid=3151,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096         0.0.0.0:4317       0.0.0.0:*    users:(("docker-proxy",pid=3615,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096         0.0.0.0:4318       0.0.0.0:*    users:(("docker-proxy",pid=3681,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096         0.0.0.0:5433       0.0.0.0:*    users:(("docker-proxy",pid=1294029,fd=8))                                                                                                                                                                                                                  
LISTEN 0      4096         0.0.0.0:5434       0.0.0.0:*    users:(("docker-proxy",pid=3064,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096         0.0.0.0:5880       0.0.0.0:*    users:(("pix2pi-jobs-run",pid=1918914,fd=3))                                                                                                                                                                                                               
LISTEN 0      4096         0.0.0.0:5890       0.0.0.0:*    users:(("pix2pi-webhook-",pid=1957197,fd=3))                                                                                                                                                                                                               
LISTEN 0      4096         0.0.0.0:5900       0.0.0.0:*    users:(("pix2pi-workflow",pid=1976507,fd=3))                                                                                                                                                                                                               
LISTEN 0      4096         0.0.0.0:5910       0.0.0.0:*    users:(("pix2pi-plugin-r",pid=2001122,fd=3))                                                                                                                                                                                                               
LISTEN 0      4096         0.0.0.0:5920       0.0.0.0:*    users:(("pix2pi-publicap",pid=2014257,fd=3))                                                                                                                                                                                                               
LISTEN 0      4096         0.0.0.0:5930       0.0.0.0:*    users:(("pix2pi-notifica",pid=2069336,fd=3))                                                                                                                                                                                                               
LISTEN 0      4096         0.0.0.0:5940       0.0.0.0:*    users:(("pix2pi-early-wa",pid=2298782,fd=3))                                                                                                                                                                                                               
LISTEN 0      4096         0.0.0.0:5950       0.0.0.0:*    users:(("pix2pi-incident",pid=2320945,fd=3))                                                                                                                                                                                                               
LISTEN 0      4096         0.0.0.0:5960       0.0.0.0:*    users:(("pix2pi-runtime-",pid=2342225,fd=3))                                                                                                                                                                                                               
LISTEN 0      4096         0.0.0.0:5970       0.0.0.0:*    users:(("pix2pi-realtime",pid=2365057,fd=3))                                                                                                                                                                                                               
LISTEN 0      4096         0.0.0.0:6379       0.0.0.0:*    users:(("docker-proxy",pid=3788,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096         0.0.0.0:7100       0.0.0.0:*    users:(("pix2pi-panel",pid=2377074,fd=4))                                                                                                                                                                                                                  
LISTEN 0      4096         0.0.0.0:8080       0.0.0.0:*    users:(("docker-proxy",pid=4033,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096         0.0.0.0:8222       0.0.0.0:*    users:(("docker-proxy",pid=3226,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096         0.0.0.0:9002       0.0.0.0:*    users:(("docker-proxy",pid=2986,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096         0.0.0.0:9090       0.0.0.0:*    users:(("docker-proxy",pid=2893,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096         0.0.0.0:9100       0.0.0.0:*    users:(("docker-proxy",pid=3938,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096         0.0.0.0:9101       0.0.0.0:*    users:(("docker-proxy",pid=3412,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096       127.0.0.1:11434      0.0.0.0:*    users:(("ollama",pid=967,fd=3))                                                                                                                                                                                                                            
LISTEN 0      4096       127.0.0.1:8007       0.0.0.0:*    users:(("nginx",pid=4513,fd=11),("nginx",pid=2172,fd=11))                                                                                                                                                                                                  
LISTEN 0      4096       127.0.0.1:8007       0.0.0.0:*    users:(("nginx",pid=4514,fd=15),("nginx",pid=2172,fd=15))                                                                                                                                                                                                  
LISTEN 0      4096       127.0.0.1:8007       0.0.0.0:*    users:(("nginx",pid=4515,fd=16),("nginx",pid=2172,fd=16))                                                                                                                                                                                                  
LISTEN 0      4096       127.0.0.1:8007       0.0.0.0:*    users:(("nginx",pid=4516,fd=17),("nginx",pid=2172,fd=17))                                                                                                                                                                                                  
LISTEN 0      4096       127.0.0.1:8007       0.0.0.0:*    users:(("nginx",pid=4517,fd=18),("nginx",pid=2172,fd=18))                                                                                                                                                                                                  
LISTEN 0      4096       127.0.0.1:8007       0.0.0.0:*    users:(("nginx",pid=4518,fd=19),("nginx",pid=2172,fd=19))                                                                                                                                                                                                  
LISTEN 0      4096       127.0.0.1:8007       0.0.0.0:*    users:(("nginx",pid=4519,fd=20),("nginx",pid=2172,fd=20))                                                                                                                                                                                                  
LISTEN 0      4096       127.0.0.1:8007       0.0.0.0:*    users:(("nginx",pid=4520,fd=21),("nginx",pid=2172,fd=21))                                                                                                                                                                                                  
LISTEN 0      4096       127.0.0.1:9010       0.0.0.0:*    users:(("pix2pi-api-gate",pid=4016338,fd=7))                                                                                                                                                                                                               
LISTEN 0      4096   127.0.0.53%lo:53         0.0.0.0:*    users:(("systemd-resolve",pid=932,fd=14))                                                                                                                                                                                                                  
LISTEN 0      4096            [::]:3001          [::]:*    users:(("docker-proxy",pid=2778,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096            [::]:3100          [::]:*    users:(("docker-proxy",pid=3342,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096            [::]:3200          [::]:*    users:(("docker-proxy",pid=3552,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096            [::]:4222          [::]:*    users:(("docker-proxy",pid=3165,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096            [::]:4317          [::]:*    users:(("docker-proxy",pid=3623,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096            [::]:4318          [::]:*    users:(("docker-proxy",pid=3698,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096            [::]:5433          [::]:*    users:(("docker-proxy",pid=1294037,fd=8))                                                                                                                                                                                                                  
LISTEN 0      4096            [::]:5434          [::]:*    users:(("docker-proxy",pid=3072,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096               *:5860             *:*    users:(("pix2pi-mission-",pid=1900284,fd=3))                                                                                                                                                                                                               
LISTEN 0      4096               *:5870             *:*    users:(("service_registr",pid=6830,fd=3))                                                                                                                                                                                                                  
LISTEN 0      4096            [::]:6379          [::]:*    users:(("docker-proxy",pid=3795,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096            [::]:8080          [::]:*    users:(("docker-proxy",pid=4051,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096               *:8091             *:*    users:(("query-read-mode",pid=6735,fd=3))                                                                                                                                                                                                                  
LISTEN 0      4096            [::]:8222          [::]:*    users:(("docker-proxy",pid=3256,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096            [::]:9002          [::]:*    users:(("docker-proxy",pid=3006,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096               *:9012             *:*    users:(("identity-api",pid=6565,fd=6))                                                                                                                                                                                                                     
LISTEN 0      4096            [::]:9090          [::]:*    users:(("docker-proxy",pid=2902,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096            [::]:9100          [::]:*    users:(("docker-proxy",pid=3958,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096            [::]:9101          [::]:*    users:(("docker-proxy",pid=3426,fd=8))                                                                                                                                                                                                                     
LISTEN 0      511          0.0.0.0:443        0.0.0.0:*    users:(("nginx",pid=2611616,fd=10),("nginx",pid=308628,fd=10),("nginx",pid=308626,fd=10),("nginx",pid=308625,fd=10),("nginx",pid=308624,fd=10),("nginx",pid=308623,fd=10),("nginx",pid=308621,fd=10),("nginx",pid=308620,fd=10),("nginx",pid=308619,fd=10))
LISTEN 0      511          0.0.0.0:8000       0.0.0.0:*    users:(("nginx",pid=4520,fd=9),("nginx",pid=4519,fd=9),("nginx",pid=4518,fd=9),("nginx",pid=4517,fd=9),("nginx",pid=4516,fd=9),("nginx",pid=4515,fd=9),("nginx",pid=4514,fd=9),("nginx",pid=4513,fd=9),("nginx",pid=2172,fd=9))                            
LISTEN 0      511          0.0.0.0:80         0.0.0.0:*    users:(("nginx",pid=2611616,fd=9),("nginx",pid=308628,fd=9),("nginx",pid=308626,fd=9),("nginx",pid=308625,fd=9),("nginx",pid=308624,fd=9),("nginx",pid=308623,fd=9),("nginx",pid=308621,fd=9),("nginx",pid=308620,fd=9),("nginx",pid=308619,fd=9))         
LISTEN 0      511          0.0.0.0:8001       0.0.0.0:*    users:(("nginx",pid=4520,fd=10),("nginx",pid=4519,fd=10),("nginx",pid=4518,fd=10),("nginx",pid=4517,fd=10),("nginx",pid=4516,fd=10),("nginx",pid=4515,fd=10),("nginx",pid=4514,fd=10),("nginx",pid=4513,fd=10),("nginx",pid=2172,fd=10))                   
LISTEN 0      511          0.0.0.0:8002       0.0.0.0:*    users:(("nginx",pid=4520,fd=12),("nginx",pid=4519,fd=12),("nginx",pid=4518,fd=12),("nginx",pid=4517,fd=12),("nginx",pid=4516,fd=12),("nginx",pid=4515,fd=12),("nginx",pid=4514,fd=12),("nginx",pid=4513,fd=12),("nginx",pid=2172,fd=12))                   
LISTEN 0      511          0.0.0.0:8445       0.0.0.0:*    users:(("nginx",pid=4520,fd=13),("nginx",pid=4519,fd=13),("nginx",pid=4518,fd=13),("nginx",pid=4517,fd=13),("nginx",pid=4516,fd=13),("nginx",pid=4515,fd=13),("nginx",pid=4514,fd=13),("nginx",pid=4513,fd=13),("nginx",pid=2172,fd=13))                   
LISTEN 0      511        127.0.0.1:8099       0.0.0.0:*    users:(("nginx",pid=2611616,fd=8),("nginx",pid=308628,fd=8),("nginx",pid=308626,fd=8),("nginx",pid=308625,fd=8),("nginx",pid=308624,fd=8),("nginx",pid=308623,fd=8),("nginx",pid=308621,fd=8),("nginx",pid=308620,fd=8),("nginx",pid=308619,fd=8))         
State  Recv-Q Send-Q Local Address:Port  Peer Address:PortProcess                                                                                                                                                                                                                                                     
```

## 6-7.6 UFW / Firewall Status

```text
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), deny (routed)
New profiles: skip

To                         Action      From
--                         ------      ----
4383/tcp                   ALLOW IN    Anywhere                  
80/tcp                     ALLOW IN    Anywhere                  
443/tcp                    ALLOW IN    Anywhere                  
8088/tcp                   ALLOW IN    Anywhere                  
5858/tcp                   ALLOW IN    Anywhere                  
5860/tcp                   ALLOW IN    Anywhere                  
22/tcp (OpenSSH)           ALLOW IN    Anywhere                  
4383/tcp (v6)              ALLOW IN    Anywhere (v6)             
80/tcp (v6)                ALLOW IN    Anywhere (v6)             
443/tcp (v6)               ALLOW IN    Anywhere (v6)             
8088/tcp (v6)              ALLOW IN    Anywhere (v6)             
5858/tcp (v6)              ALLOW IN    Anywhere (v6)             
5860/tcp (v6)              ALLOW IN    Anywhere (v6)             
22/tcp (OpenSSH (v6))      ALLOW IN    Anywhere (v6)             


-P INPUT DROP
-P FORWARD DROP
-P OUTPUT ACCEPT
-N DOCKER
-N DOCKER-BRIDGE
-N DOCKER-CT
-N DOCKER-FORWARD
-N DOCKER-INTERNAL
-N DOCKER-USER
-N f2b-sshd
-N ufw-after-forward
-N ufw-after-input
-N ufw-after-logging-forward
-N ufw-after-logging-input
-N ufw-after-logging-output
-N ufw-after-output
-N ufw-before-forward
-N ufw-before-input
-N ufw-before-logging-forward
-N ufw-before-logging-input
-N ufw-before-logging-output
-N ufw-before-output
-N ufw-logging-allow
-N ufw-logging-deny
-N ufw-not-local
-N ufw-reject-forward
-N ufw-reject-input
-N ufw-reject-output
-N ufw-skip-to-policy-forward
-N ufw-skip-to-policy-input
-N ufw-skip-to-policy-output
-N ufw-track-forward
-N ufw-track-input
-N ufw-track-output
-N ufw-user-forward
-N ufw-user-input
-N ufw-user-limit
-N ufw-user-limit-accept
-N ufw-user-logging-forward
-N ufw-user-logging-input
-N ufw-user-logging-output
-N ufw-user-output
-A INPUT -p tcp -m multiport --dports 4383 -j f2b-sshd
-A INPUT -j ufw-before-logging-input
-A INPUT -j ufw-before-input
-A INPUT -j ufw-after-input
-A INPUT -j ufw-after-logging-input
-A INPUT -j ufw-reject-input
-A INPUT -j ufw-track-input
-A FORWARD -j DOCKER-USER
-A FORWARD -j DOCKER-FORWARD
-A FORWARD -j ufw-before-logging-forward
-A FORWARD -j ufw-before-forward
-A FORWARD -j ufw-after-forward
-A FORWARD -j ufw-after-logging-forward
-A FORWARD -j ufw-reject-forward
-A FORWARD -j ufw-track-forward
-A OUTPUT -j ufw-before-logging-output
-A OUTPUT -j ufw-before-output
-A OUTPUT -j ufw-after-output
-A OUTPUT -j ufw-after-logging-output
-A OUTPUT -j ufw-reject-output
-A OUTPUT -j ufw-track-output
-A DOCKER -d 172.22.0.3/32 ! -i br-3114049d7c2f -o br-3114049d7c2f -p tcp -m tcp --dport 5432 -j ACCEPT
-A DOCKER -d 172.21.0.3/32 ! -i br-c55e17fcfc37 -o br-c55e17fcfc37 -p tcp -m tcp --dport 8080 -j ACCEPT
-A DOCKER -d 172.19.0.6/32 ! -i br-9c699663c6e9 -o br-9c699663c6e9 -p tcp -m tcp --dport 9100 -j ACCEPT
-A DOCKER -d 172.20.0.2/32 ! -i br-815a057cdc62 -o br-815a057cdc62 -p tcp -m tcp --dport 6379 -j ACCEPT
-A DOCKER -d 172.21.0.2/32 ! -i br-c55e17fcfc37 -o br-c55e17fcfc37 -p tcp -m tcp --dport 4318 -j ACCEPT
-A DOCKER -d 172.21.0.2/32 ! -i br-c55e17fcfc37 -o br-c55e17fcfc37 -p tcp -m tcp --dport 4317 -j ACCEPT
-A DOCKER -d 172.21.0.2/32 ! -i br-c55e17fcfc37 -o br-c55e17fcfc37 -p tcp -m tcp --dport 3200 -j ACCEPT
-A DOCKER -d 172.18.0.3/32 ! -i br-4d8a9b15ec18 -o br-4d8a9b15ec18 -p tcp -m tcp --dport 5860 -j ACCEPT
-A DOCKER -d 172.19.0.4/32 ! -i br-9c699663c6e9 -o br-9c699663c6e9 -p tcp -m tcp --dport 3100 -j ACCEPT
-A DOCKER -d 172.26.0.2/32 ! -i br-63217a78808e -o br-63217a78808e -p tcp -m tcp --dport 8222 -j ACCEPT
-A DOCKER -d 172.26.0.2/32 ! -i br-63217a78808e -o br-63217a78808e -p tcp -m tcp --dport 4222 -j ACCEPT
-A DOCKER -d 172.22.0.2/32 ! -i br-3114049d7c2f -o br-3114049d7c2f -p tcp -m tcp --dport 5432 -j ACCEPT
-A DOCKER -d 172.18.0.2/32 ! -i br-4d8a9b15ec18 -o br-4d8a9b15ec18 -p tcp -m tcp --dport 9002 -j ACCEPT
-A DOCKER -d 172.19.0.3/32 ! -i br-9c699663c6e9 -o br-9c699663c6e9 -p tcp -m tcp --dport 9090 -j ACCEPT
-A DOCKER -d 172.19.0.2/32 ! -i br-9c699663c6e9 -o br-9c699663c6e9 -p tcp -m tcp --dport 3000 -j ACCEPT
-A DOCKER ! -i br-3114049d7c2f -o br-3114049d7c2f -j DROP
-A DOCKER ! -i br-4d8a9b15ec18 -o br-4d8a9b15ec18 -j DROP
-A DOCKER ! -i br-63217a78808e -o br-63217a78808e -j DROP
-A DOCKER ! -i br-815a057cdc62 -o br-815a057cdc62 -j DROP
-A DOCKER ! -i br-9c699663c6e9 -o br-9c699663c6e9 -j DROP
-A DOCKER ! -i br-c55e17fcfc37 -o br-c55e17fcfc37 -j DROP
-A DOCKER ! -i docker0 -o docker0 -j DROP
-A DOCKER-BRIDGE -o br-3114049d7c2f -j DOCKER
-A DOCKER-BRIDGE -o br-4d8a9b15ec18 -j DOCKER
-A DOCKER-BRIDGE -o br-63217a78808e -j DOCKER
-A DOCKER-BRIDGE -o br-815a057cdc62 -j DOCKER
-A DOCKER-BRIDGE -o br-9c699663c6e9 -j DOCKER
-A DOCKER-BRIDGE -o br-c55e17fcfc37 -j DOCKER
-A DOCKER-BRIDGE -o docker0 -j DOCKER
-A DOCKER-CT -o br-3114049d7c2f -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A DOCKER-CT -o br-4d8a9b15ec18 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A DOCKER-CT -o br-63217a78808e -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A DOCKER-CT -o br-815a057cdc62 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A DOCKER-CT -o br-9c699663c6e9 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A DOCKER-CT -o br-c55e17fcfc37 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A DOCKER-CT -o docker0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A DOCKER-FORWARD -j DOCKER-CT
-A DOCKER-FORWARD -j DOCKER-INTERNAL
-A DOCKER-FORWARD -j DOCKER-BRIDGE
-A DOCKER-FORWARD -i br-3114049d7c2f -j ACCEPT
-A DOCKER-FORWARD -i br-4d8a9b15ec18 -j ACCEPT
-A DOCKER-FORWARD -i br-63217a78808e -j ACCEPT
-A DOCKER-FORWARD -i br-815a057cdc62 -j ACCEPT
-A DOCKER-FORWARD -i br-9c699663c6e9 -j ACCEPT
-A DOCKER-FORWARD -i br-c55e17fcfc37 -j ACCEPT
-A DOCKER-FORWARD -i docker0 -j ACCEPT
-A f2b-sshd -j RETURN
-A ufw-after-input -p udp -m udp --dport 137 -j ufw-skip-to-policy-input
-A ufw-after-input -p udp -m udp --dport 138 -j ufw-skip-to-policy-input
-A ufw-after-input -p tcp -m tcp --dport 139 -j ufw-skip-to-policy-input
-A ufw-after-input -p tcp -m tcp --dport 445 -j ufw-skip-to-policy-input
-A ufw-after-input -p udp -m udp --dport 67 -j ufw-skip-to-policy-input
-A ufw-after-input -p udp -m udp --dport 68 -j ufw-skip-to-policy-input
-A ufw-after-input -m addrtype --dst-type BROADCAST -j ufw-skip-to-policy-input
-A ufw-after-logging-forward -m limit --limit 3/min --limit-burst 10 -j LOG --log-prefix "[UFW BLOCK] "
-A ufw-after-logging-input -m limit --limit 3/min --limit-burst 10 -j LOG --log-prefix "[UFW BLOCK] "
-A ufw-before-forward -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
```

## 6-7.7 Fail2Ban Status

```text
Status
|- Number of jail:	1
`- Jail list:	sshd

Status for the jail: sshd
|- Filter
|  |- Currently failed:	7
|  |- Total failed:	3804
|  `- Journal matches:	_SYSTEMD_UNIT=sshd.service + _COMM=sshd
`- Actions
   |- Currently banned:	0
   |- Total banned:	94
   `- Banned IP list:	
```

## 6-7.8 Docker Exposed Ports / Images

```text
NAMES                     IMAGE                             STATUS                PORTS
pix2pi-redis              redis:7-alpine                    Up 9 days             0.0.0.0:6379->6379/tcp, [::]:6379->6379/tcp
pix2pi_pg_replica         postgres:16                       Up 9 days             0.0.0.0:5434->5432/tcp, [::]:5434->5432/tcp
pix2pi-mission-control    deploy-mission-control            Up 9 days             9001/tcp, 0.0.0.0:9101->5860/tcp, [::]:9101->5860/tcp
pix2pi-service-registry   deploy-service-registry           Up 9 days             
pix2pi-identity-api       deploy-identity-api               Up 9 days             0.0.0.0:9002->9002/tcp, [::]:9002->9002/tcp
pix2pi_grafana            grafana/grafana:latest            Up 9 days             0.0.0.0:3001->3000/tcp, [::]:3001->3000/tcp
pix2pi_promtail           grafana/promtail:2.9.8            Up 9 days             
pix2pi_loki               grafana/loki:2.9.8                Up 9 days             0.0.0.0:3100->3100/tcp, [::]:3100->3100/tcp
pix2pi_prometheus         prom/prometheus:latest            Up 9 days             0.0.0.0:9090->9090/tcp, [::]:9090->9090/tcp
pix2pi_node_exporter      prom/node-exporter:latest         Up 9 days             0.0.0.0:9100->9100/tcp, [::]:9100->9100/tcp
pix2pi_nats               nats:2.10-alpine                  Up 9 days             0.0.0.0:4222->4222/tcp, [::]:4222->4222/tcp, 0.0.0.0:8222->8222/tcp, [::]:8222->8222/tcp, 6222/tcp
pix2pi_tempo              grafana/tempo:2.6.1               Up 9 days             0.0.0.0:3200->3200/tcp, [::]:3200->3200/tcp, 0.0.0.0:4317-4318->4317-4318/tcp, [::]:4317-4318->4317-4318/tcp
pix2pi-api-gateway        kong:3.7                          Up 9 days (healthy)   
pix2pi_pg                 postgres:16                       Up 3 days             0.0.0.0:5433->5432/tcp, [::]:5433->5432/tcp
pix2pi_cadvisor           gcr.io/cadvisor/cadvisor:latest   Up 9 days (healthy)   0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp

REPOSITORY                 TAG           IMAGE ID       CREATED
deploy-mission-control     latest        328bd810dc26   3 weeks ago
deploy-service-registry    latest        94bb5d7c18cd   3 weeks ago
deploy-identity-api        latest        a76fb2bf7f84   3 weeks ago
postgres                   16            11ea9d908f28   2 months ago
redis                      7-alpine      aa189b5a1954   2 months ago
grafana/grafana            latest        40df8365e157   2 months ago
nats                       2.10-alpine   8b9f712ae214   3 months ago
prom/prometheus            latest        937690d77350   3 months ago
gcr.io/cadvisor/cadvisor   latest        a31688ab1366   4 months ago
prom/node-exporter         latest        696e69e899e0   6 months ago
grafana/tempo              2.6.1         5e6726c97341   18 months ago
kong                       3.7           8735a1e440df   22 months ago
grafana/loki               2.9.8         105db0731131   24 months ago
grafana/promtail           2.9.8         5ff0658d61a6   24 months ago
```

## 6-7.9 Auth / Tenant Runtime Probe

```text
===== PORT 9001 protected probe =====


===== PORT 9010 protected probe =====
HTTP/1.1 401 Unauthorized
Content-Type: application/json
X-Correlation-Id: 48dd2741328e850927e0525f7764f7da
X-Request-Id: 48dd2741328e850927e0525f7764f7da
Date: Fri, 01 May 2026 11:58:40 GMT
Content-Length: 256

{"code":"missing_authorization_header","correlation_id":"48dd2741328e850927e0525f7764f7da","error":"authorization header zorunlu","http_status":401,"middleware":"jwt","request_id":"48dd2741328e850927e0525f7764f7da","source":"api_gateway","status":"error"}

HTTP/1.1 404 Not Found
Content-Type: application/json
X-Correlation-Id: 175ef652d9d0f0160d70abe4d412d247
X-Request-Id: 175ef652d9d0f0160d70abe4d412d247
Date: Fri, 01 May 2026 11:58:40 GMT
Content-Length: 212

{"code":"route_not_found","correlation_id":"175ef652d9d0f0160d70abe4d412d247","error":"route bulunamadi","http_status":404,"request_id":"175ef652d9d0f0160d70abe4d412d247","source":"api_gateway","status":"error"}

```

## 6-7.10 Security-related Logs Inventory

```text
===== /var/log/auth.log =====
May  1 12:21:02 vm12827 sshd[284186]: Received disconnect from 101.47.159.50 port 55362:11: Bye Bye [preauth]
May  1 12:21:02 vm12827 sshd[284186]: Disconnected from invalid user ubuntu 101.47.159.50 port 55362 [preauth]
May  1 12:21:17 vm12827 sshd[284394]: Invalid user  from 45.156.87.253 port 40690
May  1 12:21:24 vm12827 sshd[284394]: Connection closed by invalid user  45.156.87.253 port 40690 [preauth]
May  1 12:22:55 vm12827 sshd[285297]: Invalid user ubuntu from 101.47.159.50 port 52002
May  1 12:22:56 vm12827 sshd[285297]: Received disconnect from 101.47.159.50 port 52002:11: Bye Bye [preauth]
May  1 12:22:56 vm12827 sshd[285297]: Disconnected from invalid user ubuntu 101.47.159.50 port 52002 [preauth]
May  1 12:23:43 vm12827 sshd[285768]: Connection closed by authenticating user root 89.185.81.112 port 53640 [preauth]
May  1 12:25:02 vm12827 sshd[286558]: Invalid user admin from 101.47.159.50 port 35280
May  1 12:25:02 vm12827 sshd[286558]: Received disconnect from 101.47.159.50 port 35280:11: Bye Bye [preauth]
May  1 12:25:02 vm12827 sshd[286558]: Disconnected from invalid user admin 101.47.159.50 port 35280 [preauth]
May  1 12:26:56 vm12827 sshd[287665]: Invalid user ubuntu from 101.47.159.50 port 37330
May  1 12:26:56 vm12827 sshd[287665]: Received disconnect from 101.47.159.50 port 37330:11: Bye Bye [preauth]
May  1 12:26:56 vm12827 sshd[287665]: Disconnected from invalid user ubuntu 101.47.159.50 port 37330 [preauth]
May  1 12:28:45 vm12827 sshd[288704]: Received disconnect from 101.47.159.50 port 55970:11: Bye Bye [preauth]
May  1 12:28:45 vm12827 sshd[288704]: Disconnected from authenticating user root 101.47.159.50 port 55970 [preauth]
May  1 12:30:40 vm12827 sshd[289941]: Invalid user nodeuser from 101.47.159.50 port 47386
May  1 12:30:40 vm12827 sshd[289941]: Received disconnect from 101.47.159.50 port 47386:11: Bye Bye [preauth]
May  1 12:30:40 vm12827 sshd[289941]: Disconnected from invalid user nodeuser 101.47.159.50 port 47386 [preauth]
May  1 12:30:41 vm12827 sshd[289944]: Invalid user test from 89.185.81.112 port 42900
May  1 12:30:41 vm12827 sshd[289944]: Connection closed by invalid user test 89.185.81.112 port 42900 [preauth]
May  1 12:32:37 vm12827 sshd[291055]: Invalid user admin from 101.47.159.50 port 45830
May  1 12:32:37 vm12827 sshd[291055]: Received disconnect from 101.47.159.50 port 45830:11: Bye Bye [preauth]
May  1 12:32:37 vm12827 sshd[291055]: Disconnected from invalid user admin 101.47.159.50 port 45830 [preauth]
May  1 12:34:27 vm12827 sshd[292115]: Invalid user guest from 101.47.159.50 port 48798
May  1 12:34:27 vm12827 sshd[292115]: Received disconnect from 101.47.159.50 port 48798:11: Bye Bye [preauth]
May  1 12:34:27 vm12827 sshd[292115]: Disconnected from invalid user guest 101.47.159.50 port 48798 [preauth]
May  1 12:36:22 vm12827 sshd[293150]: Invalid user ubuntu from 101.47.159.50 port 35654
May  1 12:36:22 vm12827 sshd[293150]: Received disconnect from 101.47.159.50 port 35654:11: Bye Bye [preauth]
May  1 12:36:22 vm12827 sshd[293150]: Disconnected from invalid user ubuntu 101.47.159.50 port 35654 [preauth]
May  1 12:37:36 vm12827 sshd[293865]: Invalid user user from 89.185.81.112 port 33616
May  1 12:37:36 vm12827 sshd[293865]: Connection closed by invalid user user 89.185.81.112 port 33616 [preauth]
May  1 12:38:23 vm12827 sshd[294307]: Invalid user dev from 101.47.159.50 port 56308
May  1 12:38:23 vm12827 sshd[294307]: Received disconnect from 101.47.159.50 port 56308:11: Bye Bye [preauth]
May  1 12:38:23 vm12827 sshd[294307]: Disconnected from invalid user dev 101.47.159.50 port 56308 [preauth]
May  1 12:38:23 vm12827 sshd[294354]: Connection closed by 154.117.199.5 port 57576 [preauth]
May  1 12:40:18 vm12827 sshd[295391]: Invalid user git from 101.47.159.50 port 42802
May  1 12:40:18 vm12827 sshd[295391]: Received disconnect from 101.47.159.50 port 42802:11: Bye Bye [preauth]
May  1 12:40:18 vm12827 sshd[295391]: Disconnected from invalid user git 101.47.159.50 port 42802 [preauth]
May  1 12:42:08 vm12827 sshd[296586]: Invalid user ansadmin from 101.47.159.50 port 51406
May  1 12:42:08 vm12827 sshd[296586]: Received disconnect from 101.47.159.50 port 51406:11: Bye Bye [preauth]
May  1 12:42:08 vm12827 sshd[296586]: Disconnected from invalid user ansadmin 101.47.159.50 port 51406 [preauth]
May  1 12:44:05 vm12827 sshd[297821]: Invalid user admin from 101.47.159.50 port 34616
May  1 12:44:06 vm12827 sshd[297821]: Received disconnect from 101.47.159.50 port 34616:11: Bye Bye [preauth]
May  1 12:44:06 vm12827 sshd[297821]: Disconnected from invalid user admin 101.47.159.50 port 34616 [preauth]
May  1 12:45:59 vm12827 sshd[298822]: Invalid user tacuser from 101.47.159.50 port 44868
May  1 12:45:59 vm12827 sshd[298822]: Received disconnect from 101.47.159.50 port 44868:11: Bye Bye [preauth]
May  1 12:45:59 vm12827 sshd[298822]: Disconnected from invalid user tacuser 101.47.159.50 port 44868 [preauth]
May  1 12:47:50 vm12827 sshd[299883]: Invalid user admin from 101.47.159.50 port 50070
May  1 12:47:50 vm12827 sshd[299883]: Received disconnect from 101.47.159.50 port 50070:11: Bye Bye [preauth]
May  1 12:47:50 vm12827 sshd[299883]: Disconnected from invalid user admin 101.47.159.50 port 50070 [preauth]
May  1 12:49:47 vm12827 sshd[300991]: Invalid user testing from 101.47.159.50 port 38728
May  1 12:49:47 vm12827 sshd[300991]: Received disconnect from 101.47.159.50 port 38728:11: Bye Bye [preauth]
May  1 12:49:47 vm12827 sshd[300991]: Disconnected from invalid user testing 101.47.159.50 port 38728 [preauth]
May  1 12:51:46 vm12827 sshd[302162]: Invalid user test from 101.47.159.50 port 44222
May  1 12:51:46 vm12827 sshd[302162]: Received disconnect from 101.47.159.50 port 44222:11: Bye Bye [preauth]
May  1 12:51:46 vm12827 sshd[302162]: Disconnected from invalid user test 101.47.159.50 port 44222 [preauth]
May  1 12:53:41 vm12827 sshd[303226]: Invalid user test from 101.47.159.50 port 55720
May  1 12:53:42 vm12827 sshd[303226]: Received disconnect from 101.47.159.50 port 55720:11: Bye Bye [preauth]
May  1 12:53:42 vm12827 sshd[303226]: Disconnected from invalid user test 101.47.159.50 port 55720 [preauth]
May  1 12:55:38 vm12827 sshd[304335]: Invalid user Ubuntu01 from 101.47.159.50 port 46264
May  1 12:55:38 vm12827 sshd[304335]: Received disconnect from 101.47.159.50 port 46264:11: Bye Bye [preauth]
May  1 12:55:38 vm12827 sshd[304335]: Disconnected from invalid user Ubuntu01 101.47.159.50 port 46264 [preauth]
May  1 12:57:35 vm12827 sshd[305477]: Invalid user admin from 101.47.159.50 port 47466
May  1 12:57:35 vm12827 sshd[305477]: Received disconnect from 101.47.159.50 port 47466:11: Bye Bye [preauth]
May  1 12:57:35 vm12827 sshd[305477]: Disconnected from invalid user admin 101.47.159.50 port 47466 [preauth]
May  1 12:59:29 vm12827 sshd[306601]: Invalid user bitrix from 101.47.159.50 port 59224
May  1 12:59:30 vm12827 sshd[306601]: Received disconnect from 101.47.159.50 port 59224:11: Bye Bye [preauth]
May  1 12:59:30 vm12827 sshd[306601]: Disconnected from invalid user bitrix 101.47.159.50 port 59224 [preauth]
May  1 13:22:26 vm12827 sshd[319266]: Connection closed by 46.253.45.10 port 47344 [preauth]
May  1 13:25:10 vm12827 sshd[320979]: Connection closed by 195.199.210.194 port 33128 [preauth]
May  1 13:27:15 vm12827 sshd[322218]: Connection closed by 118.33.113.1 port 43708 [preauth]
May  1 13:35:32 vm12827 sshd[327077]: Connection reset by 198.235.24.115 port 62130 [preauth]
May  1 13:58:58 vm12827 sshd[339852]: Connection closed by 89.218.69.66 port 54278 [preauth]
May  1 14:29:47 vm12827 sshd[450593]: Invalid user weblogic from 141.11.21.145 port 49762
May  1 14:29:47 vm12827 sshd[450593]: Connection closed by invalid user weblogic 141.11.21.145 port 49762 [preauth]
May  1 14:39:10 vm12827 sshd[542967]: Connection closed by 87.236.176.62 port 44017 [preauth]
May  1 14:46:59 vm12827 sshd[690284]: Invalid user test from 193.24.211.95 port 23590
May  1 14:46:59 vm12827 sshd[690284]: Received disconnect from 193.24.211.95 port 23590:11: Client disconnecting normally [preauth]
May  1 14:46:59 vm12827 sshd[690284]: Disconnected from invalid user test 193.24.211.95 port 23590 [preauth]
===== /var/log/nginx/access.log =====
===== /var/log/nginx/error.log =====
===== /var/log/fail2ban.log =====
2026-05-01 10:22:04,870 fail2ban.filter         [1700080]: INFO    [sshd] Found 203.145.143.163 - 2026-05-01 10:22:04
2026-05-01 10:24:10,104 fail2ban.filter         [1700080]: INFO    [sshd] Found 203.145.143.163 - 2026-05-01 10:24:09
2026-05-01 10:26:07,620 fail2ban.filter         [1700080]: INFO    [sshd] Found 45.148.10.121 - 2026-05-01 10:26:07
2026-05-01 10:26:11,370 fail2ban.filter         [1700080]: INFO    [sshd] Found 203.145.143.163 - 2026-05-01 10:26:10
2026-05-01 10:28:07,370 fail2ban.filter         [1700080]: INFO    [sshd] Found 203.145.143.163 - 2026-05-01 10:28:07
2026-05-01 10:28:07,409 fail2ban.actions        [1700080]: NOTICE  [sshd] Ban 203.145.143.163
2026-05-01 10:29:06,120 fail2ban.filter         [1700080]: INFO    [sshd] Found 45.148.10.183 - 2026-05-01 10:29:05
2026-05-01 10:30:12,870 fail2ban.filter         [1700080]: INFO    [sshd] Found 203.145.143.163 - 2026-05-01 10:30:12
2026-05-01 10:31:18,370 fail2ban.filter         [1700080]: INFO    [sshd] Found 45.148.10.183 - 2026-05-01 10:31:18
2026-05-01 10:32:18,870 fail2ban.filter         [1700080]: INFO    [sshd] Found 203.145.143.163 - 2026-05-01 10:32:18
2026-05-01 10:33:24,120 fail2ban.filter         [1700080]: INFO    [sshd] Found 45.148.10.183 - 2026-05-01 10:33:23
2026-05-01 10:34:22,290 fail2ban.filter         [1700080]: INFO    [sshd] Found 203.145.143.163 - 2026-05-01 10:34:22
2026-05-01 10:35:28,870 fail2ban.filter         [1700080]: INFO    [sshd] Found 45.148.10.183 - 2026-05-01 10:35:28
2026-05-01 10:37:32,620 fail2ban.filter         [1700080]: INFO    [sshd] Found 45.148.10.183 - 2026-05-01 10:37:32
2026-05-01 10:37:32,732 fail2ban.actions        [1700080]: NOTICE  [sshd] Ban 45.148.10.183
2026-05-01 10:38:33,870 fail2ban.filter         [1700080]: INFO    [sshd] Found 203.145.143.163 - 2026-05-01 10:38:33
2026-05-01 10:40:31,620 fail2ban.filter         [1700080]: INFO    [sshd] Found 203.145.143.163 - 2026-05-01 10:40:31
2026-05-01 10:40:32,181 fail2ban.actions        [1700080]: WARNING [sshd] 203.145.143.163 already banned
2026-05-01 10:41:29,620 fail2ban.filter         [1700080]: INFO    [sshd] Found 45.148.10.183 - 2026-05-01 10:41:29
2026-05-01 10:42:31,620 fail2ban.filter         [1700080]: INFO    [sshd] Found 203.145.143.163 - 2026-05-01 10:42:31
2026-05-01 10:44:32,620 fail2ban.filter         [1700080]: INFO    [sshd] Found 203.145.143.163 - 2026-05-01 10:44:32
2026-05-01 10:46:34,870 fail2ban.filter         [1700080]: INFO    [sshd] Found 203.145.143.163 - 2026-05-01 10:46:34
2026-05-01 10:48:40,870 fail2ban.filter         [1700080]: INFO    [sshd] Found 203.145.143.163 - 2026-05-01 10:48:40
2026-05-01 10:50:47,370 fail2ban.filter         [1700080]: INFO    [sshd] Found 203.145.143.163 - 2026-05-01 10:50:46
2026-05-01 10:50:47,564 fail2ban.actions        [1700080]: WARNING [sshd] 203.145.143.163 already banned
2026-05-01 10:52:44,370 fail2ban.filter         [1700080]: INFO    [sshd] Found 203.145.143.163 - 2026-05-01 10:52:44
2026-05-01 10:54:45,870 fail2ban.filter         [1700080]: INFO    [sshd] Found 203.145.143.163 - 2026-05-01 10:54:45
2026-05-01 10:57:09,236 fail2ban.filter         [1700080]: INFO    [sshd] Found 45.148.10.121 - 2026-05-01 10:57:09
2026-05-01 10:58:52,370 fail2ban.filter         [1700080]: INFO    [sshd] Found 203.145.143.163 - 2026-05-01 10:58:52
2026-05-01 11:00:55,870 fail2ban.filter         [1700080]: INFO    [sshd] Found 203.145.143.163 - 2026-05-01 11:00:55
2026-05-01 11:03:03,120 fail2ban.filter         [1700080]: INFO    [sshd] Found 203.145.143.163 - 2026-05-01 11:03:02
2026-05-01 11:03:03,123 fail2ban.actions        [1700080]: WARNING [sshd] 203.145.143.163 already banned
2026-05-01 11:05:07,371 fail2ban.filter         [1700080]: INFO    [sshd] Found 203.145.143.163 - 2026-05-01 11:05:07
2026-05-01 11:07:07,035 fail2ban.filter         [1700080]: INFO    [sshd] Found 141.11.21.145 - 2026-05-01 11:07:07
2026-05-01 11:09:14,870 fail2ban.filter         [1700080]: INFO    [sshd] Found 203.145.143.163 - 2026-05-01 11:09:14
2026-05-01 11:11:18,120 fail2ban.filter         [1700080]: INFO    [sshd] Found 203.145.143.163 - 2026-05-01 11:11:17
2026-05-01 11:13:17,280 fail2ban.filter         [1700080]: INFO    [sshd] Found 203.145.143.163 - 2026-05-01 11:13:17
2026-05-01 11:15:23,620 fail2ban.filter         [1700080]: INFO    [sshd] Found 203.145.143.163 - 2026-05-01 11:15:23
2026-05-01 11:15:24,075 fail2ban.actions        [1700080]: WARNING [sshd] 203.145.143.163 already banned
2026-05-01 11:17:27,870 fail2ban.filter         [1700080]: INFO    [sshd] Found 203.145.143.163 - 2026-05-01 11:17:27
2026-05-01 11:35:54,656 fail2ban.filter         [1700080]: INFO    [sshd] Found 89.185.81.112 - 2026-05-01 11:35:53
2026-05-01 11:37:32,548 fail2ban.actions        [1700080]: NOTICE  [sshd] Unban 45.148.10.183
2026-05-01 11:42:52,878 fail2ban.filter         [1700080]: INFO    [sshd] Found 89.185.81.112 - 2026-05-01 11:42:51
2026-05-01 11:51:04,741 fail2ban.filter         [1700080]: INFO    [sshd] Found 194.87.216.198 - 2026-05-01 11:51:03
2026-05-01 11:58:53,112 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 11:58:52
2026-05-01 12:05:52,151 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:05:51
2026-05-01 12:07:47,530 fail2ban.filter         [1700080]: INFO    [sshd] Found 194.87.216.198 - 2026-05-01 12:07:47
2026-05-01 12:07:54,290 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:07:53
2026-05-01 12:09:50,774 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:09:50
2026-05-01 12:11:43,215 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:11:42
2026-05-01 12:13:36,530 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:13:36
2026-05-01 12:15:23,370 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:15:23
2026-05-01 12:15:23,461 fail2ban.actions        [1700080]: NOTICE  [sshd] Unban 203.145.143.163
2026-05-01 12:17:10,870 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:17:10
2026-05-01 12:19:06,120 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:19:05
2026-05-01 12:21:02,620 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:21:02
2026-05-01 12:21:17,370 fail2ban.filter         [1700080]: INFO    [sshd] Found 45.156.87.253 - 2026-05-01 12:21:17
2026-05-01 12:22:56,244 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:22:55
2026-05-01 12:25:02,791 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:25:02
2026-05-01 12:26:56,870 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:26:56
2026-05-01 12:30:40,620 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:30:40
2026-05-01 12:30:42,120 fail2ban.filter         [1700080]: INFO    [sshd] Found 89.185.81.112 - 2026-05-01 12:30:41
2026-05-01 12:32:37,846 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:32:37
2026-05-01 12:34:27,504 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:34:27
2026-05-01 12:36:22,870 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:36:22
2026-05-01 12:37:36,620 fail2ban.filter         [1700080]: INFO    [sshd] Found 89.185.81.112 - 2026-05-01 12:37:36
2026-05-01 12:38:23,825 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:38:23
2026-05-01 12:40:18,870 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:40:18
2026-05-01 12:42:08,620 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:42:08
2026-05-01 12:44:06,120 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:44:05
2026-05-01 12:45:59,870 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:45:59
2026-05-01 12:47:50,941 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:47:50
2026-05-01 12:49:47,620 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:49:47
2026-05-01 12:51:47,120 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:51:46
2026-05-01 12:53:42,249 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:53:41
2026-05-01 12:55:38,855 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:55:38
2026-05-01 12:57:35,370 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:57:35
2026-05-01 12:59:29,870 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:59:29
2026-05-01 14:29:48,201 fail2ban.filter         [1700080]: INFO    [sshd] Found 141.11.21.145 - 2026-05-01 14:29:47
2026-05-01 14:47:00,151 fail2ban.filter         [1700080]: INFO    [sshd] Found 193.24.211.95 - 2026-05-01 14:46:59
WARN ⚠️ missing log: /var/log/pix2pi/security.log
WARN ⚠️ missing log: /var/log/pix2pi/audit.log
```

## 6-7.11 Dependency / Lock Inventory

```text
===== go.mod =====
-rw-r--r-- 1 root root 1627 Apr 16 21:27 go.mod
module github.com/divrigili/pix2pi-SaaS

go 1.24.0

require (
	github.com/alicebob/miniredis/v2 v2.35.0
	github.com/gofiber/fiber/v2 v2.52.11
	github.com/golang-jwt/jwt/v5 v5.3.1
	github.com/golang-migrate/migrate/v4 v4.19.1
	github.com/google/uuid v1.6.0
	github.com/jackc/pgx/v5 v5.6.0
	github.com/joho/godotenv v1.5.1
	github.com/lib/pq v1.12.3
	github.com/nats-io/nats.go v1.37.0
	github.com/redis/go-redis/v9 v9.18.0
	gorm.io/driver/postgres v1.6.0
	gorm.io/gorm v1.31.1
)

require (
	github.com/andybalholm/brotli v1.2.0 // indirect
	github.com/cespare/xxhash/v2 v2.3.0 // indirect
	github.com/clipperhouse/uax29/v2 v2.7.0 // indirect
	github.com/dgryski/go-rendezvous v0.0.0-20200823014737-9f7001d12a5f // indirect
	github.com/jackc/pgpassfile v1.0.0 // indirect
	github.com/jackc/pgservicefile v0.0.0-20240606120523-5a60cdf6a761 // indirect
	github.com/jackc/puddle/v2 v2.2.2 // indirect
	github.com/jinzhu/inflection v1.0.0 // indirect
	github.com/jinzhu/now v1.1.5 // indirect
	github.com/klauspost/compress v1.18.4 // indirect
	github.com/mattn/go-colorable v0.1.14 // indirect
	github.com/mattn/go-isatty v0.0.20 // indirect
	github.com/mattn/go-runewidth v0.0.20 // indirect
	github.com/nats-io/nkeys v0.4.12 // indirect
	github.com/nats-io/nuid v1.0.1 // indirect
	github.com/valyala/bytebufferpool v1.0.0 // indirect
	github.com/valyala/fasthttp v1.69.0 // indirect
	github.com/yuin/gopher-lua v1.1.1 // indirect
	go.uber.org/atomic v1.11.0 // indirect
	golang.org/x/crypto v0.46.0 // indirect
===== go.sum =====
-rw-r--r-- 1 root root 12812 Apr 16 21:27 go.sum
github.com/Azure/go-ansiterm v0.0.0-20230124172434-306776ec8161 h1:L/gRVlceqvL25UVaW/CKtUDjefjrs0SPonmDGUVOYP0=
github.com/Azure/go-ansiterm v0.0.0-20230124172434-306776ec8161/go.mod h1:xomTg63KZ2rFqZQzSB4Vz2SUXa1BpHTVz9L5PTmPC4E=
github.com/Microsoft/go-winio v0.6.2 h1:F2VQgta7ecxGYO8k3ZZz3RS8fVIXVxONVUPlNERoyfY=
github.com/Microsoft/go-winio v0.6.2/go.mod h1:yd8OoFMLzJbo9gZq8j5qaps8bJ9aShtEA8Ipt1oGCvU=
github.com/alicebob/miniredis/v2 v2.35.0 h1:QwLphYqCEAo1eu1TqPRN2jgVMPBweeQcR21jeqDCONI=
github.com/alicebob/miniredis/v2 v2.35.0/go.mod h1:TcL7YfarKPGDAthEtl5NBeHZfeUQj6OXMm/+iu5cLMM=
github.com/andybalholm/brotli v1.2.0 h1:ukwgCxwYrmACq68yiUqwIWnGY0cTPox/M94sVwToPjQ=
github.com/andybalholm/brotli v1.2.0/go.mod h1:rzTDkvFWvIrjDXZHkuS16NPggd91W3kUSvPlQ1pLaKY=
github.com/bsm/ginkgo/v2 v2.12.0 h1:Ny8MWAHyOepLGlLKYmXG4IEkioBysk6GpaRTLC8zwWs=
github.com/bsm/ginkgo/v2 v2.12.0/go.mod h1:SwYbGRRDovPVboqFv0tPTcG1sN61LM1Z4ARdbAV9g4c=
github.com/bsm/gomega v1.27.10 h1:yeMWxP2pV2fG3FgAODIY8EiRE3dy0aeFYt4l7wh6yKA=
github.com/bsm/gomega v1.27.10/go.mod h1:JyEr/xRbxbtgWNi8tIEVPUYZ5Dzef52k01W3YH0H+O0=
github.com/cespare/xxhash/v2 v2.3.0 h1:UL815xU9SqsFlibzuggzjXhog7bL6oX9BbNZnL2UFvs=
github.com/cespare/xxhash/v2 v2.3.0/go.mod h1:VGX0DQ3Q6kWi7AoAeZDth3/j3BFtOZR5XLFGgcrjCOs=
github.com/clipperhouse/uax29/v2 v2.7.0 h1:+gs4oBZ2gPfVrKPthwbMzWZDaAFPGYK72F0NJv2v7Vk=
github.com/clipperhouse/uax29/v2 v2.7.0/go.mod h1:EFJ2TJMRUaplDxHKj1qAEhCtQPW2tJSwu5BF98AuoVM=
github.com/containerd/errdefs v1.0.0 h1:tg5yIfIlQIrxYtu9ajqY42W3lpS19XqdxRQeEwYG8PI=
github.com/containerd/errdefs v1.0.0/go.mod h1:+YBYIdtsnF4Iw6nWZhJcqGSg/dwvV7tyJ/kCkyJ2k+M=
github.com/containerd/errdefs/pkg v0.3.0 h1:9IKJ06FvyNlexW690DXuQNx2KA2cUJXx151Xdx3ZPPE=
github.com/containerd/errdefs/pkg v0.3.0/go.mod h1:NJw6s9HwNuRhnjJhM7pylWwMyAkmCQvQ4GpJHEqRLVk=
github.com/davecgh/go-spew v1.1.0/go.mod h1:J7Y8YcW2NihsgmVo/mv3lAwl/skON4iLHjSsI+c5H38=
github.com/davecgh/go-spew v1.1.2-0.20180830191138-d8f796af33cc h1:U9qPSI2PIWSS1VwoXQT9A3Wy9MM3WgvqSxFWenqJduM=
github.com/davecgh/go-spew v1.1.2-0.20180830191138-d8f796af33cc/go.mod h1:J7Y8YcW2NihsgmVo/mv3lAwl/skON4iLHjSsI+c5H38=
github.com/dgryski/go-rendezvous v0.0.0-20200823014737-9f7001d12a5f h1:lO4WD4F/rVNCu3HqELle0jiPLLBs70cWOduZpkS1E78=
github.com/dgryski/go-rendezvous v0.0.0-20200823014737-9f7001d12a5f/go.mod h1:cuUVRXasLTGF7a8hSLbxyZXjz+1KgoB3wDUb6vlszIc=
github.com/dhui/dktest v0.4.6 h1:+DPKyScKSEp3VLtbMDHcUq6V5Lm5zfZZVb0Sk7Ahom4=
github.com/dhui/dktest v0.4.6/go.mod h1:JHTSYDtKkvFNFHJKqCzVzqXecyv+tKt8EzceOmQOgbU=
github.com/distribution/reference v0.6.0 h1:0IXCQ5g4/QMHHkarYzh5l+u8T3t73zM5QvfrDyIgxBk=
github.com/distribution/reference v0.6.0/go.mod h1:BbU0aIcezP1/5jX/8MP0YiH4SdvB5Y4f/wlDRiLyi3E=
github.com/docker/docker v28.3.3+incompatible h1:Dypm25kh4rmk49v1eiVbsAtpAsYURjYkaKubwuBdxEI=
github.com/docker/docker v28.3.3+incompatible/go.mod h1:eEKB0N0r5NX/I1kEveEz05bcu8tLC/8azJZsviup8Sk=
github.com/docker/go-connections v0.5.0 h1:USnMq7hx7gwdVZq1L49hLXaFtUdTADjXGp+uj1Br63c=
github.com/docker/go-connections v0.5.0/go.mod h1:ov60Kzw0kKElRwhNs9UlUHAE/F9Fe6GLaXnqyDdmEXc=
github.com/docker/go-units v0.5.0 h1:69rxXcBk27SvSaaxTtLh/8llcHD8vYHT7WSdRZ/jvr4=
github.com/docker/go-units v0.5.0/go.mod h1:fgPhTUdO+D/Jk86RDLlptpiXQzgHJF7gydDDbaIK4Dk=
github.com/felixge/httpsnoop v1.0.4 h1:NFTV2Zj1bL4mc9sqWACXbQFVBBg2W3GPvqp8/ESS2Wg=
github.com/felixge/httpsnoop v1.0.4/go.mod h1:m8KPJKqk1gH5J9DgRY2ASl2lWCfGKXixSwevea8zH2U=
github.com/go-logr/logr v1.4.3 h1:CjnDlHq8ikf6E492q6eKboGOC0T8CDaOvkHCIg8idEI=
github.com/go-logr/logr v1.4.3/go.mod h1:9T104GzyrTigFIr8wt5mBrctHMim0Nb2HLGrmQ40KvY=
github.com/go-logr/stdr v1.2.2 h1:hSWxHoqTgW2S2qGc0LTAI563KZ5YKYRhT3MFKZMbjag=
===== Dockerfile =====
-rw-r--r-- 1 root root 210 Apr  6 23:24 Dockerfile
FROM golang:1.24-alpine AS builder

WORKDIR /app

COPY . .

RUN go mod tidy
RUN go build -o app ./cmd/mission-control

FROM alpine:3.19

WORKDIR /app

COPY --from=builder /app/app .

EXPOSE 9001

CMD ["./app"]
```

## 6-7.12 Security Scripts Inventory

```text
./1_archive/root_sh/step_105_backup_api_gateway_before_rate_limit.sh
./1_archive/root_sh/step_106_restart_api_gateway_after_rate_limit.sh
./1_archive/root_sh/step_107_test_api_gateway_rate_limit.sh
./1_archive/root_sh/step_108_backup_api_gateway_before_tenant_middleware.sh
./1_archive/root_sh/step_109_restart_api_gateway_after_tenant_middleware.sh
./1_archive/root_sh/step_10_run_tenant_event_pipeline_test.sh
./1_archive/root_sh/step_110_test_gateway_tenant_middleware.sh
./1_archive/root_sh/step_111_backup_api_gateway_before_redis_rate_limit.sh
./1_archive/root_sh/step_114_restart_api_gateway_after_redis_rate_limit.sh
./1_archive/root_sh/step_115_test_gateway_redis_rate_limit.sh
./1_archive/root_sh/step_11_backup_tenant_service_filter.sh
./1_archive/root_sh/step_12_run_tenant_service_filter_test.sh
./1_archive/root_sh/step_130_backup_nginx_before_rate_limit.sh
./1_archive/root_sh/step_131_add_nginx_global_rate_limit.sh
./1_archive/root_sh/step_131_restart_gateway_after_bearer_tenant_match.sh
./1_archive/root_sh/step_132_enable_rate_limit_api_domain.sh
./1_archive/root_sh/step_132_test_gateway_bearer_tenant_match.sh
./1_archive/root_sh/step_133_reload_nginx_after_rate_limit.sh
./1_archive/root_sh/step_136_backup_fail2ban_before_nginx_jail.sh
./1_archive/root_sh/step_13_backup_redis_tenant_namespace.sh
./1_archive/root_sh/step_15_run_redis_tenant_namespace_test.sh
./1_archive/root_sh/step_17_prepare_security_dir.sh
./1_archive/root_sh/step_1_backup_tenant_test.sh
./1_archive/root_sh/step_210_audit_full.sh
./1_archive/root_sh/step_210_prepare_audit_folder.sh
./1_archive/root_sh/step_211_test_audit_engine.sh
./1_archive/root_sh/step_250_tenant_isolation_verification.sh
./1_archive/root_sh/step_260_audit_schema.sh
./1_archive/root_sh/step_261_audit_full.sh
./1_archive/root_sh/step_262_run_audit_flow.sh
./1_archive/root_sh/step_28_backup_audit_log_engine.sh
./1_archive/root_sh/step_29_prepare_audit_dirs.sh
./1_archive/root_sh/step_2_run_tenant_test.sh
./1_archive/root_sh/step_30_run_audit_log_engine_test.sh
./1_archive/root_sh/step_316_full_nginx_port_scan.sh
./1_archive/root_sh/step_360_rewrite_monitor_hardening.sh
./1_archive/root_sh/step_392_production_hardening.sh
./1_archive/root_sh/step_3_backup_jwt_tenant.sh
./1_archive/root_sh/step_404_scan_db_entrypoints.sh
./1_archive/root_sh/step_406_scan_kernel_usage.sh
./1_archive/root_sh/step_407_scan_db_usage.sh
./1_archive/root_sh/step_44c_audit_pg_topology.sh
./1_archive/root_sh/step_5_run_jwt_tenant_test.sh
./1_archive/root_sh/step_69_backup_rate_limit.sh
./1_archive/root_sh/step_6_backup_jwt_middleware.sh
./1_archive/root_sh/step_71_run_rate_limit_test.sh
./1_archive/root_sh/step_76_configure_production_firewall.sh
./1_archive/root_sh/step_8_run_jwt_middleware_test.sh
./1_archive/root_sh/step_9_backup_tenant_event_pipeline.sh
./1_archive/root_sql/step_260_create_audit_tables.sql
./_backup_archive/4c_1_1b_2_marketplace_scope_guard_report.md.bak
./_backup_archive/AppShell.tsx.bak_incident_audit_20260424_235550
./_backup_archive/App.tsx.bak_incident_audit_20260424_235550
./_backup_archive/control_panel.go.bak_incident_audit_runtime_proxy_20260424_235140
./_backup_archive/IncidentAuditPage.test.tsx.bak_multi_match_fix_20260425_000033
./_backup_archive/IncidentAuditPage.test.tsx.bak_multi_match_fix_20260425_000101
./_backup_archive/IncidentAuditPage.test.tsx.bak_multi_match_fix_20260425_000113
./_backup_archive/IncidentAuditPage.test.tsx.bak_multi_match_fix_20260425_000131
./.backup/lvl10_2_10_5_edge_security_cert_ops_20260422_061143/deploy/edge/scripts/render_edge_config.sh
./.backup/lvl8_3_tenant_layout_20260420_213427/src/app/App.tsx
./.backup/lvl8_3_tenant_layout_20260420_213427/src/app/providers/AppProviders.tsx
./.backup/lvl8_3_tenant_layout_20260420_213427/src/app/shell/AppShell.test.tsx
./.backup/lvl8_3_tenant_layout_20260420_213427/src/app/shell/AppShell.tsx
./.backup/lvl8_3_tenant_layout_20260420_213427/src/shared/styles/global.css
./.backup/lvl9_5_tenant_backend_binding_20260421_080823/src/app/providers/AppRuntimeContext.tsx
./.backup/lvl9_5_tenant_backend_binding_20260421_080823/src/app/shell/AppShell.test.tsx
./.backup/lvl9_5_tenant_backend_binding_20260421_080823/src/app/shell/AppShell.tsx
./.backup/lvl9_8_4_9_8_5_error_visibility_runtime_guard_20260422_001044/src/app/providers/AppRuntimeContext.tsx
./.backup/lvl9_8_4_9_8_5_error_visibility_runtime_guard_20260422_001044/src/shared/runtime/RuntimeConfigPanel.tsx
./.backup/lvl9_8_4_9_8_5_error_visibility_runtime_guard_20260422_001044/src/shared/runtime/RuntimeSafetyGatePanel.tsx
./backups/faz3_10_2b_erp_runtime_fiscal_guard_default_impl_20260426_063732/fiscalguard_before_default_impl.tar.gz
./backups/faz3_10_2c_erp_runtime_fiscal_guard_postgres_provider_20260426_063823/fiscalguard_before_postgres_provider.tar.gz
./backups/faz3_10_2d_erp_runtime_fiscal_guard_muhur_20260426_063854/docs_erp_before_fiscalguard_muhur.tar.gz
./backups/faz3_10_2d_erp_runtime_fiscal_guard_muhur_20260426_063854/fiscalguard_before_muhur.tar.gz
./backups/faz3_13_2c_gateway_live_negative_final_muhur_20260426_230410/logs/tenant_mismatch_response.json
./backups/faz3_13_2c_gateway_live_negative_final_muhur_20260426_230410/logs/token_tenant_7.txt
./backups/faz3_13_2c_gateway_live_negative_final_muhur_20260426_230410/logs/token_tenant_99.txt
./backups/faz3_13_3b_gateway_observability_log_visibility_20260426_232013/logs/token_tenant_7.txt
./backups/faz3_13_4a_step13_gateway_final_muhur_20260426_232851/logs/token_tenant_7.txt
./backups/faz3_14_1a_admin_panel_discovery_20260426_233259/logs/panel_admin_content_scan.log
./backups/faz3_14_1a_admin_panel_discovery_20260426_233557/logs/panel_admin_content_scan.log
./backups/faz3_14_2a_fix_panel_live_served_file_inspect_20260426_235028/logs/nginx_panel_config_scan.log
./backups/faz3_14_2a_fix_panel_live_served_file_inspect_20260426_235054/logs/nginx_panel_config_scan.log
./backups/faz3_14_3a_content_type_header_diagnose_20260427_001443/logs/content_type_source_scan.log
./backups/faz3_9_9_4a_postgres_tax_rate_repository_20260425_221024/tax_before_tax_rate_repository.tar.gz
./backups/faz3_9_9_4b_tax_rate_repository_test_20260425_221102/tax_before_tax_rate_repository_test.tar.gz
./backups/faz4_14_1_4B_primary_write_dsn_guard_20260427_075227/.env
./backups/faz4_17_3R_query_text_no_print_fix_20260427_191929/docs/phase4/17_3_gateway_route_manifest_auth_tenant_gate_report.md
./backups/faz4_17_3R_query_text_no_print_fix_20260427_191929/docs/phase4/17_3_reporting_auth_tenant_gate_contract.md
./backups/faz4_17_3R_query_text_no_print_fix_20260427_191929/scripts/phase4_gateway_route_manifest_auth_tenant_gate.sh
./backups/faz4_17_3R_query_text_no_print_fix_20260427_191929/scripts/test_phase4_gateway_route_manifest_auth_tenant_gate.sh
./backups/faz4_18_5R2_token_aware_python_syntax_fix_20260427_232018/docs/phase4/18_5_live_http_smoke_auth_tenant_report.md
./backups/faz4_18_5R2_token_aware_python_syntax_fix_20260427_232018/scripts/phase4_live_http_smoke_auth_tenant.py
./backups/faz4_18_5R2_token_aware_python_syntax_fix_20260427_232018/scripts/test_phase4_live_http_smoke_auth_tenant.sh
./backups/faz4_18_5R_token_aware_live_http_smoke_fix_20260427_231856/docs/phase4/18_5_live_http_smoke_auth_tenant_report.md
./backups/faz4_18_5R_token_aware_live_http_smoke_fix_20260427_231856/scripts/phase4_live_http_smoke_auth_tenant.py
./backups/faz4_18_5R_token_aware_live_http_smoke_fix_20260427_231856/scripts/phase4_live_http_smoke_auth_tenant.sh
./backups/faz4_18_5R_token_aware_live_http_smoke_fix_20260427_231856/scripts/test_phase4_live_http_smoke_auth_tenant.sh
./backups/faz4b_19_4R_import_wizard_tenant_ref_fix_20260428_235215/docs/phase4/19_4_import_wizard_ui_component_manifest.tsv
./backups/faz4b_19_4R_import_wizard_tenant_ref_fix_20260428_235215/docs/phase4/19_4_import_wizard_ui_contract.md
./backups/faz4b_19_4R_import_wizard_tenant_ref_fix_20260428_235215/docs/phase4/19_4_import_wizard_ui_matrix.tsv
./backups/faz4b_19_4R_import_wizard_tenant_ref_fix_20260428_235215/docs/phase4/19_4_import_wizard_ui_report.md
./backups/faz4b_19_4R_import_wizard_tenant_ref_fix_20260428_235215/docs/phase4/19_4_import_wizard_ui_route_manifest.tsv
./backups/faz4b_19_4R_import_wizard_tenant_ref_fix_20260428_235215/docs/phase4/19_4_import_wizard_ui_standard.md
./backups/faz4b_19_4R_import_wizard_tenant_ref_fix_20260428_235215/docs/phase4/19_4_import_wizard_ui_step_manifest.tsv
./backups/faz4b_19_4R_import_wizard_tenant_ref_fix_20260428_235215/scripts/phase4b_import_wizard_ui.py
./backups/faz4b_19_4R_import_wizard_tenant_ref_fix_20260428_235215/scripts/phase4b_import_wizard_ui.sh
./backups/faz4b_19_4R_import_wizard_tenant_ref_fix_20260428_235215/scripts/test_phase4b_import_wizard_ui.sh
./backups/faz4b_21_1_role_matrix_20260429_073345/db/migrations/20260429_211001_security_role_matrix.down.sql
./backups/faz4b_21_1_role_matrix_20260429_073345/db/migrations/20260429_211001_security_role_matrix.up.sql
./backups/faz4b_21_1R_role_matrix_boundary_permission_fix_20260429_073537/db/migrations/20260429_211001_security_role_matrix.down.sql
./backups/faz4b_21_1R_role_matrix_boundary_permission_fix_20260429_073537/db/migrations/20260429_211001_security_role_matrix.up.sql
./backups/faz4b_21_2R_permission_guard_surface_fix_20260429_074545/docs/phase4/21_2_permission_guard_contract.md
./backups/faz4b_21_2R_permission_guard_surface_fix_20260429_074545/docs/phase4/21_2_permission_guard_decision_manifest.tsv
./backups/faz4b_21_2R_permission_guard_surface_fix_20260429_074545/docs/phase4/21_2_permission_guard_matrix.tsv
./backups/faz4b_21_2R_permission_guard_surface_fix_20260429_074545/docs/phase4/21_2_permission_guard_middleware_manifest.tsv
./backups/faz4b_21_2R_permission_guard_surface_fix_20260429_074545/docs/phase4/21_2_permission_guard_report.md
./backups/faz4b_21_2R_permission_guard_surface_fix_20260429_074545/docs/phase4/21_2_permission_guard_standard.md
./backups/faz4b_21_2R_permission_guard_surface_fix_20260429_074545/docs/phase4/21_2_permission_guard_surface_manifest.tsv
./backups/faz4b_21_2R_permission_guard_surface_fix_20260429_074545/scripts/phase4b_permission_guard.py
./backups/faz4b_21_2R_permission_guard_surface_fix_20260429_074545/scripts/phase4b_permission_guard.sh
./backups/faz4b_21_2R_permission_guard_surface_fix_20260429_074545/scripts/test_phase4b_permission_guard.sh
./backups/faz4b_21_3R_audit_event_counter_fix_20260429_075114/db/migrations/20260429_213001_security_audit_event_model.down.sql
./backups/faz4b_21_3R_audit_event_counter_fix_20260429_075114/db/migrations/20260429_213001_security_audit_event_model.up.sql
./backups/faz4b_21_3R_audit_event_counter_fix_20260429_075114/docs/phase4/21_3_audit_event_model_inventory.tsv
./backups/faz4b_21_3R_audit_event_counter_fix_20260429_075114/docs/phase4/21_3_audit_event_model_matrix.tsv
./backups/faz4b_21_3R_audit_event_counter_fix_20260429_075114/docs/phase4/21_3_audit_event_model_report.md
./backups/faz4b_21_3R_audit_event_counter_fix_20260429_075114/docs/phase4/21_3_audit_event_model_standard.md
./backups/faz4b_21_3R_audit_event_counter_fix_20260429_075114/scripts/phase4b_audit_event_model.py
./backups/faz4b_21_3R_audit_event_counter_fix_20260429_075114/scripts/phase4b_audit_event_model.sh
./backups/faz4b_21_3R_audit_event_counter_fix_20260429_075114/scripts/test_phase4b_audit_event_model.sh
./backups/faz4c/4c_11b_pilot_completion_seal_guard/20260501_093733/4c_11a_completion_seal_criteria.env.bak
./backups/faz4c/4c_11b_pilot_completion_seal_guard/20260501_093733/4c_11a_final_closure_inventory_report.md.bak
./backups/faz4c/4c_11b_pilot_completion_seal_guard/20260501_093733/4c_11a_final_closure_inventory_seal_criteria.md.bak
./backups/faz4c/4c_11c_final_closure_report_package/20260501_093843/4c_11b_pilot_completion_seal_guard.md.bak
./backups/faz4c/4c_11c_final_closure_report_package/20260501_093843/4c_11b_pilot_completion_seal_guard_report.md.bak
./backups/faz4c/4c_11d_pilot_completion_seal_final_closure/20260501_094026/4c_11b_pilot_completion_seal_guard_report.md.bak
./backups/faz4c/4c_1_1h_real_business_apply_guard/20260501_060620/4c_1_1g_real_business_input_template.env.bak
./backups/faz4c/4c_1_1j_final_closure/20260501_065519/4c_1_1h_real_business_apply_guard_report.md.bak
./backups/faz4c/4c_2a_runtime_baseline_gap_scan/20260501_070020/4c_1_final_closure.md.bak
./backups/faz4c/4c_2b_critical_runtime_gap_classification/20260501_070226/4c_2a_runtime_baseline_gap_scan_report.md.bak
./backups/faz4c/4c_2c_runtime_port_standardization/20260501_070349/4c_2a_runtime_baseline_gap_scan_report.md.bak
./backups/faz4c/4c_2f_runtime_gap_final_closure/20260501_070733/4c_2a_runtime_baseline_gap_scan_test_report.md.bak
./backups/faz4c/4c_3a_tenant_identity_setup_plan/20260501_070839/4c_1_1h_real_business_profile_applied.md.bak
./backups/faz4c/4c_3a_tenant_identity_setup_plan/20260501_070839/4c_2f_runtime_gap_final_closure_report.md.bak
./backups/faz4c/4c_3b_db_tenant_precheck/20260501_071039/4c_3a_tenant_identity_setup_plan.env.bak
./backups/faz4c/4c_3b_db_tenant_precheck/20260501_071039/4c_3a_tenant_identity_setup_plan_report.md.bak
./backups/faz4c/4c_3c_tenant_apply_strategy_decision/20260501_071244/4c_3a_tenant_identity_setup_plan.env.bak
./backups/faz4c/4c_3c_tenant_apply_strategy_decision/20260501_071244/4c_3b_db_tenant_precheck_report.md.bak
./backups/faz4c/4c_3c_tenant_apply_strategy_decision/20260501_071249/4c_3a_tenant_identity_setup_plan.env.bak
./backups/faz4c/4c_3c_tenant_apply_strategy_decision/20260501_071249/4c_3b_db_tenant_precheck_report.md.bak
./backups/faz4c/4c_3c_tenant_apply_strategy_decision/20260501_071249/4c_3c_tenant_apply_strategy_decision.md.bak
./backups/faz4c/4c_3c_tenant_apply_strategy_decision/20260501_071249/4c_3c_tenant_apply_strategy_decision_report.md.bak
./backups/faz4c/4c_3c_tenant_apply_strategy_decision/20260501_071249/4c_3c_tenant_apply_strategy_decision_test_report.md.bak
./backups/faz4c/4c_3c_tenant_apply_strategy_decision/20260501_071249/run_4c_3c_tenant_apply_strategy_decision.sh.bak
./backups/faz4c/4c_3c_tenant_apply_strategy_decision/20260501_071249/test_4c_3c_tenant_apply_strategy_decision.sh.bak
./backups/faz4c/4c_3d_fix2_business_code_mapping/20260501_072016/4c_3d_preview_tenant_uzmanparcaci.sql.bak
./backups/faz4c/4c_3d_fix3_business_code_uppercase/20260501_072316/4c_3d_preview_tenant_uzmanparcaci.sql.bak
./backups/faz4c/4c_3d_tenant_apply_sql_package/20260501_071438/4c_3a_tenant_identity_setup_plan.env.bak
./backups/faz4c/4c_3d_tenant_apply_sql_package/20260501_071438/4c_3c_tenant_apply_strategy_decision_report.md.bak
./backups/faz4c/4c_3e_fix1b_rewrite_debug_script/20260501_071903/4c_3d_preview_tenant_uzmanparcaci.sql.bak
./backups/faz4c/4c_3e_fix1_dry_run_error_diagnosis/20260501_071706/4c_3d_preview_tenant_uzmanparcaci.sql.bak
./backups/faz4c/4c_3e_fix1_dry_run_error_diagnosis/20260501_071748/4c_3d_preview_tenant_uzmanparcaci.sql.bak
./backups/faz4c/4c_3e_fix2b_second_error_diagnosis/20260501_072111/4c_3d_preview_tenant_uzmanparcaci.sql.bak
./backups/faz4c/4c_3e_fix2b_second_error_diagnosis/20260501_072111/4c_3e_tenant_sql_dry_run.md.bak
./backups/faz4c/4c_3e_fix2b_second_error_diagnosis/20260501_072111/4c_3e_tenant_sql_dry_run_report.md.bak
./backups/faz4c/4c_3e_fix3a_domain_rule_discovery/20260501_072208/4c_3d_preview_tenant_uzmanparcaci.sql.bak
./backups/faz4c/4c_3e_tenant_sql_dry_run/20260501_071603/4c_3d_preview_tenant_uzmanparcaci.sql.bak
./backups/faz4c/4c_3e_tenant_sql_dry_run/20260501_071603/4c_3d_tenant_apply_sql_package_test_report.md.bak
./backups/faz4c/4c_3f_tenant_commit_sql_package/20260501_072506/4c_3d_fix3_business_code_uppercase_report.md.bak
./backups/faz4c/4c_3f_tenant_commit_sql_package/20260501_072506/4c_3e_tenant_sql_dry_run_test_report.md.bak
./backups/faz4c/4c_3f_tenant_commit_sql_package/20260501_072532/4c_3d_fix3_business_code_uppercase_report.md.bak
./backups/faz4c/4c_3f_tenant_commit_sql_package/20260501_072532/4c_3e_tenant_sql_dry_run_test_report.md.bak
./backups/faz4c/4c_3f_tenant_commit_sql_package/20260501_072532/4c_3f_commit_tenant_uzmanparcaci.sql.bak
./backups/faz4c/4c_3f_tenant_commit_sql_package/20260501_072532/4c_3f_tenant_commit_sql_package.md.bak
./backups/faz4c/4c_3f_tenant_commit_sql_package/20260501_072532/4c_3f_tenant_commit_sql_package_report.md.bak
./backups/faz4c/4c_3f_tenant_commit_sql_package/20260501_072532/4c_3f_tenant_commit_sql_package_test_report.md.bak
./backups/faz4c/4c_3f_tenant_commit_sql_package/20260501_072532/build_4c_3f_tenant_commit_sql_package.sh.bak
./backups/faz4c/4c_3f_tenant_commit_sql_package/20260501_072532/test_4c_3f_tenant_commit_sql_package.sh.bak
./backups/faz4c/4c_3g_tenant_apply_execution/20260501_072703/4c_3f_commit_tenant_uzmanparcaci.sql.bak
./backups/faz4c/4c_3g_tenant_apply_execution/20260501_072703/4c_3f_tenant_commit_sql_package_test_report.md.bak
./backups/faz4c/4c_3h_tenant_apply_verification/20260501_072815/4c_3g_tenant_apply_execution_report.md.bak
./backups/faz4c/4c_3h_tenant_apply_verification/20260501_072815/4c_3g_tenant_apply_execution_test_report.md.bak
./backups/faz4c/4c_3i_tenant_setup_final_closure/20260501_072914/4c_3a_tenant_identity_setup_plan_report.md.bak
./backups/faz4c/4c_3i_tenant_setup_final_closure/20260501_072914/4c_3b_db_tenant_precheck_report.md.bak
./backups/faz4c/4c_3i_tenant_setup_final_closure/20260501_072914/4c_3c_tenant_apply_strategy_decision_report.md.bak
./backups/faz4c/4c_3i_tenant_setup_final_closure/20260501_072914/4c_3d_fix3_business_code_uppercase_report.md.bak
./backups/faz4c/4c_3i_tenant_setup_final_closure/20260501_072914/4c_3e_tenant_sql_dry_run_test_report.md.bak
./backups/faz4c/4c_3i_tenant_setup_final_closure/20260501_072914/4c_3f_tenant_commit_sql_package_test_report.md.bak
./backups/faz4c/4c_3i_tenant_setup_final_closure/20260501_072914/4c_3g_tenant_apply_execution_test_report.md.bak
./backups/faz4c/4c_3i_tenant_setup_final_closure/20260501_072914/4c_3h_tenant_apply_verification_test_report.md.bak
./backups/faz4c/4c_4a_user_role_identity_plan/20260501_073437/4c_3i_tenant_setup_final_closure_report.md.bak
./backups/faz4c/4c_4c_user_role_apply_strategy/20260501_073759/4c_4a_user_role_identity_plan.env.bak
./backups/faz4c/4c_4c_user_role_apply_strategy/20260501_073759/4c_4b_identity_user_role_db_precheck_report.md.bak
./backups/faz4c/4c_4d_fix2_rebuild_sql_package/20260501_074321/4c_4c_user_role_apply_strategy_report.md.bak
./backups/faz4c/4c_4d_user_role_sql_package/20260501_074025/4c_4c_user_role_apply_strategy_report.md.bak
./backups/faz4c/4c_4i_user_role_assignment_final_closure/20260501_075710/4c_4c_user_role_apply_strategy_test_report.md.bak
./backups/faz4c/4c_5d_import_mapping_strategy/20260501_080433/4c_5c_product_stock_table_discovery_report.md.bak
./backups/faz4c/4c_5d_import_mapping_strategy/20260501_080433/4c_5c_product_stock_table_discovery_test_report.md.bak
./backups/faz4c/4c_5e_sample_csv_generation_validation/20260501_080628/4c_5d_import_mapping_strategy.env.bak
./backups/faz4c/4c_5e_sample_csv_generation_validation/20260501_080628/4c_5d_import_mapping_strategy_report.md.bak
./backups/faz4c/4c_5e_sample_csv_generation_validation/20260501_080628/4c_5d_import_mapping_strategy_test_report.md.bak
./backups/faz4c/4c_5f_import_sql_package/20260501_080756/4c_5d_import_mapping_strategy.env.bak
./backups/faz4c/4c_5j_real_pilot_data_import_final_closure/20260501_081931/4c_5d_import_mapping_strategy_test_report.md.bak
./backups/faz6_7_real_audit_fix_20260501_145840/audit_faz6_7_real_implementation.sh.backup
./backups/gateway_jwt_default_fix/20260418_091157/gateway_config.go
./backups/gw_ingress_scan/20260417_201007/conf.d/health.conf
./backups/gw_ingress_scan/20260417_201007/nginx.conf
./backups/gw_ingress_scan/20260417_201007/sites-available/default
./backups/gw_ingress_scan/20260417_201007/sites-available/pix2pi
./backups/gw_ingress_scan/20260417_201007/sites-available/pix2pi_api_gateway
./backups/gw_ingress_scan/20260417_201007/sites-available/pix2pi_http_redirect
./backups/gw_ingress_scan/20260417_201007/sites-available/pix2pi_ssl
./backups/gw_ingress_scan/20260417_201007/snippets/fastcgi-php.conf
./backups/gw_ingress_scan/20260417_201007/snippets/pix2pi_watchdog.conf
./backups/gw_ingress_scan/20260417_201007/snippets/snakeoil.conf
./cmd/api-gateway/gateway_config_security_test.go
./cmd/gateway-rate-limit-redis-test/gateway_rate_limit_redis_test_main.go
./cmd/incident-audit-runtime/incident_audit_runtime_main.go
./cmd/incident-audit-runtime/incident_audit_runtime_main_test.go
```

## 6-7.13 Runtime Audit Interpretation

```text
6-7.1 Host inventory collected OK ✅
6-7.2 User/permission context collected OK ✅
6-7.3 Env/secret file permission inventory collected OK ✅
6-7.4 Nginx syntax/security inventory collected OK ✅
6-7.5 Listening port inventory collected OK ✅
6-7.6 UFW/firewall status collected OK ✅
6-7.7 Fail2Ban status collected OK ✅
6-7.8 Docker exposed ports/images collected OK ✅
6-7.9 Auth/tenant runtime probe collected OK ✅
6-7.10 Security-related logs inventory collected OK ✅
6-7.11 Dependency/lock inventory collected OK ✅
6-7.12 Security scripts inventory collected OK ✅
FAZ_6_7_RUNTIME_AUDIT=COMPLETE ✅
```
