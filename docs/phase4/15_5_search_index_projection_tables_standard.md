# FAZ 4B / 15.5 - Search / Index Projection Tabloları

Amaç:
Pilot öncesi cari, ürün, stok, belge, finans ve global arama için tenant-safe search/index projection tablolarını oluşturmak.

Bu adım:
- Migration pair oluşturur.
- DB apply yapmaz.
- DB mutate etmez.
- SQL çalıştırmaz.
- PostgreSQL config değiştirmez.
- Container restart etmez.
- Raw DSN, password, token veya query text rapora basmaz.

Oluşturulacak schema:
- `search_projection`

Oluşturulacak tablolar:
1. `search_projection.party_search_documents`
2. `search_projection.product_search_documents`
3. `search_projection.inventory_search_documents`
4. `search_projection.business_document_search_documents`
5. `search_projection.finance_search_documents`
6. `search_projection.global_search_documents`
7. `search_projection.search_projection_rebuild_state`

Arama kapsamı:
- Cari / müşteri / tedarikçi
- Ürün / SKU / barkod / kategori
- Stok lokasyonu / stok durumu
- Belge / e-Belge / export belgesi
- Finans hesap / fiş / journal özeti
- Global tenant araması

Tenant güvenliği:
- Tüm tablolarda `tenant_id text not null` bulunmalı.
- Her projection kaydı tenant bazlı izole olmalı.
- Arama tabloları tenant + entity + search key bazlı indexlenmeli.
- Search projection transactional tabloyu değiştirmez.
- Apply sonraki controlled apply gate olmadan çalıştırılmaz.

Kapanış hedefi:
SEARCH_INDEX_PROJECTION_TABLES=PASS
SEARCH_INDEX_MIGRATION_PAIR=PASS
SEARCH_INDEX_TABLE_COUNT=7
SEARCH_INDEX_TENANT_ID_COLUMN_COUNT=7
SEARCH_INDEX_ENTITY_ID_COLUMN_COUNT>=6
SEARCH_INDEX_SEARCH_TEXT_COLUMN_COUNT>=6
SEARCH_INDEX_INDEX_COUNT>=14
DB_MUTATION=NO
DB_APPLY_EXECUTED=NO
MIGRATION_CREATED=YES
MIGRATION_APPLY_EXECUTED=NO
QUERY_TEXT_PRINTED=NO
FAZ4B_15_5_FINAL_STATUS=PASS
