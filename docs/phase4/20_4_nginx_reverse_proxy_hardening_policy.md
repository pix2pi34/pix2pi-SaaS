# FAZ 4B / 20.4 - Nginx / Reverse Proxy Hardening Policy

## Politika

Bu gate production öncesi Nginx / reverse proxy güvenliğini evidence-only şekilde kontrol eder.

## Altın kurallar

- nginx -s reload çalıştırılmaz.
- systemctl reload nginx çalıştırılmaz.
- systemctl restart nginx çalıştırılmaz.
- ufw / iptables / nftables değiştirilmez.
- Docker port publish değiştirilmez.
- Compose dosyası değiştirilmez.
- Config dosyası değiştirilmez.
- Secret, token, raw DSN, private key veya password değeri rapora basılmaz.
- Nginx config dosyalarının tamamı rapora basılmaz; sadece metadata/count/evidence yazılır.

## Production public surface policy

Allowed public:
- 80 / http
- 443 / https
- SSH management port sadece allowlist / fail2ban / key auth ile kontrollü

Should not be public:
- Redis 6379
- PostgreSQL 5432 / 5433 / 5434
- NATS 4222 / 6222 / 8222
- Prometheus 9090
- Node Exporter 9100 / 9101
- cAdvisor 8080
- Grafana 3000 / 3001
- Loki 3100
- Tempo 3200
- OTEL collector 4317 / 4318
- Pix2pi internal service ports
- Any unknown public port

## Hardening markers

- ssl_certificate
- ssl_protocols
- add_header
- X-Frame-Options
- X-Content-Type-Options
- Referrer-Policy
- Content-Security-Policy
- client_max_body_size
- proxy_read_timeout
- proxy_connect_timeout
- limit_req
- allow / deny
- auth_basic veya external auth layer

## Safety

NGINX_CONFIG_CHANGED=NO
NGINX_RELOAD_EXECUTED=NO
NGINX_RESTARTED=NO
FIREWALL_CHANGED=NO
PORT_CHANGED=NO
DOCKER_PORT_CHANGED=NO
DOCKER_COMPOSE_EXECUTED=NO
SERVICE_RESTARTED=NO
DEPLOY_EXECUTED=NO
CONFIG_CHANGED=NO
ENV_CHANGED=NO
FILE_PERMISSION_CHANGED=NO
DB_MUTATION=NO
DB_APPLY_EXECUTED=NO
MIGRATION_CREATED=NO
MIGRATION_APPLY_EXECUTED=NO
LOG_CONTENT_PRINTED=NO
QUERY_TEXT_PRINTED=NO
RAW_DSN_PRINTED=NO
SECRET_VALUE_PRINTED=NO
