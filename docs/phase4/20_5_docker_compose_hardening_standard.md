# FAZ 4B / 20.5 - Docker / Compose Hardening

Amaç:
Pilot / production öncesi Docker container, compose, network, volume ve public port publish güvenliğini evidence-only olarak kontrol etmek.

Bu adım:
- Docker container restart etmez.
- Docker container start/stop/rm yapmaz.
- Docker compose up/down/restart yapmaz.
- Docker network değiştirmez.
- Docker volume değiştirmez.
- Docker port publish değiştirmez.
- Compose dosyası değiştirmez.
- Config/env değiştirmez.
- Dosya chmod/chown değiştirmez.
- Firewall değiştirmez.
- Nginx reload yapmaz.
- Servis restart etmez.
- Deploy yapmaz.
- DB apply yapmaz.
- DB mutate etmez.
- Migration oluşturmaz.
- Migration apply yapmaz.
- Docker inspect ile environment value basmaz.
- Secret değeri, raw DSN, token, password veya query text rapora basmaz.
- Sadece container, image, status, port, network, volume ve compose metadata evidence üretir.

Ön koşul:
- 20.1 Production cleanup gate PASS olmalı.
- 20.2 Config / env hardening gate PASS olmalı.
- 20.3 Runtime service hardening PASS olmalı.
- 20.4 Nginx / reverse proxy hardening PASS olmalı.
- 21 Security / RBAC / Audit final closure PASS olmalı.

Production hedef prensibi:
- Public publish sadece edge yüzeylerde olmalı.
- DB, Redis, NATS, metrics, tracing, logging ve internal Pix2pi servisleri doğrudan public port publish etmemeli.
- Compose dosyalarında privileged/root/cap_add/host network gibi yüzeyler manuel incelenmeli.
- Container env değerleri rapora basılmamalı.
- Secret taşıyan env_file / environment sadece key-name veya count seviyesinde izlenmeli.
- Named volume ve bind mountlar production retention ve backup politikasına bağlanmalı.
- Restart policy evidence alınmalı.
- Healthcheck marker evidence alınmalı.

Kapanış hedefi:
DOCKER_COMPOSE_HARDENING=PASS
DOCKER_COMPOSE_PREVIOUS_20_4=PASS
DOCKER_CONTAINER_INVENTORY=PASS
DOCKER_COMPOSE_INVENTORY=PASS
DOCKER_NETWORK_INVENTORY=PASS
DOCKER_VOLUME_INVENTORY=PASS
DOCKER_PUBLIC_PORT_POLICY=PASS
DOCKER_HARDENING_MATRIX=PASS
DOCKER_NO_RUNTIME_CHANGE=PASS
DOCKER_NO_DEPLOY=PASS
DOCKER_SECRET_SAFE=PASS
FAZ4B_20_5_FINAL_STATUS=PASS
