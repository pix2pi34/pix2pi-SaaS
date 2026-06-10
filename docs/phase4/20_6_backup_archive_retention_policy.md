# FAZ 4B / 20.6 - Backup / Archive Retention Policy

## Politika

Bu gate backup/archive retention hijyenini evidence-only şekilde kontrol eder.

## Altın kurallar

- rm çalıştırılmaz.
- mv çalıştırılmaz.
- docker volume rm/prune çalıştırılmaz.
- restic forget/prune/unlock/repair çalıştırılmaz.
- pg_dump / pg_restore / psql restore çalıştırılmaz.
- Dosya içeriği okunup secret basılmaz.
- Backup içeriği açılmaz.
- Sadece path, boyut, yaş, kategori ve risk yazılır.

## Retention sınıfları

- keep_current_evidence
- keep_stateful_volume
- keep_restic_repository
- review_old_backup
- review_archive_candidate
- review_secret_backup_path
- review_large_backup
- review_db_dump
- review_observability_volume
- manual_approval_required

## Risk seviyeleri

- LOW: korunacak evidence
- MEDIUM: retention review adayı
- HIGH: secret/path veya stateful critical backup adayı
- CRITICAL: bu gate içinde beklenmez; bulunursa yine silinmez

## Önerilen production retention

- Saatlik backup: 24-48 saat
- Günlük backup: 14-30 gün
- Haftalık backup: 8-12 hafta
- Aylık backup: 12 ay
- Kritik DB volume: ayrı snapshot + restore drill
- Restic repo: forget/prune sadece ayrı onaylı adımda
- Archive cleanup: manuel approval + dry-run + backup sonrası

## Safety

BACKUP_DELETE_EXECUTED=NO
ARCHIVE_DELETE_EXECUTED=NO
FILE_DELETE_EXECUTED=NO
FILE_MOVE_EXECUTED=NO
DOCKER_VOLUME_REMOVED=NO
DOCKER_VOLUME_PRUNE_EXECUTED=NO
RESTIC_FORGET_EXECUTED=NO
RESTIC_PRUNE_EXECUTED=NO
RESTIC_REPAIR_EXECUTED=NO
RESTORE_EXECUTED=NO
PG_DUMP_EXECUTED=NO
PG_RESTORE_EXECUTED=NO
DB_MUTATION=NO
DB_APPLY_EXECUTED=NO
MIGRATION_CREATED=NO
MIGRATION_APPLY_EXECUTED=NO
CONFIG_CHANGED=NO
ENV_CHANGED=NO
SERVICE_RESTARTED=NO
CONTAINER_RESTARTED=NO
DEPLOY_EXECUTED=NO
QUERY_TEXT_PRINTED=NO
RAW_DSN_PRINTED=NO
SECRET_VALUE_PRINTED=NO
