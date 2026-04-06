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

  - job_name: pix2pi_core_logs
    static_configs:
      - targets:
          - localhost
        labels:
          job: pix2pi_core_logs
          service: pix2pi
          __path__: /tmp/pix2pi*.log

  - job_name: critical_system_logs
    static_configs:
      - targets:
          - localhost
        labels:
          job: system_logs
          service: system
          __path__: /var/log/syslog
YAMLEOF

echo "OK ✅ log noise azaltildi"
