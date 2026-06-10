# 128 — FAZ 3-10.1.1 — Gerçek fiş oluşturma pipeline’ı

## Amaç

Bu adım, Türkiye ERP core içinde belge bazlı gerçek TDHP fiş oluşturma pipeline'ını kurar.

## Kapsam

- Source document validation
- TDHP account mapping
- Sales invoice voucher generation
- Purchase invoice voucher generation
- Payment collection voucher generation
- Sales refund voucher generation
- Purchase refund voucher generation
- Opening balance voucher generation
- Debit / credit balancing
- Posting-ready decision
- Audit trace ID generation
- Tenant / correlation / request / idempotency guard
- Party trace guard
- Tax trace guard
- TRY currency guard
- TDHP account prefix validation

## Varsayılan TDHP İzleri

- 120 Alıcılar
- 600 Satışlar
- 391 Hesaplanan KDV
- 191 İndirilecek KDV
- 320 Satıcılar
- 102 Bankalar
- 153 Ticari mallar
- 610 Satıştan iadeler

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- Runtime dosyası var
- Test dosyası var
- Config artifact var
- Documentation artifact var
- Go test PASS
- Real implementation audit PASS
- Satış / alış / tahsilat / iade fişleri balanced ve posting-ready olur
