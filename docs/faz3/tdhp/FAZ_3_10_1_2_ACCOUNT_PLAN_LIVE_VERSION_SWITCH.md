# 129 — FAZ 3-10.1.2 — Hesap planı live version switch

## Amaç

TDHP hesap planı versiyon geçişinin live-ready simülasyon seviyesinde doğrulanması.

## Kapsam

- Account switch runtime paketi
- Versiyon geçiş modeli
- Tenant guard
- Correlation guard
- Idempotency guard
- Active version / target version mantığı
- Go test doğrulaması
- Real implementation audit evidence

## Canlı Politika

Bu adım gerçek production hesap planı aktivasyonu değildir. Runtime geçiş mantığı ve test kanıtı hazırdır.
