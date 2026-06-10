# FAZ 4B / 20.2 - Config / Env Hardening Policy

## Politika

Bu gate production öncesi config/env güvenlik envanteri içindir.

## Altın kurallar

- Secret değeri rapora basılmaz.
- Raw DSN rapora basılmaz.
- Token değeri rapora basılmaz.
- Private key içeriği rapora basılmaz.
- .env içeriği full olarak rapora basılmaz.
- Sadece path, dosya modu, risk sınıfı ve key-name sayımı yapılabilir.
- Permission change yapılmaz.
- Config/env değişikliği yapılmaz.
- Restart/deploy yapılmaz.

## Production önerisi

- Secret taşıyan dosyalar mümkünse repo dışında tutulmalı.
- Env dosyaları 600 veya daha sıkı olmalı.
- Config dosyaları gereksiz executable olmamalı.
- Backup içinde secret içeren env dosyaları ayrıca incelenmeli.
- DSN/token/password değerleri merkezi secret yönetimine taşınmalı.
- Report içinde sadece masked/metadata evidence bulunmalı.

## Candidate kategorileri

- env_file
- config_file
- potential_secret_path
- key_material_path
- backup_env_candidate
- world_readable_candidate
- group_readable_candidate
- executable_config_candidate
- keep

## Risk seviyeleri

- LOW: sadece config/evidence
- MEDIUM: manuel hardening adayı
- HIGH: secret/env/key path veya izin riski
- CRITICAL: bu gate içinde beklenmez; bulunursa yine değişiklik yapılmaz

## Safety

CONFIG_CHANGED=NO
ENV_CHANGED=NO
FILE_PERMISSION_CHANGED=NO
FILE_DELETE_EXECUTED=NO
FILE_MOVE_EXECUTED=NO
DB_MUTATION=NO
DB_APPLY_EXECUTED=NO
MIGRATION_CREATED=NO
MIGRATION_APPLY_EXECUTED=NO
DEPLOY_EXECUTED=NO
NGINX_RELOAD_EXECUTED=NO
SERVICE_RESTARTED=NO
CONTAINER_RESTARTED=NO
QUERY_TEXT_PRINTED=NO
RAW_DSN_PRINTED=NO
SECRET_VALUE_PRINTED=NO
