# FAZ 4B / 21.2 - Permission Guard

Amaç:
21.1 Role matrix üzerinde pilot öncesi permission guard standardını kurmak.

Bu adım:
- DB apply yapmaz.
- DB mutate etmez.
- Migration oluşturmaz.
- Gerçek permission guard çalıştırmaz.
- Gerçek middleware enforce etmez.
- Gerçek RBAC deny/allow kararı üretmez.
- Gerçek audit log yazmaz.
- Panel/API route deploy etmez.
- Servis restart etmez.
- PostgreSQL config değiştirmez.
- Container restart etmez.
- Raw DSN, password, token veya query text rapora basmaz.

Ön koşul:
- 21.1 Role matrix PASS olmalı.
- 19 Panel/Admin final closure PASS olmalı.

Permission guard ne yapacak?
- JWT içinden tenant context ve user context alacak.
- Request içindeki tenant context ile JWT tenant bilgisini karşılaştıracak.
- Kullanıcının role_code değerini role matrix ile eşleştirecek.
- İstenen permission_code / resource_area / action_code kararını kontrol edecek.
- Scope kuralını kontrol edecek.
- Support ve super-admin boundary kurallarını uygulamaya hazır hale getirecek.
- Karar çıktısı olarak ALLOW veya DENY reason üretecek.
- Audit event model 21.3'te kurulacağı için bu adım audit yazmaz; sadece audit-ready contract üretir.

Guard kapsama alanları:
- Panel route guard
- API route guard
- Import action guard
- Inventory action guard
- Reporting access guard
- UAT action guard
- Issue / feedback guard
- Security admin guard
- Support boundary guard
- Super-admin boundary guard

Tenant güvenliği:
- Tenant context yoksa DENY.
- JWT tenant ile request tenant uyuşmazsa DENY.
- Role yoksa DENY.
- Permission yoksa DENY.
- Scope mismatch varsa DENY.
- Cross-tenant erişim varsayılan DENY.
- Support erişimi audit-ready boundary olmadan DENY.
- Super-admin erişimi boundary kontrolü olmadan DENY.

Kapanış hedefi:
PERMISSION_GUARD=PASS
PERMISSION_GUARD_CONTRACT=PASS
PERMISSION_GUARD_MIDDLEWARE_MANIFEST=PASS
PERMISSION_GUARD_DECISION_MANIFEST=PASS
PERMISSION_GUARD_SURFACE_MANIFEST=PASS
PERMISSION_GUARD_PREVIOUS_21_1=PASS
PERMISSION_GUARD_TENANT_SAFETY=PASS
PERMISSION_GUARD_BOUNDARY_STATUS=PASS
PERMISSION_GUARD_AUDIT_READY=PASS
PERMISSION_GUARD_NO_APPLY=PASS
PERMISSION_GUARD_SECRET_SAFETY=PASS
FAZ4B_21_2_FINAL_STATUS=PASS

## 21.2R Notu - Surface manifest standard fix

21.2 test gate, permission guard surface ID'lerini standard dokümanda birebir arar.

Bu nedenle aşağıdaki guard surface ID'leri standard dokümana açıkça eklendi:

- panel_route_guard
- api_route_guard
- import_action_guard
- inventory_action_guard
- reporting_access_guard
- uat_action_guard
- issue_feedback_guard
- security_admin_guard
- support_boundary_guard
- super_admin_boundary_guard

Surface açıklamaları:

- `panel_route_guard`: Admin panel route erişimini role/permission/scope kararına bağlar.
- `api_route_guard`: API route erişimini permission guard kararına bağlar.
- `import_action_guard`: Import upload, mapping, validation ve commit-plan aksiyonlarını korur.
- `inventory_action_guard`: Stok hareketi, rezervasyon, negative stock ve valuation aksiyonlarını korur.
- `reporting_access_guard`: Readmodel/reporting ve raporlama erişimlerini tenant-safe kontrol eder.
- `uat_action_guard`: UAT checklist status, evidence ve readiness işlemlerini korur.
- `issue_feedback_guard`: Issue/feedback create, comment, evidence ve status işlemlerini korur.
- `security_admin_guard`: Security/RBAC/Audit yönetim yüzeylerini korur.
- `support_boundary_guard`: Support erişimini tenant boundary ve audit-ready kurallara bağlar.
- `super_admin_boundary_guard`: Super-admin erişimini boundary ve audit-ready kurallara bağlar.

Bu fix:
- DB mutate etmez.
- DB apply yapmaz.
- Permission guard çalıştırmaz.
- RBAC enforce etmez.
- Audit log yazmaz.
- Sadece contract/standard evidence düzeltir.
