# 204 — FAZ 4-16.3.1 Yönetim Paneli UAT

## Amaç

Pilot tenant için yönetim paneli UAT kapsamını standartlaştırır.

Bu adım import zinciri 198–203 PASS olduktan sonra yönetim paneli üzerinden pilot kabul testlerinin yapılabilir olduğunu doğrular.

## Kapsam

Yönetim paneli UAT aşağıdaki alanları kapsar:

- Panel erişim / oturum açma kontrolü
- Tenant context görünürlüğü
- Tenant config görüntüleme
- Kullanıcı / rol yönetimi görüntüleme
- Import batch listesi
- Import validation raporu görüntüleme
- Cari import sonucu görüntüleme
- Ürün / stok import sonucu görüntüleme
- Fiş / hareket import sonucu görüntüleme
- Readmodel / reporting özetleri
- Operasyonel readmodel özetleri
- Support / issue bağlantısı
- Audit evidence bağlantısı
- Rollback / cutover guard görünürlüğü
- Kritik hata sayısı 0
- Canlı dış provider/GIB/banka/POS kapalı policy gate

## Ana Kural

Bu adım canlı dış provider, GIB, banka veya POS aktivasyonu yapmaz.

Bu adım gerçek kullanıcıya e-posta göndermez.

Bu adım panel UAT kabul standardını kurar.

Policy:

CLOSED_POLICY_GATE_REFERENCE_ONLY

## Kabul Kuralı

Yönetim paneli UAT PASS sayılırsa:

- uat_status = READY olmalıdır.
- uat_mode = CONTROLLED_PILOT olmalıdır.
- required UAT case'lerin tamamı PASS olmalıdır.
- required evidence_ref alanları dolu olmalıdır.
- total_case_count gerçek case sayısıyla eşleşmelidir.
- pass_count gerçek PASS sayısıyla eşleşmelidir.
- fail_count gerçek FAIL sayısıyla eşleşmelidir.
- required_fail_count = 0 olmalıdır.
- critical_issue_count = 0 olmalıdır.
- tenant_context_status = PASS olmalıdır.
- import_uat_status = PASS olmalıdır.
- reporting_uat_status = PASS olmalıdır.
- live_external_policy_status = CLOSED olmalıdır.

## Çıkış Kriterleri

Bu adım PASS sayılırsa:

- Yönetim paneli UAT dokümanı vardır.
- Master config artifact vardır.
- UAT case artifact vardır.
- Runtime validation script vardır ve executable durumdadır.
- Test fixture vardır.
- Audit script vardır.
- Valid UAT fixture PASS döner.
- Invalid UAT fixture FAIL döner.
- Required evidence guard doğrulanır.
- Counter reconciliation guard doğrulanır.
- Critical issue zero guard doğrulanır.
- Closed policy marker doğrulanır.
- Final status gerçek test/audit sayaçlarından türetilir.
