# 171 — FAZ 3-12.5 — Abonelik / Durum Görünümü

## Amaç

Muhasebeci portalında firma bazlı abonelik durumlarını, paket/kota bilgilerini, aylık doğrulama ve erişim kararlarını görünür hale getirmek.

## Kapsam

- Firma abonelik durumu
- Muhasebeci abonelik görünümü
- Aylık doğrulama görünümü
- Paket / plan görünümü
- ACTIVE / TRIAL / SUSPENDED / EXPIRED durumları
- ACCESS_ALLOWED / READ_ONLY_ALLOWED / ACCESS_BLOCKED kararları
- Firma limiti
- Export kotası
- Renewal date
- Validation date
- Billing mode
- Subscription hash / quota hash / access hash / audit hash izleri
- Audit timeline

## Canlı Politika

Bu ekran gerçek billing, ödeme alma veya fatura kesme yapmaz.

Production approved FALSE, real billing allowed FALSE, real payment collection allowed FALSE, real invoice issue allowed FALSE kalır.

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- HTML ekran dosyası var
- Config artifact var
- Documentation artifact var
- Audit script var
- ACTIVE / TRIAL / SUSPENDED / EXPIRED görünür
- ACCOUNTANT_STARTER / ACCOUNTANT_PRO / ACCOUNTANT_ENTERPRISE görünür
- ACCESS_ALLOWED / READ_ONLY_ALLOWED / ACCESS_BLOCKED görünür
- Kota, renewal, validation, billing mode görünür
- Real billing FALSE
- Audit PASS
