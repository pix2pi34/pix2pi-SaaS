# 207 — FAZ 4-16.3.4 Muhasebeci Portalı UAT

## Amaç

Pilot tenant için muhasebeci portalı UAT kapsamını controlled pilot seviyesinde standartlaştırır.

Bu adım Muhasebe UAT PASS olduktan sonra muhasebeci portalının çoklu firma görünümü, tenant atama sınırı, finans/muhasebe rapor okuma ve export preview akışlarının pilot kabul testlerine hazır olduğunu doğrular.

## Kapsam

Muhasebeci portalı UAT aşağıdaki alanları kapsar:

- Muhasebeci portal erişimi
- Accountant user context görünürlüğü
- Atanmış tenant listesi
- Tek tenant okuma
- Cross-tenant erişim engeli
- Finance reporting mart görünümü
- Cari hareket görünümü
- TDHP / yevmiye preview görünümü
- KDV / vergi summary görünümü
- Payment reconciliation görünümü
- e-Belge / export preview bağlantısı
- Dosya export preview
- Read-only guard
- Audit evidence bağlantısı
- Kritik hata sayısı 0
- Canlı dış provider/GIB/banka/POS kapalı policy gate

## Ana Kural

Bu adım gerçek muhasebeci müşteri aktivasyonu yapmaz.

Bu adım gerçek export, gerçek GIB/e-Belge gönderimi, banka mutabakatı, ödeme sağlayıcı, POS provider veya dış provider aktivasyonu yapmaz.

Bu adım sadece controlled pilot muhasebeci portalı UAT kabul standardını kurar.

Policy:

CLOSED_POLICY_GATE_REFERENCE_ONLY

## Kabul Kuralı

Muhasebeci portalı UAT PASS sayılırsa:

- uat_status = READY olmalıdır.
- uat_mode = CONTROLLED_PILOT olmalıdır.
- portal_mode = READ_ONLY_PREVIEW olmalıdır.
- required UAT case'lerin tamamı PASS olmalıdır.
- required evidence_ref alanları dolu olmalıdır.
- total_case_count gerçek case sayısıyla eşleşmelidir.
- pass_count gerçek PASS sayısıyla eşleşmelidir.
- fail_count gerçek FAIL sayısıyla eşleşmelidir.
- required_fail_count = 0 olmalıdır.
- critical_issue_count = 0 olmalıdır.
- accountant_context_status = PASS olmalıdır.
- assigned_tenant_scope_status = PASS olmalıdır.
- cross_tenant_guard_status = PASS olmalıdır.
- read_only_guard_status = PASS olmalıdır.
- export_preview_status = PASS olmalıdır.
- real_export_status = CLOSED olmalıdır.
- live_external_policy_status = CLOSED olmalıdır.

## Çıkış Kriterleri

Bu adım PASS sayılırsa:

- Muhasebeci portalı UAT dokümanı vardır.
- Master config artifact vardır.
- Muhasebeci portalı UAT case artifact vardır.
- Runtime validation script vardır ve executable durumdadır.
- Test fixture vardır.
- Audit script vardır.
- Valid UAT fixture PASS döner.
- Invalid UAT fixture FAIL döner.
- Required evidence guard doğrulanır.
- Counter reconciliation guard doğrulanır.
- Critical issue zero guard doğrulanır.
- Cross-tenant guard doğrulanır.
- Read-only guard doğrulanır.
- Real export closed guard doğrulanır.
- Closed policy marker doğrulanır.
- Final status gerçek test/audit sayaçlarından türetilir.
