#!/bin/bash
set -e

echo "=== BACKUP ==="
mkdir -p ~/pix2pi/pix2pi-SaaS/_backup_archive/orchestrator
cp -a /etc/systemd/system /etc/systemd/system.bak_pix2pi_$(date +%Y%m%d_%H%M%S) || true

echo "=== PIX2PI ORCHESTRATOR DIRS ==="
mkdir -p /opt/pix2pi/orchestrator/bin
mkdir -p /opt/pix2pi/orchestrator/env
mkdir -p /opt/pix2pi/orchestrator/log
mkdir -p /opt/pix2pi/orchestrator/run
mkdir -p /opt/pix2pi/orchestrator/services

echo "=== ENV FILE ==="
cat <<'ENVEOF' > /opt/pix2pi/orchestrator/env/common.env
PIX2PI_ROOT=/root/pix2pi/pix2pi-SaaS
GO_BIN=/usr/local/go/bin/go
ENV=production
ENVEOF

echo "=== SERVICE WRAPPER: API GATEWAY ==="
cat <<'APIEOF' > /opt/pix2pi/orchestrator/bin/run_api_gateway.sh
#!/bin/bash
set -e

source /opt/pix2pi/orchestrator/env/common.env

cd "$PIX2PI_ROOT"
exec "$GO_BIN" run ./cmd/api-gateway >> /tmp/pix2pi_api_gateway.log 2>&1
APIEOF
chmod +x /opt/pix2pi/orchestrator/bin/run_api_gateway.sh

echo "=== SERVICE WRAPPER: ACCOUNTING ==="
cat <<'ACCEOF' > /opt/pix2pi/orchestrator/bin/run_accounting_service.sh
#!/bin/bash
set -e

source /opt/pix2pi/orchestrator/env/common.env

cd "$PIX2PI_ROOT"
exec "$GO_BIN" run ./cmd/accounting-service >> /tmp/pix2pi_accounting.log 2>&1
ACCEOF
chmod +x /opt/pix2pi/orchestrator/bin/run_accounting_service.sh

echo "=== SERVICE WRAPPER: QUERY READ MODEL ==="
cat <<'QREOF' > /opt/pix2pi/orchestrator/bin/run_query_read_model.sh
#!/bin/bash
set -e

source /opt/pix2pi/orchestrator/env/common.env

cd "$PIX2PI_ROOT"
exec "$GO_BIN" run ./cmd/query-read-model >> /tmp/pix2pi_query_read_model.log 2>&1
QREOF
chmod +x /opt/pix2pi/orchestrator/bin/run_query_read_model.sh

echo "=== SERVICE WRAPPER: SERVICE DISCOVERY ==="
cat <<'SDEOF' > /opt/pix2pi/orchestrator/bin/run_service_discovery.sh
#!/bin/bash
set -e

source /opt/pix2pi/orchestrator/env/common.env

cd "$PIX2PI_ROOT"
exec "$GO_BIN" run ./cmd/service-registry >> /tmp/pix2pi_service_registry.log 2>&1
SDEOF
chmod +x /opt/pix2pi/orchestrator/bin/run_service_discovery.sh

echo "=== SYSTEMD UNIT: API GATEWAY ==="
cat <<'UNITEOF' > /etc/systemd/system/pix2pi-api-gateway.service
[Unit]
Description=Pix2pi API Gateway
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/pix2pi/pix2pi-SaaS
ExecStart=/opt/pix2pi/orchestrator/bin/run_api_gateway.sh
Restart=always
RestartSec=3
StartLimitIntervalSec=60
StartLimitBurst=10

[Install]
WantedBy=multi-user.target
UNITEOF

echo "=== SYSTEMD UNIT: ACCOUNTING ==="
cat <<'UNITEOF' > /etc/systemd/system/pix2pi-accounting.service
[Unit]
Description=Pix2pi Accounting Service
After=network.target nats.service redis.service
Wants=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/pix2pi/pix2pi-SaaS
ExecStart=/opt/pix2pi/orchestrator/bin/run_accounting_service.sh
Restart=always
RestartSec=3
StartLimitIntervalSec=60
StartLimitBurst=10

[Install]
WantedBy=multi-user.target
UNITEOF

echo "=== SYSTEMD UNIT: QUERY READ MODEL ==="
cat <<'UNITEOF' > /etc/systemd/system/pix2pi-query-read-model.service
[Unit]
Description=Pix2pi Query Read Model
After=network.target nats.service redis.service
Wants=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/pix2pi/pix2pi-SaaS
ExecStart=/opt/pix2pi/orchestrator/bin/run_query_read_model.sh
Restart=always
RestartSec=3
StartLimitIntervalSec=60
StartLimitBurst=10

[Install]
WantedBy=multi-user.target
UNITEOF

echo "=== SYSTEMD UNIT: SERVICE DISCOVERY ==="
cat <<'UNITEOF' > /etc/systemd/system/pix2pi-service-discovery.service
[Unit]
Description=Pix2pi Service Discovery
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/pix2pi/pix2pi-SaaS
ExecStart=/opt/pix2pi/orchestrator/bin/run_service_discovery.sh
Restart=always
RestartSec=3
StartLimitIntervalSec=60
StartLimitBurst=10

[Install]
WantedBy=multi-user.target
UNITEOF

echo "=== SYSTEMD RELOAD ==="
systemctl daemon-reload

echo "=== VERIFY UNIT FILES ==="
systemctl cat pix2pi-api-gateway.service >/dev/null
systemctl cat pix2pi-accounting.service >/dev/null
systemctl cat pix2pi-query-read-model.service >/dev/null
systemctl cat pix2pi-service-discovery.service >/dev/null

echo "OK ✅ orchestrator foundation hazir"
