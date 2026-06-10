# FAZ 4B / 19.3 - Admin Dashboard Cards

Amaç:
Pilot admin paneli için ana dashboard kartlarını standartlaştırmak.

Bu adım:
- DB apply yapmaz.
- DB mutate etmez.
- Migration oluşturmaz.
- Panel build/deploy çalıştırmaz.
- Route deploy etmez.
- Servis restart etmez.
- PostgreSQL config değiştirmez.
- Container restart etmez.
- Raw DSN, password, token veya query text rapora basmaz.

Ön koşul:
- 19.1 Runtime flow history PASS olmalı.
- 19.2 Flow detail page PASS olmalı.

Dashboard route:
- `/admin/dashboard`

API contract önerisi:
- `GET /api/v1/admin/dashboard/summary`
- `GET /api/v1/admin/dashboard/cards`
- `GET /api/v1/admin/dashboard/runtime-flows`
- `GET /api/v1/admin/dashboard/imports`
- `GET /api/v1/admin/dashboard/inventory`
- `GET /api/v1/admin/dashboard/security`
- `GET /api/v1/admin/dashboard/activity`

Dashboard kart hedefleri:
- Pilot yöneticisi sisteme girince ne çalışıyor, ne hatalı, nerede aksiyon lazım görebilmeli.
- Runtime flow, import, stok, güvenlik, reporting ve son aktiviteler tek yüzeyde özetlenmeli.
- Her kart flow detail, import wizard, issue feedback veya security gate gibi sonraki sayfalara drilldown hazırlığı taşımalı.

Tenant güvenliği:
- Her dashboard response tenant scope ile dönmeli.
- Tüm kartlar tenant_required=YES olmalı.
- Super-admin görünümü ileride RBAC/audit gate ile sınırlandırılmalı.
- Query text, token, raw DSN ve password dashboard contract veya rapora basılmamalı.

Kapanış hedefi:
ADMIN_DASHBOARD_CARDS=PASS
ADMIN_DASHBOARD_CARDS_CONTRACT=PASS
ADMIN_DASHBOARD_CARD_MANIFEST=PASS
ADMIN_DASHBOARD_METRIC_MANIFEST=PASS
ADMIN_DASHBOARD_PREVIOUS_19_2=PASS
ADMIN_DASHBOARD_TENANT_SAFETY=PASS
ADMIN_DASHBOARD_NO_APPLY=PASS
ADMIN_DASHBOARD_SECRET_SAFETY=PASS
FAZ4B_19_3_FINAL_STATUS=PASS
