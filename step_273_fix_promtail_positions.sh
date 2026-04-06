#!/bin/bash
set -e

BASE=~/pix2pi/pix2pi-SaaS
OBS=$BASE/infra/observability

mkdir -p $OBS/promtail/data

cat <<'YAMLEOF' > $OBS/promtail/promtail-config.yml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /var/lib/promtail/positions.yaml

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

cat <<'YAMLEOF' > $OBS/docker-compose.yml
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
      - ./promtail/data:/var/lib/promtail
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

echo "OK ✅ promtail positions fix dosyalari hazir"
