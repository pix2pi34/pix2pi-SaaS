# 149 — FAZ 3-10.6.4 — Confidence + review queue runtime

## Amaç

Document AI / OCR-Lens ailesinde düşük confidence, eksik alan ve manuel kontrol gerektiren kayıtları review queue içine alır.

## Kapsam

- Review source type modeli
- Review status modeli
- Review priority modeli
- Review action modeli
- Review item modeli
- Review decision modeli
- Register review runtime
- OCR review bridge
- Tax extraction review bridge
- Contact extraction review bridge
- Assign runtime
- Resolve approve runtime
- Resolve reject runtime
- Dismiss runtime
- List open runtime
- Priority calculation
- Tenant-safe in-memory queue
- Decision hash üretimi

## Canlı Politika

Bu runtime gerçek queue/DB yazımı yapmaz. FAZ 3 içinde deterministic ve tenant-safe in-memory review queue çekirdeğidir. DB persistence ve UI yüzeyi ayrı fazlarda bağlanabilir.

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- Runtime dosyası var
- Test dosyası var
- Config artifact var
- Documentation artifact var
- Go test PASS
- Real implementation audit PASS
- OCR review register PASS
- Tax review register PASS
- Contact review register PASS
- Assign PASS
- Resolve approve/reject PASS
- Dismiss PASS
- List open tenant scope PASS
- Validation guards PASS
