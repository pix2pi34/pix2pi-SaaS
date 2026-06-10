#!/usr/bin/env bash
set -euo pipefail

cd ~/pix2pi/pix2pi-SaaS
export PATH="/usr/local/go/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

set -a
source /opt/pix2pi/orchestrator/env/common.env
source /etc/pix2pi/ports.env
set +a

echo "===== OPS CONSOLE GENERAL GO TEST ====="
go test ./cmd/ops-console-smoke -v

echo
echo "===== OPS CONSOLE SMOKE BUILD ====="
go build -o /tmp/pix2pi-ops-console-smoke.new ./cmd/ops-console-smoke

echo
echo "===== OPS CONSOLE SMOKE INSTALL ====="
if [ -f /usr/local/bin/pix2pi-ops-console-smoke ]; then
  cp -a /usr/local/bin/pix2pi-ops-console-smoke /usr/local/bin/pix2pi-ops-console-smoke.bak_$(date +%Y%m%d_%H%M%S)
fi

install -m 0755 /tmp/pix2pi-ops-console-smoke.new /usr/local/bin/pix2pi-ops-console-smoke
ls -la /usr/local/bin/pix2pi-ops-console-smoke

echo
echo "===== OPS CONSOLE LIVE SMOKE ====="
/usr/local/bin/pix2pi-ops-console-smoke

echo
echo "===== PANEL HEALTH ====="
curl -s --max-time 5 "http://127.0.0.1:${PANEL_PORT:-7100}/health"
echo

echo
echo "===== NGINX TEST ====="
/usr/sbin/nginx -t

echo
echo "OK ✅ ops console general smoke suite gecti"
