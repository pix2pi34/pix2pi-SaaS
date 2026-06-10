# FAZ 7-8M — Mikro Connector Module Foundation

## Amaç

Bu faz, Pix2pi entegrasyon ailesinde Mikro sağlayıcısı için provider-specific connector foundation kurar.

Bu modül gerçek Mikro bağlantısı açmaz.
Bu modül gerçek dosya gönderimi yapmaz.
Bu modül gerçek ERP write yapmaz.

Bu modülün görevi:

- Mikro provider identity standardını tanımlamak
- Mikro dry-run connector foundation runtime kontratını oluşturmak
- Mikro capability matrix başlangıcını tanımlamak
- tenant / correlation / actor guard zorunluluğunu koymak
- secret value / real token / real endpoint kullanımını yasaklamak
- gerçek provider API, gerçek dosya teslimi ve gerçek ERP write kapılarını kapalı tutmak
- sonraki Mikro alt modüllerine kontrollü handoff zemini hazırlamak

## Faz Bilgisi

- Phase: FAZ_7_8M
- Module: Mikro Connector Module Foundation
- Provider ID: mikro
- Provider Name: Mikro
- Connector Mode: DRY_RUN_CONTRACT_ONLY
- Foundation Gate: READY
- Provider Live Handoff Gate: CLOSED_UNTIL_MIKRO_CONNECTOR_FINAL_CLOSURE

## Zorunlu Kapalı Kapılar

Aşağıdaki gerçek operasyonlar bu fazda kapalıdır:

- MIKRO_REAL_PROVIDER_API_STATUS=CLOSED_UNTIL_PROVIDER_LIVE_MODULE
- MIKRO_REAL_FILE_DELIVERY_STATUS=CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE
- MIKRO_REAL_ERP_WRITE_STATUS=CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE

## Foundation Scope

Bu fazda kurulan kapsam:

1. Mikro provider metadata
2. Mikro dry-run runtime contract
3. Mikro capability matrix başlangıcı
4. tenant-safe request guard
5. correlation-safe audit guard
6. actor-safe operation guard
7. secret value forbidden guard
8. real provider API forbidden guard
9. real file delivery forbidden guard
10. real ERP write forbidden guard
11. test suite
12. real implementation audit

## Bu Fazda Bilerek Yapılmayanlar

Aşağıdaki işler bu fazda yapılmaz:

- gerçek Mikro API bağlantısı
- gerçek Mikro kullanıcı adı / şifre / token saklama
- gerçek Mikro dosya üretimi
- gerçek Mikro dosya gönderimi
- gerçek ERP write
- gerçek sync worker
- gerçek import delivery
- canlı müşteri verisi gönderimi

Bunlar ileride ayrı provider live / sync worker / delivery modüllerinde açılacaktır.

## Audit Zorunlulukları

Real implementation audit şunları doğrulamalıdır:

- doküman var
- config artifact var
- Mikro runtime code var
- Mikro test code var
- provider id mikro olarak tanımlı
- FAZ_7_8M phase tanımlı
- real provider API kapalı
- real file delivery kapalı
- real ERP write kapalı
- tenant guard var
- correlation guard var
- actor guard var
- secret value forbidden guard var
- capability matrix var
- dry-run decision runtime var
- testlerde 7-8M, 7-8M.x ve 7-8M.x.x görünür OK çıktıları var

## Çıkış Kapısı

Bu fazın başarılı sayılması için:

- Go test PASS olmalı
- Real implementation audit PASS olmalı
- REQUIRED_FAIL=0 olmalı
- final status sayaçlardan türemeli
- gerçek Mikro bağlantısı kapalı kalmalı
- FAZ 7-9 HOLD durumunda kalmalı

