#!/bin/bash
set -e

CONFIG=~/pix2pi/pix2pi-SaaS/infra/observability/promtail/promtail-config.yml

cat <<'YAMLEOF' > $CONFIG
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /var/lib/promtail/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:

  - job_name: accounting_service
    static_configs:
      - targets:
          - localhost
        labels:
          job: accounting
          __path__: /tmp/pix2pi_accounting.log

  - job_name: reporting_service
    static_configs:
      - targets:
          - localhost
        labels:
          job: reporting
          __path__: /tmp/pix2pi_reporting_service.log
YAMLEOF

echo "OK ✅ snapshot promtaildan kaldirildi"
