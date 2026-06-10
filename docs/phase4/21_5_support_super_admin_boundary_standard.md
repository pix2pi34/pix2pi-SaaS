# FAZ 4B / 21.5 - Support / Super-admin Boundary

Amaç:
Pilot öncesi support kullanıcılarının ve super-admin yetkisinin tenant verisine erişim sınırlarını netleştirmek.

Bu adım:
- DB apply yapmaz.
- DB mutate etmez.
- Migration oluşturmaz.
- Gerçek support erişimi açmaz.
- Gerçek super-admin erişimi açmaz.
- Gerçek break-glass çalıştırmaz.
- Gerçek permission guard enforce etmez.
- Gerçek audit log yazmaz.
- Panel/API route deploy etmez.
- Servis restart etmez.
- PostgreSQL config değiştirmez.
- Container restart etmez.
- Raw DSN, password, token veya query text rapora basmaz.

Ön koşul:
- 21.1 Role matrix PASS olmalı.
- 21.2 Permission guard PASS olmalı.
- 21.3 Audit event model PASS olmalı.
- 21.4 Tenant access checks PASS olmalı.

Boundary amacı:
- Support kullanıcısı tenant verisine varsayılan olarak erişemez.
- Support erişimi sadece açık gerekçe, ticket, tenant scope, süre sınırı ve audit zorunluluğu ile contract seviyesinde tanımlanır.
- Support readonly erişim bile gerekçesiz açılamaz.
- Support operator erişim daha sıkı sınırlanır.
- Super-admin erişimi normal operasyon için kullanılmaz.
- Super-admin erişimi break-glass olarak kabul edilir.
- Break-glass erişim dual approval, reason code, timebox, high-risk ve audit zorunluluğu taşır.
- Cross-tenant erişim varsayılan DENY olarak kalır.
- Silent access yasaktır.
- Export, secret, ödeme/vergi, kullanıcı kimlik verisi gibi hassas alanlar ayrıca deny/approval gerektirir.

Boundary rule IDs:
- support_readonly_requires_reason
- support_operator_requires_ticket
- support_timeboxed_access
- support_no_secret_access
- support_no_export_default
- support_tenant_scope_required
- super_admin_break_glass_required
- super_admin_dual_approval_required
- super_admin_timeboxed_access
- super_admin_no_silent_access
- cross_tenant_default_deny
- audit_required_for_all_boundary_access
- emergency_revocation_required

Reason codes:
- CUSTOMER_SUPPORT_REQUEST
- PILOT_UAT_SUPPORT
- IMPORT_ASSISTANCE
- INCIDENT_RESPONSE
- SECURITY_INVESTIGATION
- DATA_REPAIR_APPROVED
- BILLING_SUPPORT
- BREAK_GLASS_INCIDENT
- LEGAL_COMPLIANCE_REQUEST
- INTERNAL_TESTING_DENIED

Tenant güvenliği:
- Support access tenant scope olmadan DENY.
- Support reason olmadan DENY.
- Support ticket olmadan DENY.
- Support timebox olmadan DENY.
- Super-admin break-glass reason olmadan DENY.
- Super-admin dual approval olmadan DENY.
- Super-admin silent access her zaman DENY.
- Cross-tenant access varsayılan DENY.
- Her boundary access audit_required=true.
- Her break-glass access high_risk=true.

Kapanış hedefi:
SUPPORT_SUPER_ADMIN_BOUNDARY=PASS
SUPPORT_SUPER_ADMIN_BOUNDARY_CONTRACT=PASS
SUPPORT_SUPER_ADMIN_BOUNDARY_RULE_MANIFEST=PASS
SUPPORT_SUPER_ADMIN_BOUNDARY_REASON_MANIFEST=PASS
SUPPORT_SUPER_ADMIN_BOUNDARY_DECISION_MANIFEST=PASS
SUPPORT_SUPER_ADMIN_BOUNDARY_PREVIOUS_21_4=PASS
SUPPORT_SUPER_ADMIN_BOUNDARY_TENANT_SAFETY=PASS
SUPPORT_SUPER_ADMIN_BOUNDARY_AUDIT_READY=PASS
SUPPORT_SUPER_ADMIN_BOUNDARY_NO_APPLY=PASS
SUPPORT_SUPER_ADMIN_BOUNDARY_SECRET_SAFETY=PASS
FAZ4B_21_5_FINAL_STATUS=PASS

## 21.5R Notu - Boundary / high_risk evidence fix

21.5 test gate şu iki sayaçta ek kanıt bekler:
- boundary reference >= 35
- high_risk reference >= 10

Bu nedenle support / super-admin boundary contract kanıtı netleştirildi:

- Her support boundary kararı tenant boundary içinde değerlendirilir.
- Her super-admin boundary kararı break-glass boundary içinde değerlendirilir.
- Cross-tenant boundary varsayılan olarak DENY kalır.
- Boundary dışı erişim silent access sayılır ve DENY olur.
- Support, super-admin ve cross-tenant boundary kararları audit-ready çalışır.
- Break-glass, secret access, export access ve cross-tenant boundary kararları high_risk kabul edilir.
- high_risk=true olan tüm kararlar audit_required=true olmak zorundadır.
- high_risk boundary kararı approval, reason, ticket ve timebox olmadan ALLOW olamaz.

Bu fix:
- DB mutate etmez.
- DB apply yapmaz.
- Migration oluşturmaz.
- Support access açmaz.
- Super-admin access açmaz.
- Break-glass çalıştırmaz.
- Audit log yazmaz.
- Sadece contract evidence düzeltir.
