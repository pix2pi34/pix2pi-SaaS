# FAZ 4B / 20.1 - Production Cleanup Policy

## Policy

Bu politika production öncesi temizlik gate'i içindir.

## Temel kural

Bu adım sadece evidence üretir.
Silme, taşıma, deploy, restart, chmod, chown, DB apply veya config değişikliği yapmaz.

## Güvenli kategoriler

- docs/phase4 raporları korunur.
- scripts/phase4b_* dosyaları korunur.
- db/migrations/*.up.sql ve *.down.sql pair olarak korunur.
- backups dizini doğrudan silinmez; sadece aday olarak işaretlenir.
- archive dizini doğrudan silinmez; sadece aday olarak işaretlenir.
- .env, key, pem, token, secret isimli dosyaların içeriği okunup rapora basılmaz.
- Sadece path/risk/category bilgisi yazılır.

## Candidate kategorileri

- backup_candidate
- archive_candidate
- temp_candidate
- old_file_candidate
- generated_report
- migration_file
- script_file
- potential_secret_path
- production_baseline
- keep

## Risk seviyeleri

- LOW: sadece kayıt/evidence
- MEDIUM: temizlik adayı ama manuel gözden geçirme gerekir
- HIGH: secret/key/env adı taşıyan path; içerik asla basılmaz
- CRITICAL: bu gate içinde beklenmez; bulunursa yine silinmez

## Safety

FILE_DELETE_EXECUTED=NO
FILE_MOVE_EXECUTED=NO
FILE_PERMISSION_CHANGED=NO
ENV_CHANGED=NO
DB_MUTATION=NO
DB_APPLY_EXECUTED=NO
MIGRATION_CREATED=NO
MIGRATION_APPLY_EXECUTED=NO
DEPLOY_EXECUTED=NO
SERVICE_RESTARTED=NO
CONTAINER_RESTARTED=NO
QUERY_TEXT_PRINTED=NO
RAW_DSN_PRINTED=NO
SECRET_VALUE_PRINTED=NO
