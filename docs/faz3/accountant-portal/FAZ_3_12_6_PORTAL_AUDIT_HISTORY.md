# 172 — FAZ 3-12.6 — Portal Audit / İşlem Geçmişi

## Amaç

Muhasebeci portalında yapılan firma seçimi, firma değişimi, yetki kararı, export isteği, abonelik doğrulama ve erişim kararlarını append-only audit geçmişi olarak görünür hale getirmek.

## Kapsam

- Portal audit geçmişi
- Append-only audit görünümü
- COMPANY_SWITCH event
- PERMISSION_DECISION event
- EXPORT_REQUEST event
- SUBSCRIPTION_VALIDATE event
- ACCESS_DECISION event
- Actor görünümü
- Tenant / firma scope görünümü
- Correlation ID
- Request ID
- Idempotency key
- IP hash
- User agent hash
- Before / after state hash
- Event hash
- Scope hash
- Chain hash
- Evidence hash
- Evidence file
- Hash timeline

## Canlı Politika

Bu ekran append-only/read-only audit yüzeyidir.

Audit silme, audit değiştirme ve cross-tenant audit okuma kapalıdır.

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- HTML ekran dosyası var
- Config artifact var
- Documentation artifact var
- Audit script var
- Tüm event tipleri görünür
- ALLOW / REVIEW_REQUIRED / DENY / READ_ONLY kararları görünür
- Actor / tenant / firm / correlation / request / idempotency izleri görünür
- Event hash / scope hash / chain hash / evidence hash izleri görünür
- Append-only TRUE
- Audit delete FALSE
- Audit mutation FALSE
- Cross tenant audit read FALSE
- Audit PASS
