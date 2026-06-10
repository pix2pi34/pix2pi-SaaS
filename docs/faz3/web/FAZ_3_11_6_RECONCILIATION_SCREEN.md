# 158 — FAZ 3-11.6 — Reconciliation Ekranı

## Amaç

TDHP, ödeme, banka, marketplace settlement ve export mutabakatlarını tek ERP web yüzeyinde izlemek ve yönetmek.

## Kapsam

- TDHP reconciliation görünümü
- Payment reconciliation görünümü
- Bank statement reconciliation görünümü
- Marketplace settlement reconciliation görünümü
- Export reconciliation görünümü
- Difference review görünümü
- Manual review görünümü
- Closure block görünümü
- Ledger posting readiness görünümü
- Payment closure readiness görünümü
- Evidence export yüzeyi
- Tenant / correlation / request / idempotency izleri
- Document / voucher / posting / provider / bank / statement / settlement izleri
- Posting hash / audit trace hash / reconciliation hash izleri
- Audit timeline

## Canlı Politika

Bu ekran gerçek banka, gerçek ödeme sağlayıcı veya dış provider çağrısı yapmaz.

Real bank gate CLOSED, real payment gate CLOSED, real provider gate CLOSED ve production approved FALSE kalır. UI aksiyonları provider-live modülü gelene kadar dry-run/readiness yüzeyidir.

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- HTML ekran dosyası var
- Config artifact var
- Documentation artifact var
- Audit script var
- TDHP / payment / bank / marketplace / export reconciliation yüzeyleri var
- Difference review / manual review / closure block yüzeyleri var
- Ledger posting readiness / payment closure readiness yüzeyleri var
- Hash ve audit izleri var
- Real bank/payment/provider gate CLOSED
- Production approved FALSE
- Audit PASS
