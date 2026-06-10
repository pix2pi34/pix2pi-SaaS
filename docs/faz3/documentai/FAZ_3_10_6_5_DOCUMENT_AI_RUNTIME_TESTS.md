# 150 — FAZ 3-10.6.5 — Belge AI runtime testleri

## Amaç

FAZ 3-10.6 Document AI / OCR-Lens modül ailesini uçtan uca doğrular.

## Kapsam

- OCR / Lens processing runtime bridge
- Tax field extraction runtime bridge
- Contact field extraction runtime bridge
- Confidence + review queue runtime bridge
- Happy path: OCR → tax extraction → contact extraction
- Review path: OCR review → tax review → contact review → review queue
- Runtime hash doğrulama
- Tenant validation
- Source file hash validation
- Source text validation
- Suite hash üretimi

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- Suite dosyası var
- Test dosyası var
- Config artifact var
- Documentation artifact var
- Go test PASS
- Real implementation audit PASS
- OCR happy path PASS
- Tax extraction happy path PASS
- Contact extraction happy path PASS
- OCR review path PASS
- Tax review queue path PASS
- Contact review queue path PASS
- Validation guards PASS
