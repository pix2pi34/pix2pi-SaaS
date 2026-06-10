# FAZ 4B / 20.6 - Backup / Archive Retention Hygiene

Amaç:
Pilot / production öncesi backup, archive, restic repo, stateful volume ve retention hijyenini evidence-only olarak kontrol etmek.

Bu adım:
- Backup silmez.
- Archive silmez.
- Volume silmez.
- Docker volume prune yapmaz.
- Restic forget / prune / unlock / repair çalıştırmaz.
- PostgreSQL dump/restore çalıştırmaz.
- DB apply yapmaz.
- DB mutate etmez.
- Migration oluşturmaz.
- Migration apply yapmaz.
- Dosya taşımaz.
- Dosya chmod/chown değiştirmez.
- Config/env değiştirmez.
- Deploy yapmaz.
- Servis restart etmez.
- Container restart etmez.
- Secret değeri, raw DSN, token, password veya query text rapora basmaz.
- Sadece path, kategori, boyut, yaş, risk ve retention candidate evidence üretir.

Ön koşul:
- 20.1 Production cleanup gate PASS olmalı.
- 20.2 Config / env hardening gate PASS olmalı.
- 20.3 Runtime service hardening PASS olmalı.
- 20.4 Nginx / reverse proxy hardening PASS olmalı.
- 20.5 Docker / compose hardening PASS olmalı.
- 21 Security / RBAC / Audit final closure PASS olmalı.

Kontrol alanları:
- backups dizini
- archive / archives dizini
- restic repo path adayları
- db dump / sql backup adayları
- docker stateful volume adayları
- postgres volume adayları
- redis volume adayları
- nats volume adayları
- observability volume adayları
- eski step backup adayları
- retention policy evidence
- no-delete / no-prune / no-restore safety

Production retention prensibi:
- Backup silme işi ayrı onaylı execution adımı olmadan yapılmaz.
- Stateful volume’lar retention/backup politikasına bağlanır.
- Restic repo sadece snapshot evidence seviyesinde incelenir.
- DB restore drill ayrı fazda yapılır.
- Archive temizliği manuel onaylı execution adımına bırakılır.
- Secret içeren backup pathleri path-only evidence olarak kalır; içerik basılmaz.

Kapanış hedefi:
BACKUP_ARCHIVE_RETENTION_HYGIENE=PASS
BACKUP_ARCHIVE_PREVIOUS_20_5=PASS
BACKUP_ARCHIVE_INVENTORY=PASS
BACKUP_ARCHIVE_VOLUME_RETENTION=PASS
BACKUP_ARCHIVE_POLICY=PASS
BACKUP_ARCHIVE_NO_DELETE=PASS
BACKUP_ARCHIVE_NO_PRUNE=PASS
BACKUP_ARCHIVE_NO_RESTORE=PASS
BACKUP_ARCHIVE_SECRET_SAFE=PASS
FAZ4B_20_6_FINAL_STATUS=PASS
