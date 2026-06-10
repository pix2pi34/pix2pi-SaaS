# FAZ 4B / 20.3 - Runtime Service Hardening Policy

## Politika

Bu gate production öncesi çalışan servis / port / container durumunu evidence-only şekilde çıkarır.

## Altın kurallar

- systemctl restart/start/stop/reload/enable/disable çalıştırılmaz.
- docker restart/stop/start/rm/compose up/down çalıştırılmaz.
- nginx reload yapılmaz.
- journalctl log içeriği basılmaz.
- /proc/*/environ okunmaz.
- systemd Environment değeri rapora basılmaz.
- Docker env veya secret inspect edilmez.
- Sadece servis adı, state, unit path, kullanıcı bilgisi, restart policy, port ve container metadata yazılır.
- Secret değeri, raw DSN, token, password veya query text basılmaz.

## Hardening evidence kategorileri

- pix2pi_service_candidate
- critical_platform_service
- system_service
- listening_port
- docker_container
- missing_runtime_tool
- hardening_candidate
- keep

## Risk seviyeleri

- LOW: sadece evidence
- MEDIUM: production hardening adayı
- HIGH: public port / root user / missing restart policy gibi manuel inceleme adayı
- CRITICAL: bu gate içinde beklenmez; bulunursa yine değişiklik yapılmaz

## Safety

SERVICE_RESTARTED=NO
SERVICE_STARTED=NO
SERVICE_STOPPED=NO
SYSTEMD_UNIT_CHANGED=NO
SYSTEMD_ENABLE_CHANGED=NO
CONTAINER_RESTARTED=NO
DOCKER_COMPOSE_EXECUTED=NO
NGINX_RELOAD_EXECUTED=NO
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
