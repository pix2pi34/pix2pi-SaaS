# FAZ 5-2 — Packages / Pricing Architecture

## 1. Adım Kimliği

FAZ_NO=5
STEP_NO=5-2
STEP_NAME=Packages / Pricing Architecture
STEP_TITLE=Paketler ve fiyatlama mimarisi
STEP_STATUS=PASS
STEP_SEAL_STATUS=SEALED
FAZ_5_2_PACKAGES_PRICING_STATUS=PASS
FAZ_5_2_PACKAGES_PRICING_SEAL_STATUS=SEALED
FAZ_5_3_READY=YES

## 2. Giriş Şartı

Bu adımın başlayabilmesi için:

FAZ_5_1_TEST_STATUS=PASS ✅
FAZ_5_1_SCOPE_FREEZE_STATUS=PASS ✅
FAZ_5_1_SCOPE_FREEZE_SEAL_STATUS=SEALED ✅
FAZ_5_2_READY=YES ✅

## 3. Amaç

Bu adımın amacı Pix2pi için ilk ticari paket mimarisini ve fiyatlama modelini belirlemektir.

Bu adım sonunda:

- Demo paketi tanımlanır.
- Starter paketi tanımlanır.
- Pro paketi tanımlanır.
- Enterprise paketi tanımlanır.
- Muhasebeci paketi tanımlanır.
- Aylık ve yıllık fiyatlama mantığı belirlenir.
- Modül bazlı upsell alanları ayrılır.
- 5-3 Entitlement Matrix için temel oluşturulur.

## 4. Fiyatlama Ana Prensipleri

| No | Prensip | Açıklama | Durum |
|---:|---|---|---|
| 1 | Paket sayısı az tutulur | İlk ticari çıkışta karmaşa yapılmaz | ACCEPTED |
| 2 | Starter giriş paketidir | Küçük işletme için düşük riskli başlangıç | ACCEPTED |
| 3 | Pro ana büyüme paketidir | Pix2pi'nin ana ticari büyüme paketi | ACCEPTED |
| 4 | Enterprise özel tekliftir | Büyük müşteri, özel SLA ve özel entegrasyon | ACCEPTED |
| 5 | Muhasebeci ayrı ürün ailesidir | Firma başı ücret ve export hakkı ayrı yönetilir | ACCEPTED |
| 6 | Yıllık ödeme teşvik edilir | Yaklaşık 10 ay öde 12 ay kullan mantığı | ACCEPTED |
| 7 | Public fiyatlar sonra yayınlanır | Public pricing 5-10 içinde hazırlanır | ACCEPTED |

## 5. Paket Ailesi

FAZ 5 ticari paket ailesi:

- demo
- starter
- pro
- enterprise
- accountant

## 6. Paket 1 — Demo

Kod:

- demo

Amaç:

- Satış öncesi deneme
- Pilot ön izleme
- Demo tenant akışı

Fiyat:

- Aylık: 0 TRY
- Yıllık: 0 TRY

Limitler:

- 1 tenant
- 1 şube
- 2 kullanıcı
- 100 test ürün
- 50 test satış kaydı
- Export kapalı
- API kapalı
- Canlı finansal işlem kapalı
- Süre: 14 gün

Karar:

ACTIVE_PACKAGE

## 7. Paket 2 — Starter

Kod:

- starter

Amaç:

- Küçük işletme başlangıç paketi

Önerilen iç fiyat:

- Aylık: 799 TRY
- Yıllık: 7.990 TRY

Limitler:

- 1 tenant
- 1 şube
- 3 kullanıcı
- Temel ERP açık
- Temel POS açık
- Temel stok açık
- Temel müşteri / cari açık
- Temel raporlar açık
- Export sınırlı
- API kapalı
- Marketplace discovery kapalı veya sınırlı

Karar:

ACTIVE_PACKAGE

## 8. Paket 3 — Pro

Kod:

- pro

Amaç:

- Ana büyüme paketi

Önerilen iç fiyat:

- Aylık: 1.999 TRY
- Yıllık: 19.990 TRY

Limitler:

- 1 tenant
- 3 şube
- 10 kullanıcı
- ERP açık
- POS açık
- Stok açık
- Cari açık
- Gelişmiş raporlar açık
- Export açık
- Paraşüt discovery açık
- Marketplace discovery açık
- API sınırlı açık
- Muhasebeci paylaşımı opsiyonel

Karar:

ACTIVE_PACKAGE

## 9. Paket 4 — Enterprise

Kod:

- enterprise

Amaç:

- Kurumsal / çok şubeli / özel entegrasyonlu müşteri

Fiyat:

- Özel teklif

Limitler:

