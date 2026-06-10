# 206 — FAZ 4-16.3.3 Muhasebe UAT

## Amaç

Pilot tenant için muhasebe UAT kapsamını controlled pilot seviyesinde standartlaştırır.

Bu adım POS UAT PASS olduktan sonra ERP muhasebe yüzeyi, TDHP ön muhasebe akışı, fiş/hareket muhasebe önizleme ve rapor bağlantılarının pilot kabul testlerine hazır olduğunu doğrular.

## Kapsam

Muhasebe UAT aşağıdaki alanları kapsar:

- Muhasebe ekran erişimi
- Tenant context görünürlüğü
- TDHP hesap planı görünümü
- Cari hareket muhasebe görünümü
- Satış fişi muhasebe preview
- Alış fişi muhasebe preview
- KDV özet görünümü
- Yevmiye taslak preview
- Borç / alacak denge kontrolü
- Finance reporting mart bağlantısı
- Payment / reconciliation mart bağlantısı
- Import validation evidence bağlantısı
- POS UAT dry-run satış evidence bağlantısı
- Audit evidence bağlantısı
- Kritik hata sayısı 0
- Canlı dış provider/GIB/banka/POS kapalı policy gate

## Ana Kural

Bu adım gerçek yevmiye defteri kaydı oluşturmaz.

Bu adım gerçek e-Belge/GIB gönderimi, banka mutabakatı, ödeme sağlayıcı, POS provider veya dış provider aktivasyonu yapmaz.

Bu adım sadece controlled pilot muhasebe UAT kabul standardını kurar.

Policy:

CLOSED_POLICY_GATE_REFERENCE_ONLY

## Kabul Kuralı

Muhasebe UAT PASS sayılırsa:

- uat_status = READY olmalıdır.
- uat_mode = CONTROLLED_PILOT olmalıdır.
- accounting_mode = PREVIEW olmalıdır.
- required UAT case'lerin tamamı PASS olmalıdır.
- required evidence_ref alanları dolu olmalıdır.
- total_case_count gerçek case sayısıyla eşleşmelidir.
- pass_count gerçek PASS sayısıyla eşleşmelidir.
- fail_count gerçek FAIL sayısıyla eşleşmelidir.
- required_fail_count = 0 olmalıdır.
- critical_issue_count = 0 olmalıdır.
- tenant_context_status = PASS olmalıdır.
- journal_preview_status = PASS olmalıdır.
- debit_credit_balance_status = PASS olmalıdır.
- tax_summary_status = PASS olmalıdır.
- real_ledger_posting_status = CLOSED olmalıdır.
- live_external_policy_status = CLOSED olmalıdır.

## Çıkış Kriterleri

Bu adım PASS sayılırsa:

- Muhasebe UAT dokümanı vardır.
- Master config artifact vardır.
- Muhasebe UAT case artifact vardır.
- Runtime validation script vardır ve executable durumdadır.
- Test fixture vardır.
- Audit script vardır.
- Valid UAT fixture PASS döner.
- Invalid UAT fixture FAIL döner.
- Required evidence guard doğrulanır.
- Counter reconciliation guard doğrulanır.
- Critical issue zero guard doğrulanır.
- Real ledger posting closed guard doğrulanır.
- Debit / credit balance guard doğrulanır.
- Closed policy marker doğrulanır.
- Final status gerçek test/audit sayaçlarından türetilir.
