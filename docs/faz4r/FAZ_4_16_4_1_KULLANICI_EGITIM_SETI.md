# 210 — FAZ 4-16.4.1 Kullanıcı Eğitim Seti

## Amaç

Pilot tenant kullanıcıları için kontrollü pilot eğitim setini standartlaştırır.

Bu adım 209 UAT sign-off PASS olduktan sonra eğitim/destek bloğuna geçişin ilk kapısıdır.

## Kapsam

Kullanıcı eğitim seti aşağıdaki eğitim modüllerini kapsar:

- Giriş / ilk kullanım
- Tenant / firma bağlamı
- Yönetim paneli temel kullanım
- POS temel kullanım
- Cari import kullanım rehberi
- Ürün / stok import kullanım rehberi
- Fiş / hareket import kullanım rehberi
- Import validation raporu okuma
- Muhasebe ekranı temel kullanım
- Muhasebeci portalı okuma akışı
- e-Belge / export preview akışı
- Hata bildirme / support yönlendirme
- Pilot sınırları ve kapalı canlı provider policy
- Sık yapılan hatalar
- Eğitim tamamlama checklist

## Ana Kural

Bu adım canlı dış provider, GIB, banka, POS veya gerçek ödeme aktivasyonu yapmaz.

Bu adım gerçek public launch eğitimi değildir.

Bu adım controlled pilot kullanıcı eğitim seti standardını kurar.

Policy:

CLOSED_POLICY_GATE_REFERENCE_ONLY

## Kabul Kuralı

Kullanıcı eğitim seti PASS sayılırsa:

- training_set_status = READY olmalıdır.
- training_mode = CONTROLLED_PILOT olmalıdır.
- required training module'lerin tamamı READY olmalıdır.
- required evidence_ref alanları dolu olmalıdır.
- total_module_count gerçek modül sayısıyla eşleşmelidir.
- ready_module_count gerçek READY sayısıyla eşleşmelidir.
- missing_module_count = 0 olmalıdır.
- required_fail_count = 0 olmalıdır.
- critical_issue_count = 0 olmalıdır.
- uat_signoff_status = PASS olmalıdır.
- support_handoff_ready = YES olmalıdır.
- completion_checklist_status = READY olmalıdır.
- live_external_policy_status = CLOSED olmalıdır.

## Çıkış Kriterleri

Bu adım PASS sayılırsa:

- Kullanıcı eğitim seti dokümanı vardır.
- Master config artifact vardır.
- Training set artifact vardır.
- Runtime validation script vardır ve executable durumdadır.
- Test fixture vardır.
- Audit script vardır.
- Valid training fixture PASS döner.
- Invalid training fixture FAIL döner.
- Required module guard doğrulanır.
- Evidence guard doğrulanır.
- Counter reconciliation guard doğrulanır.
- Critical issue zero guard doğrulanır.
- UAT sign-off dependency guard doğrulanır.
- Closed policy marker doğrulanır.
- Final status gerçek test/audit sayaçlarından türetilir.
