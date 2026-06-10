# FAZ 4B / 20.2 - Config / Env Hardening Gate

Amaç:
Pilot / production öncesi config ve env dosyalarının güvenlik hijyenini kanıtlamak.

Bu adım:
- .env içeriğini rapora basmaz.
- Secret değerlerini rapora basmaz.
- Raw DSN rapora basmaz.
- Token / password / private key değerlerini rapora basmaz.
- Dosya chmod/chown değiştirmez.
- Config/env değiştirmez.
- Dosya silmez.
- Dosya taşımaz.
- DB apply yapmaz.
- DB mutate etmez.
- Migration oluşturmaz.
- Migration apply yapmaz.
- Container restart etmez.
- Servis restart etmez.
- Deploy yapmaz.
- Nginx reload yapmaz.
- Sadece path, izin modu, dosya tipi, risk sınıfı ve candidate evidence üretir.

Ön koşul:
- 20.1 Production cleanup gate PASS olmalı.
- 21 Security / RBAC / Audit final closure PASS olmalı.

Kontrol alanları:
- .env / *.env / env dosya pathleri
- config dosya pathleri
- secret / token / key / pem / password isimli pathler
- dosya izin modu
- group/world readable riski
- executable config/env riski
- repo içinde secret-like path bulunması
- config/env değerlerinin rapora basılmaması
- production-safe env standardı
- no-mutation / no-restart / no-deploy safety

Hardening candidate mantığı:
Bu gate sadece aday listesi çıkarır.
Gerçek chmod/chown/env taşıma/secret rotation 20.3 veya ayrı onaylı execution adımında yapılır.

Kapanış hedefi:
CONFIG_ENV_HARDENING_GATE=PASS
CONFIG_ENV_PREVIOUS_20_1=PASS
CONFIG_ENV_BASELINE=PASS
CONFIG_ENV_INVENTORY=PASS
CONFIG_ENV_PERMISSION_EVIDENCE=PASS
CONFIG_ENV_VALUE_NOT_PRINTED=PASS
CONFIG_ENV_NO_CHANGE=PASS
CONFIG_ENV_NO_DEPLOY=PASS
CONFIG_ENV_SECRET_SAFE=PASS
FAZ4B_20_2_FINAL_STATUS=PASS
