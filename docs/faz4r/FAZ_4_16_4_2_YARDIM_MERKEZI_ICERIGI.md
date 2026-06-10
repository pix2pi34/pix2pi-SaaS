# 211 — FAZ 4-16.4.2 Yardım Merkezi İçeriği

## Amaç

Controlled pilot kullanıcıları için yardım merkezi içerik standardını kurar.

Bu adım 210 Kullanıcı Eğitim Seti PASS olduktan sonra kullanıcıların eğitim dokümanlarına ek olarak hızlı erişilebilir yardım merkezi içeriğine sahip olmasını sağlar.

## Kapsam

Yardım merkezi içeriği aşağıdaki kategorileri kapsar:

- İlk giriş ve hesap erişimi
- Firma / tenant bağlamı
- Yönetim paneli
- POS temel kullanım
- Cari import
- Ürün / stok import
- Fiş / hareket import
- Import validation raporu
- Muhasebe preview
- Muhasebeci portalı read-only akışı
- e-Belge / export preview
- Hata bildirimi / destek talebi
- Pilot sınırları
- Canlı provider kapalı policy
- Sık sorulan sorular

## Ana Kural

Bu adım canlı dış provider, GIB, banka, POS veya gerçek ödeme aktivasyonu yapmaz.

Bu adım public production help center değildir.

Bu adım controlled pilot yardım merkezi içerik standardını kurar.

Policy:

CLOSED_POLICY_GATE_REFERENCE_ONLY

## Kabul Kuralı

Yardım merkezi içeriği PASS sayılırsa:

- help_center_status = READY olmalıdır.
- help_center_mode = CONTROLLED_PILOT olmalıdır.
- required content article'ların tamamı READY olmalıdır.
- required evidence_ref alanları dolu olmalıdır.
- total_article_count gerçek article sayısıyla eşleşmelidir.
- ready_article_count gerçek READY sayısıyla eşleşmelidir.
- missing_article_count = 0 olmalıdır.
- required_fail_count = 0 olmalıdır.
- critical_issue_count = 0 olmalıdır.
- training_set_status = PASS olmalıdır.
- searchable_index_status = READY olmalıdır.
- support_route_status = READY olmalıdır.
- completion_checklist_status = READY olmalıdır.
- live_external_policy_status = CLOSED olmalıdır.

## Çıkış Kriterleri

Bu adım PASS sayılırsa:

- Yardım merkezi içeriği dokümanı vardır.
- Master config artifact vardır.
- Help center content artifact vardır.
- Help center article dosyaları vardır.
- Runtime validation script vardır ve executable durumdadır.
- Test fixture vardır.
- Audit script vardır.
- Valid help center fixture PASS döner.
- Invalid help center fixture FAIL döner.
- Required article guard doğrulanır.
- Evidence guard doğrulanır.
- Counter reconciliation guard doğrulanır.
- Critical issue zero guard doğrulanır.
- Searchable index guard doğrulanır.
- Support route guard doğrulanır.
- Closed policy marker doğrulanır.
- Final status gerçek test/audit sayaçlarından türetilir.
