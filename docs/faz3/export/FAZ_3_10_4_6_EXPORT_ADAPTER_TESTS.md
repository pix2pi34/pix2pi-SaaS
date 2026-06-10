# 139 — FAZ 3-10.4.6 — Export adapter testleri

## Amaç

Bu adım, ETA / Logo / Mikro / Zirve export adapter format üretimlerini ve format validation matrix runtime sonucunu tek E2E test suite altında doğrular.

## Kapsam

- ETA adapter package generation test
- Logo adapter package generation test
- Mikro adapter package generation test
- Zirve adapter package generation test
- Format matrix ready test
- Adapter file count validation
- Adapter row count validation
- Adapter package hash validation
- Adapter balance validation
- Invalid account prefix negative test
- Tenant mismatch negative test
- Missing posting hash negative test
- Export family closure readiness decision

## Canlı Politika

Bu adım dış sisteme gerçek dosya göndermez. Export adapter paketlerini runtime seviyesinde üretir, doğrular ve matrix ile kapatır.

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- Suite dosyası var
- Test dosyası var
- Config artifact var
- Documentation artifact var
- Go test PASS
- Real implementation audit PASS
- ETA / Logo / Mikro / Zirve adapter sonuçları PASS
- Format matrix PASS
- Negative tests PASS
