# 224 — FAZ 4-16.6.4 Ürün Karar Defteri

## Amaç

Controlled pilot sırasında feedback, değişiklik sınıflandırma ve hızlı düzeltme hattından çıkan ürün karar adaylarını tek ürün karar defterinde kayıt altına alır.

Bu adım 223 Hızlı Düzeltme Hattı PASS olduktan sonra ürün kararlarının owner, karar tipi, etki alanı, öncelik, kapsam, kabul/ret/defer kararı, kanıt bağlantısı ve closure durumuyla izlenmesini sağlar.

## Kapsam

- Product decision intake
- Decision type taxonomy
- Decision owner assignment
- Impact area mapping
- Priority mapping
- Scope boundary mapping
- Accepted decision marker
- Rejected decision marker
- Deferred decision marker
- Quick fix link
- Feedback link
- Evidence attachment
- Approval record
- Decision history
- Closure checklist
- Closed provider policy guard

## Ana Kural

Bu adım ürün kararını otomatik uygulamaz.

Bu adım hotfix deploy yapmaz.

Bu adım gerçek roadmap tool, gerçek CRM veya gerçek ticket sistemi açmaz.

Bu adım production launch kararı vermez.

Bu adım canlı dış provider, GIB, banka, POS veya ödeme sağlayıcı aktivasyonu yapmaz.

Policy:

CLOSED_POLICY_GATE_REFERENCE_ONLY

## Kabul Kuralı

Ürün karar defteri PASS sayılırsa:

- decision_log_status = READY olmalıdır.
- decision_log_mode = CONTROLLED_PILOT olmalıdır.
- required decision rule'ların tamamı READY olmalıdır.
- required evidence_ref alanları dolu olmalıdır.
- total_rule_count gerçek rule sayısıyla eşleşmelidir.
- ready_rule_count gerçek READY sayısıyla eşleşmelidir.
- missing_rule_count = 0 olmalıdır.
- required_fail_count = 0 olmalıdır.
- critical_issue_count = 0 olmalıdır.
- open_blocker_count = 0 olmalıdır.
- quick_fix_lane_status = PASS olmalıdır.
- decision_type_taxonomy_status = READY olmalıdır.
- owner_assignment_status = READY olmalıdır.
- impact_area_mapping_status = READY olmalıdır.
- approval_record_status = READY olmalıdır.
- closure_checklist_status = READY olmalıdır.
- no_auto_apply_decision = true olmalıdır.
- no_hotfix_deploy = true olmalıdır.
- no_real_roadmap_tool = true olmalıdır.
- no_real_crm_system = true olmalıdır.
- no_real_ticket_system = true olmalıdır.
- live_external_policy_status = CLOSED olmalıdır.

## Çıkış Kriterleri

Bu adım PASS sayılırsa:

- Ürün karar defteri dokümanı vardır.
- Master config artifact vardır.
- Product decision log artifact vardır.
- Decision rule kanıt dokümanları vardır.
- Runtime validation script vardır ve executable durumdadır.
- Test fixture vardır.
- Audit script vardır.
- Valid product decision fixture PASS döner.
- Invalid product decision fixture FAIL döner.
- Required rule guard doğrulanır.
- Evidence guard doğrulanır.
- Counter reconciliation guard doğrulanır.
- Owner/impact/approval/closure guard doğrulanır.
- No auto apply / no hotfix / no real tool guard doğrulanır.
- Closed policy marker doğrulanır.
- Final status gerçek test/audit sayaçlarından türetilir.
