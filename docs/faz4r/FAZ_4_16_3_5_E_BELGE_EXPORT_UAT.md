# 208 — FAZ 4-16.3.5 e-Belge / Export UAT

## Amaç

Pilot tenant için e-Belge ve export UAT kapsamını controlled pilot seviyesinde standartlaştırır.

Bu adım Muhasebeci Portalı UAT PASS olduktan sonra e-Fatura, e-Arşiv, e-Adisyon/export preview, XML/PDF preview ve muhasebe paket export preview akışlarının pilot kabul testlerine hazır olduğunu doğrular.

## Kapsam

e-Belge / export UAT aşağıdaki alanları kapsar:

- e-Belge / export ekran erişimi
- Tenant context görünürlüğü
- e-Fatura preview
- e-Arşiv preview
- e-Adisyon / belge preview
- XML preview
- PDF preview
- Logo export preview
- Mikro export preview
- Zirve export preview
- ETA export preview
- Export validation raporu
- Muhasebe UAT bağlantısı
- Muhasebeci portalı export linki
- Audit evidence bağlantısı
- GIB canlı gönderim kapalı gate
- Gerçek export kapalı gate
- Kritik hata sayısı 0
- Canlı dış provider/GIB/banka/POS kapalı policy gate

## Ana Kural

Bu adım gerçek GIB gönderimi yapmaz.

Bu adım gerçek e-Fatura, e-Arşiv, e-Adisyon, banka, ödeme sağlayıcı, POS provider veya dış provider aktivasyonu yapmaz.

Bu adım gerçek dosya gönderimi/export teslimi yapmaz; sadece preview ve UAT kabul standardını kurar.

Policy:

CLOSED_POLICY_GATE_REFERENCE_ONLY

## Kabul Kuralı

e-Belge / export UAT PASS sayılırsa:

- uat_status = READY olmalıdır.
- uat_mode = CONTROLLED_PILOT olmalıdır.
- export_mode = PREVIEW olmalıdır.
- required UAT case'lerin tamamı PASS olmalıdır.
- required evidence_ref alanları dolu olmalıdır.
- total_case_count gerçek case sayısıyla eşleşmelidir.
- pass_count gerçek PASS sayısıyla eşleşmelidir.
- fail_count gerçek FAIL sayısıyla eşleşmelidir.
- required_fail_count = 0 olmalıdır.
- critical_issue_count = 0 olmalıdır.
- tenant_context_status = PASS olmalıdır.
- document_preview_status = PASS olmalıdır.
- xml_preview_status = PASS olmalıdır.
- pdf_preview_status = PASS olmalıdır.
- package_export_preview_status = PASS olmalıdır.
- gib_live_status = CLOSED olmalıdır.
- real_export_status = CLOSED olmalıdır.
- live_external_policy_status = CLOSED olmalıdır.

## Çıkış Kriterleri

Bu adım PASS sayılırsa:

- e-Belge / export UAT dokümanı vardır.
- Master config artifact vardır.
- e-Belge / export UAT case artifact vardır.
- Runtime validation script vardır ve executable durumdadır.
- Test fixture vardır.
- Audit script vardır.
- Valid UAT fixture PASS döner.
- Invalid UAT fixture FAIL döner.
- Required evidence guard doğrulanır.
- Counter reconciliation guard doğrulanır.
- Critical issue zero guard doğrulanır.
- GIB live closed guard doğrulanır.
- Real export closed guard doğrulanır.
- XML/PDF preview guard doğrulanır.
- Package export preview guard doğrulanır.
- Closed policy marker doğrulanır.
- Final status gerçek test/audit sayaçlarından türetilir.
