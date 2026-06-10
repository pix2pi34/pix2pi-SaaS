# 209 — FAZ 4-16.3.6 UAT Sign-off

## Amaç

FAZ 4-R UAT bloğunda tamamlanan yönetim paneli, POS, muhasebe, muhasebeci portalı ve e-Belge/export UAT sonuçlarını tek sign-off kapısında mühürler.

Bu adım UAT sonuçlarının pilot eğitim/destek bloğuna geçmeye hazır olduğunu doğrular.

## Kapsam

UAT sign-off aşağıdaki alanları kapsar:

- Yönetim paneli UAT sonucu
- POS UAT sonucu
- Muhasebe UAT sonucu
- Muhasebeci portalı UAT sonucu
- e-Belge / export UAT sonucu
- Pilot tenant scope doğrulaması
- UAT evidence referansları
- Required fail zero kontrolü
- Critical issue zero kontrolü
- Business owner sign-off preview
- Technical owner sign-off preview
- Product owner sign-off preview
- Support readiness handoff
- Eğitim / destek bloğuna geçiş kapısı
- Canlı dış provider/GIB/banka/POS kapalı policy gate

## Ana Kural

Bu adım gerçek canlıya geçiş onayı değildir.

Bu adım production public launch yapmaz.

Bu adım gerçek GIB, banka, POS, ödeme sağlayıcı veya dış provider aktivasyonu yapmaz.

Bu adım controlled pilot UAT sign-off standardını kurar.

Policy:

CLOSED_POLICY_GATE_REFERENCE_ONLY

## Kabul Kuralı

UAT sign-off PASS sayılırsa:

- signoff_status = READY olmalıdır.
- signoff_mode = CONTROLLED_PILOT olmalıdır.
- all_uat_status = PASS olmalıdır.
- required_fail_count = 0 olmalıdır.
- critical_issue_count = 0 olmalıdır.
- open_blocker_count = 0 olmalıdır.
- business_owner_signoff = READY olmalıdır.
- technical_owner_signoff = READY olmalıdır.
- product_owner_signoff = READY olmalıdır.
- required evidence_ref alanları dolu olmalıdır.
- total_uat_area_count gerçek UAT area sayısıyla eşleşmelidir.
- pass_uat_area_count gerçek PASS sayısıyla eşleşmelidir.
- fail_uat_area_count gerçek FAIL sayısıyla eşleşmelidir.
- support_handoff_ready = YES olmalıdır.
- next_phase_ready = FAZ_4_16_4_1_READY olmalıdır.
- live_external_policy_status = CLOSED olmalıdır.

## Çıkış Kriterleri

Bu adım PASS sayılırsa:

- UAT sign-off dokümanı vardır.
- Master config artifact vardır.
- Sign-off artifact vardır.
- Runtime validation script vardır ve executable durumdadır.
- Test fixture vardır.
- Audit script vardır.
- Valid sign-off fixture PASS döner.
- Invalid sign-off fixture FAIL döner.
- Evidence guard doğrulanır.
- Counter reconciliation guard doğrulanır.
- Required fail zero guard doğrulanır.
- Critical issue zero guard doğrulanır.
- Open blocker zero guard doğrulanır.
- Owner sign-off guard doğrulanır.
- Closed policy marker doğrulanır.
- Final status gerçek test/audit sayaçlarından türetilir.
