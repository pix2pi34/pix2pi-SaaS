# 129 — FAZ 3-10.1.2 — Hesap planı live version switch

## Amaç

Bu adım, TDHP hesap planı ve hesap mapping versiyonlarının canlıda güvenli şekilde prepare / activate / rollback edilmesini sağlar.

## Kapsam

- Chart version modeli
- Account mapping rule modeli
- Full switch
- Canary switch
- Blue/green switch readiness
- Activate switch
- Rollback switch
- Resolve account by active version
- Legal reference guard
- Approval guard
- Evidence file/hash guard
- Artifact path guard
- Country TR guard
- Currency TRY guard
- Required account purpose coverage
- TDHP prefix validation
- Canary percent guard
- Canary tenant allowlist guard
- Rollback reason guard

## TDHP Prefix Kontrolleri

- 120 Alıcılar
- 600 Satışlar
- 391 Hesaplanan KDV
- 153 Ticari mallar
- 191 İndirilecek KDV
- 320 Satıcılar
- 102 Bankalar
- 610 Satıştan iadeler
- 500 Açılış / sermaye

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- Runtime dosyası var
- Test dosyası var
- Config artifact var
- Documentation artifact var
- Go test PASS
- Real implementation audit PASS
- Prepare / canary / activate / rollback / resolve / invalid prefix testleri PASS
