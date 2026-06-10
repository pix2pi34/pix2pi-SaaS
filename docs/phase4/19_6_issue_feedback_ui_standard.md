# FAZ 4B / 19.6 - Issue / Feedback UI

Amaç:
Pilot kullanıcıların hata, öneri, veri problemi, UAT blocker ve operasyonel geri bildirimlerini admin panelden kontrollü şekilde bildirebilmesi için Issue / Feedback UI standardını kurmak.

Bu adım:
- DB apply yapmaz.
- DB mutate etmez.
- Migration oluşturmaz.
- Gerçek issue oluşturmaz.
- Gerçek feedback kaydı oluşturmaz.
- Evidence upload çalıştırmaz.
- Status update çalıştırmaz.
- Panel build/deploy çalıştırmaz.
- Route deploy etmez.
- Servis restart etmez.
- PostgreSQL config değiştirmez.
- Container restart etmez.
- Raw DSN, password, token veya query text rapora basmaz.

Ön koşul:
- 19.5 UAT checklist UI PASS olmalı.
- 19.1 Runtime flow history PASS olmalı.
- 18 Inventory Pilot Motoru PASS olmalı.

Panel route:
- `/admin/issues-feedback`

Amaçlanan akış:
1. Kullanıcı issue veya feedback tipini seçer.
2. Severity / priority belirlenir.
3. İlgili runtime flow, UAT checklist, import batch veya inventory context linklenir.
4. Evidence link / ekran görüntüsü placeholder olarak contract seviyesinde tanımlanır.
5. Tenant-safe issue payload hazırlanır.
6. Support / admin / product owner tarafına yönlendirme contract seviyesinde tanımlanır.
7. Status lifecycle izlenebilir hale gelir.

Tenant güvenliği:
- Her issue tenant scope ile çalışır.
- Her feedback tenant scope ile çalışır.
- Runtime flow link tenant uyumlu olmalıdır.
- UAT checklist link tenant uyumlu olmalıdır.
- Import batch link tenant uyumlu olmalıdır.
- Evidence link tenant sınırını aşamaz.
- Cross-tenant issue görüntüleme yasaktır.
- Cross-tenant feedback görüntüleme yasaktır.
- Super-admin görüntüleme ileride RBAC/audit gate ile sınırlandırılır.
- Query text, token, raw DSN ve password issue/feedback contract veya rapora basılmaz.

Kapanış hedefi:
ISSUE_FEEDBACK_UI=PASS
ISSUE_FEEDBACK_CONTRACT=PASS
ISSUE_FEEDBACK_ROUTE_MANIFEST=PASS
ISSUE_FEEDBACK_TYPE_MANIFEST=PASS
ISSUE_FEEDBACK_COMPONENT_MANIFEST=PASS
ISSUE_FEEDBACK_PREVIOUS_19_5=PASS
ISSUE_FEEDBACK_TENANT_SAFETY=PASS
ISSUE_FEEDBACK_LINKAGE_STATUS=PASS
ISSUE_FEEDBACK_NO_APPLY=PASS
ISSUE_FEEDBACK_SECRET_SAFETY=PASS
FAZ4B_19_6_FINAL_STATUS=PASS
