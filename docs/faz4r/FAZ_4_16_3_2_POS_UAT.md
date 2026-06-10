# 205 — FAZ 4-16.3.2 POS UAT

## Amaç

Pilot tenant için POS UAT kapsamını controlled pilot seviyesinde standartlaştırır.

Bu adım yönetim paneli UAT PASS olduktan sonra POS yüzeyinin pilot kabul testlerine hazır olduğunu doğrular.

## Kapsam

POS UAT aşağıdaki alanları kapsar:

- POS login / erişim kontrolü
- Tenant context görünürlüğü
- Kasiyer oturumu açılışı
- Ürün arama / barkod opsiyonel akışı
- Sepet operasyonları
- Satış dry-run
- İade dry-run
- Ödeme simülasyon / kapalı provider gate
- Stok hareket preview
- Offline queue preview
- Fiş preview
- Cari / ürün import referanslarının görünmesi
- Audit evidence bağlantısı
- Kritik hata sayısı 0
- Canlı dış provider/GIB/banka/POS kapalı policy gate

## Ana Kural

Bu adım canlı ödeme sağlayıcı, canlı POS provider, GIB, banka veya dış provider aktivasyonu yapmaz.

Bu adım gerçek satış / tahsilat / belge gönderimi yapmaz.

Policy:

CLOSED_POLICY_GATE_REFERENCE_ONLY

## Kabul Kuralı

POS UAT PASS sayılırsa:

- uat_status = READY olmalıdır.
- uat_mode = CONTROLLED_PILOT olmalıdır.
- pos_mode = DRY_RUN olmalıdır.
- required UAT case'lerin tamamı PASS olmalıdır.
- required evidence_ref alanları dolu olmalıdır.
- total_case_count gerçek case sayısıyla eşleşmelidir.
- pass_count gerçek PASS sayısıyla eşleşmelidir.
- fail_count gerçek FAIL sayısıyla eşleşmelidir.
- required_fail_count = 0 olmalıdır.
- critical_issue_count = 0 olmalıdır.
- tenant_context_status = PASS olmalıdır.
- cashier_session_status = PASS olmalıdır.
- sale_dry_run_status = PASS olmalıdır.
- payment_provider_status = CLOSED olmalıdır.
- live_external_policy_status = CLOSED olmalıdır.

## Çıkış Kriterleri

Bu adım PASS sayılırsa:

- POS UAT dokümanı vardır.
- Master config artifact vardır.
- POS UAT case artifact vardır.
- Runtime validation script vardır ve executable durumdadır.
- Test fixture vardır.
- Audit script vardır.
- Valid UAT fixture PASS döner.
- Invalid UAT fixture FAIL döner.
- Required evidence guard doğrulanır.
- Counter reconciliation guard doğrulanır.
- Critical issue zero guard doğrulanır.
- Payment provider closed guard doğrulanır.
- Closed policy marker doğrulanır.
- Final status gerçek test/audit sayaçlarından türetilir.
