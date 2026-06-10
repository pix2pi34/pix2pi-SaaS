# FAZ 4B / 20.3 - Runtime Service Hardening

Amaç:
Pilot / production öncesi runtime servis güvenliği ve operasyon hijyenini evidence-only olarak kontrol etmek.

Bu adım:
- Servis restart etmez.
- Servis start/stop yapmaz.
- systemd unit değiştirmez.
- systemctl enable/disable yapmaz.
- Docker container restart etmez.
- Docker compose up/down yapmaz.
- Nginx reload yapmaz.
- Deploy yapmaz.
- Dosya chmod/chown değiştirmez.
- Config/env değiştirmez.
- DB apply yapmaz.
- DB mutate etmez.
- Migration oluşturmaz.
- Migration apply yapmaz.
- Log içeriği veya secret değeri rapora basmaz.
- Raw DSN, token, password veya query text rapora basmaz.
- Sadece runtime service, port, container, unit metadata ve hardening candidate evidence üretir.

Ön koşul:
- 20.1 Production cleanup gate PASS olmalı.
- 20.2 Config / env hardening gate PASS olmalı.
- 21 Security / RBAC / Audit final closure PASS olmalı.

Kontrol alanları:
- systemd service inventory
- Pix2pi service unit adayları
- critical platform services
- listening port inventory
- Docker container inventory
- runtime user evidence
- restart policy evidence
- service state evidence
- health endpoint readiness notu
- no-restart / no-deploy / no-secret safety

Runtime hardening adayları:
- systemd unit user/root kullanımı
- restart policy yokluğu
- wanted-by / enabled durumu
- public listening port adayları
- Docker container running state
- orphan / exited container adayları
- nginx/docker/fail2ban/postgres gibi kritik servislerin varlığı
- service health gate için ileride 20.7 testlerine taşınacak evidence

Kapanış hedefi:
RUNTIME_SERVICE_HARDENING=PASS
RUNTIME_SERVICE_PREVIOUS_20_2=PASS
RUNTIME_SERVICE_SYSTEMD_INVENTORY=PASS
RUNTIME_SERVICE_PORT_INVENTORY=PASS
RUNTIME_SERVICE_CONTAINER_INVENTORY=PASS
RUNTIME_SERVICE_HARDENING_MATRIX=PASS
RUNTIME_SERVICE_NO_RESTART=PASS
RUNTIME_SERVICE_NO_DEPLOY=PASS
RUNTIME_SERVICE_SECRET_SAFE=PASS
FAZ4B_20_3_FINAL_STATUS=PASS
