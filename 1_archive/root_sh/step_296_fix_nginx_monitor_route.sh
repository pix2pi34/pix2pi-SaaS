#!/bin/bash
set -e

echo "===== BACKUP ====="
cp /etc/nginx/sites-enabled/pix2pi_ssl /etc/nginx/sites-enabled/pix2pi_ssl.bak_$(date +%s)

echo "===== ROUTE EKLENIYOR ====="

cat <<'BLOCK' >> /etc/nginx/sites-enabled/pix2pi_ssl

    location /internal/service-monitor {
        proxy_pass http://127.0.0.1:9016/status;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

BLOCK

echo "===== NGINX TEST ====="
nginx -t

echo "===== RELOAD ====="
systemctl reload nginx

echo "===== TEST ====="
curl -s http://127.0.0.1/internal/service-monitor | head

echo
echo "OK ✅ nginx monitor route eklendi"
