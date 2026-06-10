# FAZ 4B / 20.1 - Production File / Folder Cleanup Gate

Amaç:
Pilot / production öncesi repo ve runtime dizinlerinde dosya/dizin hijyenini kanıtlamak.

Bu adım:
- Dosya silmez.
- Dosya taşımaz.
- Dosya chmod/chown değiştirmez.
- Config/env değiştirmez.
- DB apply yapmaz.
- DB mutate etmez.
- Migration oluşturmaz.
- Migration apply yapmaz.
- Container restart etmez.
- Servis restart etmez.
- Deploy yapmaz.
- Nginx reload yapmaz.
- Secret değerlerini rapora basmaz.
- Query text rapora basmaz.
- Sadece production cleanup envanteri, risk matrisi ve evidence üretir.

Ön koşul:
- 21 Security / RBAC / Audit final closure PASS olmalı.
- 19 Panel/Admin final closure PASS olmalı.

Kontrol alanları:
- Repo ana dizin hijyeni
- docs/phase4 evidence dizinleri
- scripts dizini
- db/migrations dizini
- backups / archive / old / tmp / temp / scratch adayları
- *.bak / *.old / *.orig / *.tmp adayları
- env / secret / key isimli dosya adayları
- migration pair zinciri
- production no-delete / no-move / no-deploy safety

Cleanup candidate mantığı:
Bu gate sadece aday listesi çıkarır.
Gerçek temizlik 20.2 veya ileride ayrı onaylı execution adımında yapılır.

Kapanış hedefi:
PRODUCTION_CLEANUP_GATE=PASS
PRODUCTION_CLEANUP_PREVIOUS_21=PASS
PRODUCTION_CLEANUP_BASELINE=PASS
PRODUCTION_CLEANUP_INVENTORY=PASS
PRODUCTION_CLEANUP_MIGRATION_CHAIN=PASS
PRODUCTION_CLEANUP_NO_DELETE=PASS
PRODUCTION_CLEANUP_NO_MOVE=PASS
PRODUCTION_CLEANUP_NO_DEPLOY=PASS
PRODUCTION_CLEANUP_SECRET_SAFE=PASS
FAZ4B_20_1_FINAL_STATUS=PASS
