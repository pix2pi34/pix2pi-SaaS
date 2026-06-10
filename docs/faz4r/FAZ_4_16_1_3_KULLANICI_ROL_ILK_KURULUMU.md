# 197 — FAZ 4-16.1.3 Kullanıcı / Rol İlk Kurulumu

## Amaç

Pilot tenant için ilk kullanıcı, rol ve yetki baseline kurulumunu standartlaştırır.

Bu adım 196 — Tenant config şablonları PASS olduktan sonra gelir.

## Kapsam

Kullanıcı / rol ilk kurulumu aşağıdaki alanları kapsar:

- Tenant admin kullanıcısı
- Operator kullanıcısı
- Accountant kullanıcısı
- Support observer kullanıcısı
- Role baseline
- Permission baseline
- Role assignment
- Invite policy
- MFA policy
- Audit evidence
- Tenant isolation guard
- Critical issue zero guard
- Canlı dış provider/GIB/banka/POS kapalı policy gate

## Ana Kural

Bu adım gerçek kullanıcıya e-posta göndermez, canlı dış servis çağırmaz, canlı provider/GIB/banka/POS aktivasyonu yapmaz.

Policy:

CLOSED_POLICY_GATE_REFERENCE_ONLY

## Role Baseline

Kontrollü pilot için minimum roller:

- TENANT_ADMIN
- PILOT_OPERATOR
- ACCOUNTANT
- SUPPORT_OBSERVER

## Zorunlu Permission Grupları

- TENANT_READ
- TENANT_CONFIG_READ
- USER_INVITE_MANAGE
- ROLE_ASSIGN_MANAGE
- IMPORT_DRY_RUN_RUN
- IMPORT_REPORT_READ
- UAT_CASE_READ
- UAT_CASE_UPDATE
- REPORTING_READ
- OPERATIONAL_READMODEL_READ
- SUPPORT_ISSUE_READ
- SUPPORT_ISSUE_UPDATE
- AUDIT_EVIDENCE_READ

## Kabul Kuralı

User / role initial setup PASS sayılırsa:

- setup_status = READY olmalıdır.
- tenant_scope = SINGLE_TENANT olmalıdır.
- pilot_mode = CONTROLLED_PILOT olmalıdır.
- Tenant admin en az 1 olmalıdır.
- Her required role tanımlı olmalıdır.
- Her required permission tanımlı olmalıdır.
- Tenant admin kullanıcısında TENANT_ADMIN rolü olmalıdır.
- Rollerin permission assignment kayıtları dolu olmalıdır.
- Invite policy READY olmalıdır.
- MFA policy READY veya ENFORCED olmalıdır.
- Critical issue count 0 olmalıdır.
- Live external policy CLOSED olmalıdır.

## Çıkış Kriterleri

Bu adım PASS sayılırsa:

- Kullanıcı / rol ilk kurulum dokümanı vardır.
- Master config artifact vardır.
- User-role setup template artifact vardır.
- Runtime validation script vardır ve executable durumdadır.
- Test fixture vardır.
- Audit script vardır.
- Valid fixture PASS döner.
- Invalid fixture FAIL döner.
- Role / permission / assignment guard doğrulanır.
- Closed policy marker doğrulanır.
- Final status gerçek test/audit sayaçlarından türetilir.
