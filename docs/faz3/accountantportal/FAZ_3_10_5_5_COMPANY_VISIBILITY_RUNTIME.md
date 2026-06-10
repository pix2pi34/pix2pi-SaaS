# 144 — FAZ 3-10.5.5 — Firma görünürlüğü runtime

## Amaç

Muhasebeci portalında kullanıcıya hangi firmaların görüneceğini abonelik, çok firmalı erişim, assignment, firma profili ve yetki kurallarına göre belirler.

## Kapsam

- Company profile modeli
- Company visibility request modeli
- Company visibility item modeli
- Company visibility result modeli
- Monthly subscription runtime bridge
- Multi-firm access runtime bridge
- Active subscription guard
- Active assignment guard
- Tenant scope guard
- Company scope guard
- Company profile guard
- Company status guard
- Visible-in-portal flag guard
- Permission match guard
- Visibility hash üretimi

## Canlı Politika

Bu runtime UI değildir; muhasebeci portalı firma listeleme ekranlarının arkasındaki görünürlük karar çekirdeğidir.

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- Runtime dosyası var
- Test dosyası var
- Config artifact var
- Documentation artifact var
- Go test PASS
- Real implementation audit PASS
- Visible company path PASS
- Hidden company path PASS
- Denied company path PASS
- Subscription denied path PASS
- Assignment filter path PASS
- Permission filter path PASS
