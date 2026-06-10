# 190 — FAZ 4-15.7 Readmodel / Reporting Test Seti

## Amaç

FAZ 4-R DB-L6 Reporting / Readmodel bloğunda kurulan 185–189 arası reporting/readmodel altyapısını birlikte test eder.

## Kapsam

Bu test seti aşağıdaki adımları birlikte doğrular:

- 185 — Search / index projection tabloları
- 186 — Finance reporting mart
- 187 — Payment / reconciliation reporting mart
- 188 — e-Belge / export reporting mart
- 189 — Materialized view / cache projection standardı

## Test Yaklaşımı

Test canlı domain datasına yazmaz.

Akış:

1. En güncel 185–189 migration dosyaları bulunur.
2. Temporary schema oluşturulur.
3. Migration dosyaları aynı schema içinde sırayla apply edilir.
4. Search document projection test edilir.
5. Finance reporting mart test edilir.
6. Payment reconciliation reporting mart test edilir.
7. e-Belge / export reporting mart test edilir.
8. Materialized cache projection health test edilir.
9. Cross-readmodel summary consistency test edilir.
10. FK guard ve rollback safety doğrulanır.

## Tenant Güvenliği

Tüm test kayıtları tenant_test_190 altında çalışır.

## Dış Provider Policy

Bu adım canlı dış provider, GIB, banka veya POS aktivasyonu yapmaz.

Policy:

CLOSED_POLICY_GATE_REFERENCE_ONLY

## Çıkış Kriterleri

Bu adım PASS sayılırsa:

- Doc artifact vardır.
- Config artifact vardır.
- SQL test artifact vardır.
- Audit script vardır.
- 185–189 migration dependency dosyaları bulunur.
- PostgreSQL temporary schema içinde tüm migration chain apply edilir.
- Readmodel/reporting cross-domain behavior testleri geçer.
- Materialized view refresh doğrulanır.
- Final status gerçek test/audit sayaçlarından türetilir.
