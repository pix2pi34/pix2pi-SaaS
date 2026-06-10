# FAZ 4B / 20.5 - Docker / Compose Hardening Policy

## Politika

Bu gate Docker / Compose production hardening için evidence-only çalışır.

## Altın kurallar

- docker restart/start/stop/rm çalıştırılmaz.
- docker compose up/down/restart çalıştırılmaz.
- docker network create/rm/connect/disconnect çalıştırılmaz.
- docker volume rm/prune çalıştırılmaz.
- docker system prune çalıştırılmaz.
- compose dosyası değiştirilmez.
- port publish değiştirilmez.
- Docker env veya secret değerleri rapora basılmaz.
- docker inspect sadece güvenli metadata için kullanılır.
- /proc/*/environ okunmaz.
- Secret, raw DSN, token, password veya query text basılmaz.

## Public port policy

Allowed public:
- 80 / 443 edge yüzeyi
- SSH yönetim portu ayrı güvenlik katmanıyla

Should not be public:
- PostgreSQL 5432 / 5433 / 5434
- Redis 6379
- NATS 4222 / 6222 / 8222
- Prometheus 9090
- Node Exporter 9100 / 9101
- cAdvisor 8080
- Grafana 3000 / 3001
- Loki 3100
- Tempo 3200
- OTEL 4317 / 4318
- Pix2pi internal service ports
- Unknown public ports

## Hardening markers

- restart policy
- healthcheck marker
- non-root user marker
- read_only marker
- cap_drop marker
- privileged=false
- host network yokluğu
- env_file / secret count evidence
- bind mount / volume review
- public port publish review

## Safety

CONTAINER_RESTARTED=NO
CONTAINER_STARTED=NO
CONTAINER_STOPPED=NO
CONTAINER_REMOVED=NO
DOCKER_COMPOSE_EXECUTED=NO
DOCKER_NETWORK_CHANGED=NO
DOCKER_VOLUME_CHANGED=NO
DOCKER_PORT_CHANGED=NO
DOCKER_PRUNE_EXECUTED=NO
CONFIG_CHANGED=NO
ENV_CHANGED=NO
FILE_PERMISSION_CHANGED=NO
FIREWALL_CHANGED=NO
NGINX_RELOAD_EXECUTED=NO
SERVICE_RESTARTED=NO
DEPLOY_EXECUTED=NO
DB_MUTATION=NO
DB_APPLY_EXECUTED=NO
MIGRATION_CREATED=NO
MIGRATION_APPLY_EXECUTED=NO
LOG_CONTENT_PRINTED=NO
QUERY_TEXT_PRINTED=NO
RAW_DSN_PRINTED=NO
SECRET_VALUE_PRINTED=NO
