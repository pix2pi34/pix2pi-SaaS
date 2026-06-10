#!/bin/bash
set -e

BASE=~/pix2pi/pix2pi-SaaS
OBS=$BASE/infra/observability

mkdir -p $OBS/prometheus
mkdir -p $OBS/loki
mkdir -p $OBS/promtail
mkdir -p $OBS/grafana/provisioning/datasources
mkdir -p $OBS/grafana/provisioning/dashboards
mkdir -p $OBS/grafana/dashboards

cat <<'YAMLEOF' > $OBS/docker-compose.yml
version: "3.9"

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: pix2pi_prometheus
    restart: unless-stopped
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
    ports:
      - "9090:9090"
    networks:
      - pix2pi_observability

  loki:
    image: grafana/loki:2.9.8
    container_name: pix2pi_loki
    restart: unless-stopped
    command: -config.file=/etc/loki/local-config.yaml
    volumes:
      - ./loki/loki-config.yml:/etc/loki/local-config.yaml:ro
    ports:
      - "3100:3100"
    networks:
      - pix2pi_observability

  promtail:
    image: grafana/promtail:2.9.8
    container_name: pix2pi_promtail
    restart: unless-stopped
    command: -config.file=/etc/promtail/config.yml
    volumes:
      - ./promtail/promtail-config.yml:/etc/promtail/config.yml:ro
      - /tmp:/tmp:ro
      - /var/log:/var/log:ro
    depends_on:
      - loki
    networks:
      - pix2pi_observability

  grafana:
    image: grafana/grafana:latest
    container_name: pix2pi_grafana
    restart: unless-stopped
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=pix2pi_admin_123
      - GF_USERS_ALLOW_SIGN_UP=false
    volumes:
      - ./grafana/provisioning:/etc/grafana/provisioning:ro
      - ./grafana/dashboards:/var/lib/grafana/dashboards:ro
    ports:
      - "3001:3000"
    depends_on:
      - prometheus
      - loki
    networks:
      - pix2pi_observability

  node_exporter:
    image: prom/node-exporter:latest
    container_name: pix2pi_node_exporter
    restart: unless-stopped
    command:
      - --path.rootfs=/host
    pid: host
    volumes:
      - /:/host:ro,rslave
    ports:
      - "9100:9100"
    networks:
      - pix2pi_observability

networks:
  pix2pi_observability:
    driver: bridge
YAMLEOF

cat <<'YAMLEOF' > $OBS/prometheus/prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["prometheus:9090"]

  - job_name: "node_exporter"
    static_configs:
      - targets: ["node_exporter:9100"]
YAMLEOF

cat <<'YAMLEOF' > $OBS/loki/loki-config.yml
auth_enabled: false

server:
  http_listen_port: 3100

common:
  path_prefix: /tmp/loki
  storage:
    filesystem:
      chunks_directory: /tmp/loki/chunks
      rules_directory: /tmp/loki/rules
  replication_factor: 1
  ring:
    kvstore:
      store: inmemory

schema_config:
  configs:
    - from: 2024-01-01
      store: tsdb
      object_store: filesystem
      schema: v13
      index:
        prefix: index_
        period: 24h

ruler:
  alertmanager_url: http://localhost:9093
YAMLEOF

cat <<'YAMLEOF' > $OBS/promtail/promtail-config.yml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
  - job_name: pix2pi_tmp_logs
    static_configs:
      - targets:
          - localhost
        labels:
          job: pix2pi_tmp_logs
          host: vm12827
          __path__: /tmp/pix2pi*.log

  - job_name: system_logs
    static_configs:
      - targets:
          - localhost
        labels:
          job: system_logs
          host: vm12827
          __path__: /var/log/*.log
YAMLEOF

cat <<'YAMLEOF' > $OBS/grafana/provisioning/datasources/datasources.yml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true

  - name: Loki
    type: loki
    access: proxy
    url: http://loki:3100
YAMLEOF

cat <<'YAMLEOF' > $OBS/grafana/provisioning/dashboards/dashboards.yml
apiVersion: 1

providers:
  - name: pix2pi-dashboards
    orgId: 1
    folder: Pix2pi
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    options:
      path: /var/lib/grafana/dashboards
YAMLEOF

cat <<'JSONEOF' > $OBS/grafana/dashboards/pix2pi-overview.json
{
  "annotations": {
    "list": []
  },
  "editable": true,
  "fiscalYearStartMonth": 0,
  "graphTooltip": 0,
  "id": null,
  "links": [],
  "panels": [
    {
      "datasource": {
        "type": "prometheus",
        "uid": "PBFA97CFB590B2093"
      },
      "fieldConfig": {
        "defaults": {},
        "overrides": []
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 0,
        "y": 0
      },
      "id": 1,
      "options": {
        "legend": {
          "displayMode": "list",
          "placement": "bottom"
        }
      },
      "targets": [
        {
          "expr": "rate(node_cpu_seconds_total{mode!=\"idle\"}[5m])",
          "refId": "A"
        }
      ],
      "title": "CPU Rate",
      "type": "timeseries"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "PBFA97CFB590B2093"
      },
      "fieldConfig": {
        "defaults": {},
        "overrides": []
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 12,
        "y": 0
      },
      "id": 2,
      "targets": [
        {
          "expr": "node_memory_MemAvailable_bytes",
          "refId": "A"
        }
      ],
      "title": "Memory Available",
      "type": "timeseries"
    }
  ],
  "refresh": "10s",
  "schemaVersion": 39,
  "style": "dark",
  "tags": [
    "pix2pi"
  ],
  "templating": {
    "list": []
  },
  "time": {
    "from": "now-15m",
    "to": "now"
  },
  "title": "Pix2pi Overview",
  "version": 1
}
JSONEOF

echo "OK ✅ observability dosyalari hazir"