- Şube limiti özel
- Kullanıcı limiti özel
- API açık
- Export açık
- Özel SLA
- Özel entegrasyon
- Gelişmiş audit
- Gelişmiş reporting
- Gelişmiş destek
- Kurumsal onboarding

Karar:

ACTIVE_PACKAGE

## 10. Paket 5 — Muhasebeci

Kod:

- accountant

Amaç:

- Muhasebeci / mali müşavir workspace ürünü

Önerilen iç fiyat:

- Workspace aylık: 999 TRY
- Workspace yıllık: 9.990 TRY
- Firma başı aylık ek ücret: 149 TRY

Limitler:

- 1 muhasebeci workspace
- 10 firma dahil
- Firma başı ek ücret modeli
- Excel export açık
- PDF export açık
- TDHP export açık
- Logo / Mikro / Zirve / ETA export ileride opsiyonel
- Firma bazlı erişim kontrolü

Karar:

ACTIVE_PACKAGE

## 11. Modül Bazlı Upsell Alanları

Aşağıdaki alanlar paket üstü ek gelir kalemi olabilir:

1. Gelişmiş reporting
2. API erişimi
3. Muhasebeci portalı
4. Ek kullanıcı
5. Ek şube
6. Ek tenant / firma
7. Marketplace entegrasyonu
8. Paraşüt / muhasebe entegrasyonları
9. Logo / Mikro / Zirve / ETA export
10. Premium destek
11. Özel onboarding
12. Gelişmiş audit / compliance
13. İleri stok / oto yedek parça uyumluluk modülü
14. Developer sandbox
15. Public API quota artırımı

Karar:

UPSELL_READY

## 12. Fiyatlama Para Birimi

İlk iç ticari versiyon:

- Para birimi: TRY
- Vergi gösterimi: KDV hariç
- Public yayın: 5-10 içinde ayrıca hazırlanacak
- İndirim: yıllık ödeme teşviki
- Özel fiyat: enterprise ve büyük muhasebeci hesapları

Karar:

TRY_INTERNAL_V1

## 13. Paket Karşılaştırma Özeti

| Paket | Aylık | Yıllık | Kullanıcı | Şube | API | Export | Hedef |
|---|---:|---:|---:|---:|---|---|---|
| Demo | 0 | 0 | 2 | 1 | Kapalı | Kapalı | Deneme |
| Starter | 799 | 7.990 | 3 | 1 | Kapalı | Sınırlı | Küçük işletme |
| Pro | 1.999 | 19.990 | 10 | 3 | Sınırlı | Açık | Büyüyen işletme |
| Enterprise | Özel | Özel | Özel | Özel | Açık | Açık | Kurumsal |
| Muhasebeci | 999 + firma | 9.990 + firma | Özel | Firma bazlı | Sınırlı | Açık | Muhasebeci |

## 14. 5-3 İçin Aktarılacak Kararlar

5-3 Entitlement Matrix adımı şu paketleri baz alacak:

- demo
- starter
- pro
- enterprise
- accountant

5-3 içinde her paket için şu haklar netleşecek:

- module_access
- user_limit
- branch_limit
- tenant_limit
- api_access
- export_access
- reporting_access
- marketplace_access
- accountant_portal_access
- support_level
- billing_policy
- freeze_policy

## 15. Kapsam Dışı

Bu adımda aşağıdakiler yapılmaz:

- Gerçek ödeme kuruluşu entegrasyonu
- Canlı tahsilat
- Public fiyat sayfası yayını
- Abonelik runtime kodu
- Entitlement middleware kodu
- Paket değişim otomasyonu

Bu başlıklar sonraki FAZ 5 adımlarında ele alınacaktır.

## 16. Çıkış Kriterleri

Bu adım PASS sayılmak için:

- 5 paket tanımlanmış olmalı
- Starter fiyatı tanımlanmış olmalı
- Pro fiyatı tanımlanmış olmalı
- Enterprise özel teklif olarak ayrılmış olmalı
- Muhasebeci paketi ayrı tanımlanmış olmalı
- Demo kontrollü paket olarak tanımlanmış olmalı
- Yıllık ödeme teşviki yazılmış olmalı
- Upsell alanları yazılmış olmalı
- JSON pricing catalog oluşturulmuş olmalı
- 5-3 geçiş izni verilmiş olmalı

## 17. 5-2 Mühür

FAZ_5_2_TEST_STATUS=PASS
FAZ_5_2_PACKAGES_PRICING_STATUS=PASS
FAZ_5_2_PACKAGES_PRICING_SEAL_STATUS=SEALED
FAZ_5_3_READY=YES

## Not / Sonuç

[ buraya çıktı gelecek ]

## Evet / Hata

[ Evet / Hata ]
