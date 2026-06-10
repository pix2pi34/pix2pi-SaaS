#!/bin/bash
set -e

mkdir -p /root/pix2pi/nginx_backups
cp /etc/nginx/sites-enabled/pix2pi_ssl /root/pix2pi/nginx_backups/pix2pi_ssl.before_rewrite.$(date +%Y%m%d_%H%M%S)

cat <<'NGEOF' > /etc/nginx/sites-enabled/pix2pi_ssl
server {
    listen 443 ssl;
    server_name pix2pi.com.tr www.pix2pi.com.tr panel.pix2pi.com.tr;

    ssl_certificate /etc/letsencrypt/live/pix2pi.com.tr/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/pix2pi.com.tr/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;

    location = /health {
        default_type text/plain;
        return 200 "panel ok\n";
    }

    location = /api/health {
        proxy_pass http://127.0.0.1:8080/api/health;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location = /dev/token {
        proxy_pass http://127.0.0.1:8080/dev/token;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location = /internal/service-monitor {
        proxy_pass http://127.0.0.1:9016/status;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location = /internal/service-watchdog-health {
        proxy_pass http://127.0.0.1:9016/health;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /containers/ {
        return 404;
    }

    location / {
        root /opt/pix2pi/nginx;
        index panel_index.html;
        try_files $uri $uri/ /panel_index.html;
    }
}

server {
    listen 443 ssl;
    server_name server.pix2pi.com.tr;

    ssl_certificate /etc/letsencrypt/live/pix2pi.com.tr/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/pix2pi.com.tr/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;

    location = / {
        return 301 https://server.pix2pi.com.tr/containers/;
    }

    location /containers/ {
        proxy_pass http://127.0.0.1:8080/containers/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
NGEOF

nginx -t
systemctl reload nginx

echo
echo "=== WATCHDOG HEALTH TEST ==="
curl -s http://127.0.0.1/internal/service-watchdog-health
echo
echo
echo "=== WATCHDOG STATUS TEST ==="
curl -s http://127.0.0.1/internal/service-monitor
echo
echo
echo "OK ✅ pix2pi_ssl temiz yazildi ve watchdog baglandi"
