# FAZ 4C — 4C-2A Runtime Baseline Gap Scan Report

Step: 4C-2A
Blok: Runtime Baseline Inventory / Gap Scan
Test tarihi: 2026-05-01 07:00:20

## 1. Tool durumu

GIT_AVAILABLE=YES
GO_AVAILABLE=YES
DOCKER_AVAILABLE=YES
CURL_AVAILABLE=YES
SS_AVAILABLE=YES
SYSTEMCTL_AVAILABLE=YES

---

## 2. Repo / dosya durumu

REPO_GIT_DIR=FOUND
GO_MOD_FILE=FOUND
DOCKER_COMPOSE_FILE=MISSING
PORTS_ENV_FILE=FOUND
COMMON_ENV_FILE=FOUND

---

## 3. Systemd servis durumu

API_GATEWAY_SERVICE_STATUS=active
IDENTITY_SERVICE_STATUS=inactive
FAIL2BAN_STATUS=active
CRON_STATUS=active

---

## 4. Port dinleme durumu

PORT_9010_API_GATEWAY=LISTEN
PORT_9001_IDENTITY=NOT_LISTEN
PORT_5433_POSTGRES_HOST=LISTEN
PORT_9090_PROMETHEUS=LISTEN
PORT_3000_GRAFANA=NOT_LISTEN
PORT_9100_NODE_EXPORTER=LISTEN
PORT_8080_CADVISOR=LISTEN

---

## 5. Health endpoint durumu

GATEWAY_HEALTH_HTTP=200
IDENTITY_HEALTH_HTTP=NO_RESPONSE
PROM_READY_HTTP=200
GRAFANA_HEALTH_HTTP=NO_RESPONSE
NODE_EXPORTER_HTTP=200
CADVISOR_HTTP=200

---

## 6. Docker running containers

```text
pix2pi-redis | redis:7-alpine | Up 9 days | 0.0.0.0:6379->6379/tcp, [::]:6379->6379/tcp
pix2pi_pg_replica | postgres:16 | Up 9 days | 0.0.0.0:5434->5432/tcp, [::]:5434->5432/tcp
pix2pi-mission-control | deploy-mission-control | Up 9 days | 9001/tcp, 0.0.0.0:9101->5860/tcp, [::]:9101->5860/tcp
pix2pi-service-registry | deploy-service-registry | Up 9 days | 
pix2pi-identity-api | deploy-identity-api | Up 9 days | 0.0.0.0:9002->9002/tcp, [::]:9002->9002/tcp
pix2pi_grafana | grafana/grafana:latest | Up 9 days | 0.0.0.0:3001->3000/tcp, [::]:3001->3000/tcp
pix2pi_promtail | grafana/promtail:2.9.8 | Up 9 days | 
pix2pi_loki | grafana/loki:2.9.8 | Up 9 days | 0.0.0.0:3100->3100/tcp, [::]:3100->3100/tcp
pix2pi_prometheus | prom/prometheus:latest | Up 9 days | 0.0.0.0:9090->9090/tcp, [::]:9090->9090/tcp
pix2pi_node_exporter | prom/node-exporter:latest | Up 9 days | 0.0.0.0:9100->9100/tcp, [::]:9100->9100/tcp
pix2pi_nats | nats:2.10-alpine | Up 9 days | 0.0.0.0:4222->4222/tcp, [::]:4222->4222/tcp, 0.0.0.0:8222->8222/tcp, [::]:8222->8222/tcp, 6222/tcp
pix2pi_tempo | grafana/tempo:2.6.1 | Up 9 days | 0.0.0.0:3200->3200/tcp, [::]:3200->3200/tcp, 0.0.0.0:4317-4318->4317-4318/tcp, [::]:4317-4318->4317-4318/tcp
pix2pi-api-gateway | kong:3.7 | Up 9 days (healthy) | 
pix2pi_pg | postgres:16 | Up 3 days | 0.0.0.0:5433->5432/tcp, [::]:5433->5432/tcp
pix2pi_cadvisor | gcr.io/cadvisor/cadvisor:latest | Up 9 days (healthy) | 0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp
```

---

## 7. Gap özeti

4C_2A_CRITICAL_BLOCKER_COUNT=0
4C_2A_WARNING_COUNT=1

Not:
Bu adim runtime fotoğrafı çeker.
Warning olması bu adımı fail yapmaz.
Critical blocker varsa 4C-2B içinde ayrıştırılır.

---

## 8. Status

4C_2A_RUNTIME_BASELINE_SCAN_STATUS=PASS
4C_2A_REPORT_CREATED=YES
4C_2A_NEXT_STEP_READY=YES
4C_2B_READY=YES
