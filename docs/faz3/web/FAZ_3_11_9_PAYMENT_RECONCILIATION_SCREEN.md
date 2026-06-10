# 162 — FAZ 3-11.9 — Ödeme / Mutabakat Ekranı

## Amaç

POS, sanal POS, banka tahsilat, ödeme durum senkronu, iade/iptal, retry/DLQ ve ödeme mutabakatını ERP web yüzeyinde görüntülemek.

## Kapsam

- POS provider görünümü
- Sanal POS görünümü
- Banka transfer görünümü
- Banka tahsilat görünümü
- Marketplace settlement görünümü
- Authorize / capture / refund / void / cancel yüzeyleri
- Status sync görünümü
- Retry / DLQ görünümü
- Manual review görünümü
- Payment reconciliation görünümü
- Provider error görünümü
- Bank statement görünümü
- Evidence export yüzeyi
- Audit timeline

## Canlı Politika

Bu ekran gerçek ödeme, gerçek banka veya dış provider çağrısı yapmaz.

Real payment gate CLOSED, real bank gate CLOSED, production approved FALSE ve real external provider calls FALSE kalır. UI aksiyonları provider-live modülü tamamlanana kadar dry-run/readiness yüzeyidir.

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- HTML ekran dosyası var
- Config artifact var
- Documentation artifact var
- Audit script var
- POS / VPOS / bank / marketplace kanalları görünür
- Capture / refund / void / retry / audit yüzeyleri var
- Provider transaction / bank reference / statement line / settlement id izleri var
- Provider payload hash / statement hash / payment hash / reconciliation hash / audit hash izleri var
- Real payment gate CLOSED
- Real bank gate CLOSED
- Production approved FALSE
- Audit PASS
