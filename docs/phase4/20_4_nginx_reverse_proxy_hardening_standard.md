# FAZ 4B / 20.4 - Nginx / Reverse Proxy Hardening

Amaç:
Pilot / production öncesi public yüzeyi Nginx / reverse proxy düzenine bağlamak için evidence-only hardening gate üretmek.

Bu adım:
- Nginx reload yapmaz.
- Nginx config değiştirmez.
- Firewall değiştirmez.
- Port kapatmaz.
- Docker restart yapmaz.
- Docker compose up/down yapmaz.
- Servis restart etmez.
- Deploy yapmaz.
- Config/env değiştirmez.
- Dosya chmod/chown değiştirmez.
- DB apply yapmaz.
- DB mutate etmez.
- Migration oluşturmaz.
- Migration apply yapmaz.
- Log içeriği basmaz.
- Secret değeri, raw DSN, token, password veya query text rapora basmaz.
- Sadece Nginx config metadata, reverse proxy surface, public port policy ve risk evidence üretir.

Ön koşul:
- 20.1 Production cleanup gate PASS olmalı.
- 20.2 Config / env hardening gate PASS olmalı.
- 20.3 Runtime service hardening PASS olmalı.
- 21 Security / RBAC / Audit final closure PASS olmalı.

Production hedef prensibi:
- Dış dünyaya normalde sadece 80/443 açık kalmalı.
- SSH portu ayrıca kontrollü yönetim yüzeyi olarak ele alınmalı.
- Redis, PostgreSQL, NATS, Prometheus, Node Exporter, cAdvisor, Loki, Tempo, Grafana ve internal Pix2pi servisleri doğrudan public olmamalı.
- Internal servisler Nginx / API Gateway / private network arkasında tutulmalı.
- Health / metrics endpointleri public olmamalı.
- Observability stack private veya VPN / auth / allowlist arkasında olmalı.
- DB, cache ve event bus public interface dinlememeli.
- TLS, security header, body limit, timeout ve rate-limit standardı ayrıca güçlendirilmeli.

Kontrol alanları:
- Nginx config path inventory
- server/listen/proxy_pass metadata
- security header markerları
- TLS markerları
- reverse proxy surface manifest
- public port policy manifest
- internal_should_not_public port adayları
- no-reload / no-deploy / no-secret safety

Kapanış hedefi:
NGINX_REVERSE_PROXY_HARDENING=PASS
NGINX_REVERSE_PROXY_PREVIOUS_20_3=PASS
NGINX_CONFIG_INVENTORY=PASS
NGINX_PROXY_SURFACE_MANIFEST=PASS
NGINX_PUBLIC_PORT_POLICY=PASS
NGINX_HARDENING_MATRIX=PASS
NGINX_NO_RELOAD=PASS
NGINX_NO_FIREWALL_CHANGE=PASS
NGINX_NO_DEPLOY=PASS
NGINX_SECRET_SAFE=PASS
FAZ4B_20_4_FINAL_STATUS=PASS
