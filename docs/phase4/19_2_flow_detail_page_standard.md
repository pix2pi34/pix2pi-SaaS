# FAZ 4B / 19.2 - Flow Detail Page

Amaç:
Admin panelde bir runtime flow kaydının detay sayfasını standartlaştırmak.

Bu adım:
- DB apply yapmaz.
- DB mutate etmez.
- Migration oluşturmaz.
- Route deploy etmez.
- Panel build/deploy çalıştırmaz.
- Servis restart etmez.
- PostgreSQL config değiştirmez.
- Container restart etmez.
- Raw DSN, password, token veya query text rapora basmaz.

Ön koşul:
- 19.1 Runtime flow history PASS olmalı.

Flow detail page amacı:
- Tek bir `runtime_flow_run_id` üzerinden akışın genel özetini göstermek
- Step timeline göstermek
- Event history göstermek
- Error links göstermek
- Snapshot/progress göstermek
- Request/correlation/source_event izlerini göstermek
- Tenant güvenliği ve RBAC hazırlığını korumak

Panel route:
- `/admin/runtime-flows/:flow_run_id`

API contract önerisi:
- `GET /api/v1/admin/runtime-flows/:flow_run_id`
- `GET /api/v1/admin/runtime-flows/:flow_run_id/steps`
- `GET /api/v1/admin/runtime-flows/:flow_run_id/events`
- `GET /api/v1/admin/runtime-flows/:flow_run_id/timeline`
- `GET /api/v1/admin/runtime-flows/:flow_run_id/errors`
- `GET /api/v1/admin/runtime-flows/:flow_run_id/snapshots`

Tenant güvenliği:
- Her request JWT tenant context ile çalışmalı.
- Her response tenant scope içinden dönmeli.
- `X-Tenant-ID` ve JWT tenant uyuşmazlığı ileride security/RBAC gate ile bloklanmalı.
- Super-admin görüntüleme ayrı audit/RBAC gate olmadan serbest bırakılmamalı.
- Query text, token, raw DSN, password response veya rapora basılmamalı.

Kapanış hedefi:
FLOW_DETAIL_PAGE=PASS
FLOW_DETAIL_PAGE_CONTRACT=PASS
FLOW_DETAIL_PAGE_ROUTE_MANIFEST=PASS
FLOW_DETAIL_PAGE_COMPONENT_MANIFEST=PASS
FLOW_DETAIL_PAGE_PREVIOUS_19_1=PASS
FLOW_DETAIL_PAGE_TENANT_SAFETY=PASS
FLOW_DETAIL_PAGE_NO_APPLY=PASS
FLOW_DETAIL_PAGE_SECRET_SAFETY=PASS
FAZ4B_19_2_FINAL_STATUS=PASS
