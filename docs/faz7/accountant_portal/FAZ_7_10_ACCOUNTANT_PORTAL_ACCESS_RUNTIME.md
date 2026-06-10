# FAZ 7-10 — Accountant Portal Access / Multi-Firm Runtime Surface

## Amaç

Bu modül, FAZ 7-9 ticari yüzeyinin üzerine muhasebeci portalı çok firmalı erişim runtime yüzeyini kurar.

Kapsam:
- Muhasebeci tenant → firma tenant erişim grant modeli
- Kullanıcı bazlı firma erişimi
- Dönem bazlı erişim sınırı
- Permission bazlı firma context seçimi
- Visible firm listesi
- Revoke modeli
- Access decision audit trail
- Cross-tenant izolasyon
- Live export / provider API / ERP write kapalı kalma garantisi

## Runtime kuralı

Bir muhasebeci kullanıcısının firma context seçebilmesi için şu şartlar gerekir:

1. accountant_tenant_id boş olmamalı
2. firm_tenant_id boş olmamalı
3. user_id boş olmamalı
4. period YYYY-MM formatında olmalı
5. accountant_tenant_id ve firm_tenant_id aynı olmamalı
6. aktif access grant bulunmalı
7. grant aynı accountant tenant + firm tenant + user + period için olmalı
8. gerekli permission grant içinde olmalı
9. live gates kapalı olmalı

## Kapalı kalan live işlemler

Bu fazda aşağıdaki işlemler kapalıdır:

- Gerçek muhasebeci billing
- Gerçek ödeme capture
- Gerçek provider API operasyonu
- Gerçek dosya teslimi
- Gerçek ERP write
- Gerçek müşteri verisi export
- Gerçek operator provider action

## Acceptance criteria

- Runtime kodu var
- Test kodu var
- Config var
- Dokümantasyon var
- Audit script var
- Grant firm access var
- Select firm context var
- Permission enforcement var
- Cross-tenant isolation var
- Period isolation var
- Revoke var
- Live customer data export blocker var
- Real provider operation blocker var
- Real ERP write blocker var
- Audit trail var
- Go test PASS
- Real implementation audit PASS
