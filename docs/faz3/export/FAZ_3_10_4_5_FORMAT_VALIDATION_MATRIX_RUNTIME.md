# 138 — FAZ 3-10.4.5 — Format doğrulama matrisi runtime

## Amaç

Bu adım, ETA / Logo / Mikro / Zirve gerçek format üretimlerini tek matrix altında doğrular.

## Kapsam

- Matrix request modeli
- Matrix result modeli
- Target check result modeli
- Matrix issue modeli
- ETA format runtime bağlantısı
- Logo format runtime bağlantısı
- Mikro format runtime bağlantısı
- Zirve format runtime bağlantısı
- Tüm targetların dosya / satır / balance / hash doğrulaması
- Provider issue → matrix fail politikası
- Adapter testleri için readiness kararı

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- Runtime dosyası var
- Test dosyası var
- Config artifact var
- Documentation artifact var
- Go test PASS
- Real implementation audit PASS
- ETA / Logo / Mikro / Zirve tüm targetlar PASS
- Negative path testleri PASS
