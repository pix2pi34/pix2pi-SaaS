# 152 — FAZ 3-10.8.6 — ERP-TR live readiness closure

## Amaç

ERP Türkiye çekirdeğinin canlıya hazırlık kapanış kontrolünü yapar.

## Kapsam

- ERP-TR core final recheck evidence
- TDHP live tests evidence
- Tax runtime tests evidence
- Payment integration tests evidence
- Export adapter tests evidence
- Document AI runtime tests evidence
- e-Belge smoke evidence
- Real provider gates closed policy
- Production approved=false policy
- Closure hash üretimi

## Canlı Politika

Bu closure production live açılışı değildir.

Gerçek provider, gerçek ödeme, gerçek e-Belge/GİB, gerçek dış sistem çağrıları bu adımda kapalı kalır. Bu adım sadece ERP-TR runtime ailesinin canlıya hazırlık açısından geçişe hazır olduğunu kanıtlar.

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- Runtime dosyası var
- Test dosyası var
- Config artifact var
- Documentation artifact var
- Tüm required evidence dosyaları var
- İlgili Go test paketleri PASS
- Real provider gates CLOSED
- Production approved FALSE
- Closure hash üretilmiş
- FAIL_COUNT=0
