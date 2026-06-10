# 185 — FAZ 4-15.5 Search / Index Projection Tabloları

## Amaç

FAZ 4-R DB-L6 Reporting / Readmodel bloğu için tenant-safe search / index projection altyapısı kurar.

## Kapsam

Bu adım aşağıdaki tabloları kurar:

- search_projection_sources
- search_index_documents
- search_index_terms
- search_projection_offsets
- search_projection_rebuild_jobs
- search_projection_audit_events

## Mimari Karar

Search sistemi transactional domain tablolarından ayrıdır.

Search projection readmodel mantığıyla çalışır.

Amaç:

- Yönetim panelinde hızlı arama
- Cari / ürün / stok / fiş araması
- Import batch araması
- OEM / barkod / vergi no / belge no gibi özel terim araması
- Projection offset takibi
- Rebuild job standardı
- Audit event izi

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
- Required tablolar metadata üzerinden doğrulanır.
- Required index / FK / unique constraint metadata üzerinden doğrulanır.
- Search behavior insert/update/delete testleri geçer.
- Final status gerçek test/audit sayaçlarından türetilir.
