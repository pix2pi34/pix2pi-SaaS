# FAZ 4B / 19.5 - UAT Checklist UI

Amaç:
Pilot öncesi kullanıcı kabul testi sürecini admin panelde yönetilebilir hale getirecek UAT checklist UI standardını kurmak.

Bu adım:
- DB apply yapmaz.
- DB mutate etmez.
- Migration oluşturmaz.
- Gerçek UAT kaydı oluşturmaz.
- Evidence upload çalıştırmaz.
- Go-live onayı vermez.
- Panel build/deploy çalıştırmaz.
- Route deploy etmez.
- Servis restart etmez.
- PostgreSQL config değiştirmez.
- Container restart etmez.
- Raw DSN, password, token veya query text rapora basmaz.

Ön koşul:
- 19.4 Import wizard UI PASS olmalı.
- 18 Inventory Pilot Motoru PASS olmalı.
- 14 Migration / lifecycle / import PASS olmalı.

UAT route:
- `/admin/uat/checklist`

UAT checklist hedefleri:
- Pilot senaryolarını görünür yapmak
- Her senaryo için PASS / FAIL / BLOCKED / NOT_STARTED durumunu izlemek
- Evidence linki, sorumlu kişi, açıklama ve blocker bilgisi tutmak
- Go-live readiness yüzdesini göstermek
- Blocking item varsa go-live gate'i kapalı tutmak
- Runtime flow ve issue/feedback sayfalarına bağlantı hazırlamak

Tenant güvenliği:
- Her UAT checklist tenant scope ile çalışır.
- Her UAT scenario tenant context içinde değerlendirilir.
- Her UAT evidence sadece ilgili tenant kaydına bağlanır.
- UAT owner / reviewer tenant sınırını aşamaz.
- Cross-tenant checklist görüntüleme yasaktır.
- Cross-tenant evidence link yasaktır.
- Super-admin görüntüleme ileride RBAC/audit gate ile sınırlandırılır.
- Query text, token, raw DSN ve password UAT contract veya rapora basılmaz.

Kapanış hedefi:
UAT_CHECKLIST_UI=PASS
UAT_CHECKLIST_CONTRACT=PASS
UAT_CHECKLIST_ROUTE_MANIFEST=PASS
UAT_CHECKLIST_SCENARIO_MANIFEST=PASS
UAT_CHECKLIST_COMPONENT_MANIFEST=PASS
UAT_CHECKLIST_PREVIOUS_19_4=PASS
UAT_CHECKLIST_TENANT_SAFETY=PASS
UAT_CHECKLIST_NO_APPLY=PASS
UAT_CHECKLIST_SECRET_SAFETY=PASS
FAZ4B_19_5_FINAL_STATUS=PASS
