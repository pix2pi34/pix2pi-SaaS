# FAZ 4B / 19.1 - Runtime Flow History

Amaç:
Admin panelde pilot operasyonları için runtime akış geçmişini izlenebilir hale getirecek tenant-safe altyapıyı kurmak.

Bu adım:
- Migration pair oluşturur.
- DB apply yapmaz.
- DB mutate etmez.
- SQL çalıştırmaz.
- Panel runtime geçmişi üretmez.
- Servis restart etmez.
- PostgreSQL config değiştirmez.
- Container restart etmez.
- Raw DSN, password, token veya query text rapora basmaz.

Oluşturulacak schema:
- `panel_admin`

Oluşturulacak tablolar:
1. `panel_admin.runtime_flow_runs`
2. `panel_admin.runtime_flow_steps`
3. `panel_admin.runtime_flow_events`
4. `panel_admin.runtime_flow_snapshots`
5. `panel_admin.runtime_flow_error_links`
6. `panel_admin.runtime_flow_timeline_views`

Runtime flow history neyi gösterir?
- Hangi tenantta hangi akış başladı?
- Hangi servis / route / job / event üzerinden ilerledi?
- Hangi step başarılı oldu, hangisi hata aldı?
- Hata varsa request_id, correlation_id, source_event_id ile iz sürülebilir mi?
- Panelde flow detail sayfası için timeline verisi üretilebilir mi?

Tenant güvenliği:
- Tüm tablolarda `tenant_id text not null` bulunmalı.
- Flow run, step, event, snapshot ve error link kayıtları tenant bazlı izole olmalı.
- Cross-tenant runtime history gösterimi yasaktır.
- Super-admin görüntülemesi ileride RBAC/audit gate ile sınırlandırılır.

Kapanış hedefi:
RUNTIME_FLOW_HISTORY=PASS
RUNTIME_FLOW_HISTORY_MIGRATION_PAIR=PASS
RUNTIME_FLOW_HISTORY_TABLE_COUNT=6
RUNTIME_FLOW_HISTORY_TENANT_ID_COLUMN_COUNT=6
RUNTIME_FLOW_HISTORY_INDEX_COUNT>=12
DB_MUTATION=NO
DB_APPLY_EXECUTED=NO
MIGRATION_CREATED=YES
MIGRATION_APPLY_EXECUTED=NO
PANEL_RUNTIME_HISTORY_EXECUTED=NO
QUERY_TEXT_PRINTED=NO
FAZ4B_19_1_FINAL_STATUS=PASS

## 19.1R Notu - Unique constraint fix

19.1 test gate, runtime flow history migration dosyasında en az 8 unique constraint bekler.

İlk koşuda unique constraint sayısı 7 geldi. Bu nedenle `runtime_flow_timeline_views` tablosuna ayrıca şu unique constraint eklendi:

- `UNIQUE (tenant_id, runtime_flow_run_id, display_group, timeline_order)`

Amaç:
- Panel timeline projection tarafında aynı tenant + aynı flow + aynı display group + aynı sıra tekrarını engellemek
- Runtime flow detail sayfasında tekrar eden timeline kayıtlarını önlemek
- Panel görüntüleme tutarlılığını güçlendirmek
