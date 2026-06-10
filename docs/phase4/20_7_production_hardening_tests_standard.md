# FAZ 4B / 20.7 - Production Hardening Tests

Amaç:
FAZ 4B / 20 altında 20.1-20.6 arasında üretilen production hardening evidence gate'lerini tek test setinde doğrulamak.

Bu adım:
- Dosya silmez.
- Dosya taşımaz.
- Permission değiştirmez.
- Config/env değiştirmez.
- Firewall değiştirmez.
- Nginx reload/restart yapmaz.
- Docker container restart/start/stop/remove yapmaz.
- Docker compose up/down/restart yapmaz.
- Docker network/volume/port değiştirmez.
- Docker prune çalıştırmaz.
- Restic forget/prune/repair çalıştırmaz.
- Restore çalıştırmaz.
- Pg dump/restore çalıştırmaz.
- Servis restart etmez.
- Deploy yapmaz.
- DB apply yapmaz.
- DB mutate etmez.
- Migration oluşturmaz.
- Migration apply yapmaz.
- Secret değeri, raw DSN, token, password veya query text rapora basmaz.

Kapsam:
- 20.1 Production file / folder cleanup gate
- 20.2 Config / env hardening gate
- 20.3 Runtime service hardening
- 20.4 Nginx / reverse proxy hardening
- 20.5 Docker / compose hardening
- 20.6 Backup / archive retention hygiene

Test hedefleri:
- Tüm 20.1-20.6 final status değerleri PASS olmalı.
- Tüm domain gate değerleri PASS olmalı.
- Tüm no-change / no-delete / no-restart / no-deploy / no-secret kararları korunmalı.
- Risk evidence sayıları kaybolmamalı.
- Production hardening final closure öncesi tek birleşik test raporu üretilmeli.

Kapanış hedefi:
PRODUCTION_HARDENING_TESTS=PASS
PRODUCTION_TEST_CLEANUP=PASS
PRODUCTION_TEST_CONFIG_ENV=PASS
PRODUCTION_TEST_RUNTIME_SERVICE=PASS
PRODUCTION_TEST_NGINX=PASS
PRODUCTION_TEST_DOCKER=PASS
PRODUCTION_TEST_BACKUP_ARCHIVE=PASS
PRODUCTION_TEST_ARTIFACT_COVERAGE=PASS
PRODUCTION_TEST_NO_CHANGE=PASS
PRODUCTION_TEST_RISK_EVIDENCE=PASS
PRODUCTION_TEST_SECRET_SAFE=PASS
FAZ4B_20_7_FINAL_STATUS=PASS
