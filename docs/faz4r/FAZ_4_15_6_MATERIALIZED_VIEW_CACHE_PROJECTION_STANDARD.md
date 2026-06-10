# 189 — FAZ 4-15.6 Materialized View / Cache Projection Standardı

## Amaç

FAZ 4-R DB-L6 Reporting / Readmodel kapsamında materialized view ve cache projection standardını kurar.

## Kapsam

Bu adım aşağıdaki altyapıyı kurar:

- materialized_projection_definitions
- projection_cache_profiles
- projection_cache_entries
- materialized_projection_dependencies
- materialized_projection_refresh_jobs
- materialized_projection_audit_events
- mv_projection_cache_health

## Mimari Karar

Bu yapı transactional domain tablolarından ayrıdır.

Amaç:

- Projection tanımlarını izlenebilir hale getirmek
- Cache profile standardı kurmak
- Cache entry lifecycle yönetmek
- Projection dependency izlerini tutmak
- Refresh job standardı kurmak
- Cache health materialized view ile hızlı operasyonel okuma sağlamak

## Tenant Güvenliği

Tüm tablolarda tenant_id zorunludur.

Primary key ve index tasarımları tenant_id ile başlar.

## Dış Provider Policy

Bu adım canlı dış provider, GIB, banka veya POS aktivasyonu yapmaz.

Policy:

CLOSED_POLICY_GATE_REFERENCE_ONLY

## Çıkış Kriterleri

Bu adım PASS sayılırsa:

- Migration dosyası vardır.
- Rollback dosyası vardır.
- Config artifact vardır.
- SQL test artifact vardır.
- Audit script vardır.
- PostgreSQL temporary schema içinde migration uygulanır.
- Required tablolar ve materialized view metadata üzerinden doğrulanır.
- Required FK / unique / index yapıları doğrulanır.
- Cache entry lifecycle davranış testleri geçer.
- Refresh job davranış testleri geçer.
- Materialized view refresh davranışı doğrulanır.
- Final status gerçek test/audit sayaçlarından türetilir.
