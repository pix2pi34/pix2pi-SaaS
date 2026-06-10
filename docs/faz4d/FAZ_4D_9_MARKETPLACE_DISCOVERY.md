# FAZ 4D-9 — Marketplace discovery

## 1. Amaç

Bu adımın amacı, Pix2pi pilot işletme yüzeyinden marketplace modeline ileride nasıl geçileceğini keşif seviyesinde belgelemek ve kapsamı production entegrasyona büyütmeden mühürlemektir.

Bu adım production marketplace entegrasyonu değildir.

Bu adımın hedefi:
- marketplace yönünü netleştirmek,
- ürün/parça yayınlama hazırlığını tanımlamak,
- tenant izolasyonunu korumak,
- stok/fiyat/sipariş senkronu için sonraki faz kararlarını ayırmak,
- komisyon ve gelir modelini sonraki ticari faza taşımak,
- oto yedek parça marketplace uygunluğunu discovery seviyesinde görmek.

## 2. Giriş Şartı

FAZ_4D_1_FINAL_STATUS=PASS ✅
FAZ_4D_1_SEAL_STATUS=SEALED ✅
FAZ_4D_2_FINAL_STATUS=PASS ✅
FAZ_4D_2_SEAL_STATUS=SEALED ✅
FAZ_4D_3_FINAL_STATUS=PASS ✅
FAZ_4D_3_SEAL_STATUS=SEALED ✅
FAZ_4D_4_FINAL_STATUS=PASS ✅
FAZ_4D_4_SEAL_STATUS=SEALED ✅
FAZ_4D_5_FINAL_STATUS=PASS ✅
FAZ_4D_5_SEAL_STATUS=SEALED ✅
FAZ_4D_6_FINAL_STATUS=PASS ✅
FAZ_4D_6_SEAL_STATUS=SEALED ✅
FAZ_4D_7_FINAL_STATUS=PASS ✅
FAZ_4D_7_SEAL_STATUS=SEALED ✅
FAZ_4D_8_FINAL_STATUS=PASS ✅
FAZ_4D_8_SEAL_STATUS=SEALED ✅
FAZ_4D_9_READY=YES ✅

## 3. Marketplace Discovery Kararları

| No | Karar | Açıklama | Durum |
|---:|---|---|---|
| 1 | Marketplace bu fazda discovery kalır | Production satış kanalı açılmaz | ACCEPTED |
| 2 | Ürün yayınlama hazırlığı tanımlanır | Ürün adı, açıklama, fiyat, stok ve görsel alanları keşfedilir | ACCEPTED |
| 3 | Tenant izolasyonu zorunludur | Her satıcı/işletme kendi ürününü görür ve yönetir | ACCEPTED |
| 4 | Stok senkronu sonraki faza bırakılır | Gerçek zamanlı stok senkronu bu adımda yapılmaz | ACCEPTED |
| 5 | Fiyat senkronu sonraki faza bırakılır | Marketplace fiyat yönetimi production yapılmaz | ACCEPTED |
| 6 | Sipariş alma production yapılmaz | Marketplace üzerinden gerçek sipariş kabul edilmez | ACCEPTED |
| 7 | Komisyon modeli FAZ 5 ticari hazırlığa taşınır | Platform gelir modeli ayrı çalışılır | ACCEPTED |
| 8 | Oto yedek parça uyumu keşfedilir | OEM/eşdeğer/araç uyum bilgileri marketplace için avantajdır | ACCEPTED |
| 9 | Paraşüt ile çakışma engellenir | Muhasebe/ön muhasebe entegrasyonu 4D-10'da ayrı discovery olur | ACCEPTED |
| 10 | Public API / webhook finali yapılmaz | Marketplace entegrasyonu sonraki platform fazlarında derinleşir | ACCEPTED |

## 4. Marketplace Minimum Discovery Alanları

Marketplace için keşif seviyesinde şu alanlar not edilir:

- tenant_id
- seller_id veya merchant_id
- product_id
- product_name
- description
- category
- price
- currency
- stock_quantity
- sku
- barcode opsiyonel
- oem_number opsiyonel
- equivalent_group_id opsiyonel
- vehicle_compatibility opsiyonel
- publish_status
- commission_policy_placeholder

## 5. Pilot İçin Marketplace Akışı

Pilot aşamasında marketplace akışı sadece keşif ve hazırlık seviyesindedir:

1. Pilot ürün veya parça seçilir.
2. Ürün marketplace'e uygun mu diye değerlendirilir.
3. Ürün adı, kategori, fiyat ve stok bilgileri kontrol edilir.
4. Oto yedek parça ise OEM/eşdeğer/araç uyum avantajları not edilir.
5. Tenant/seller ayrımı korunur.
6. Yayınlama, gerçek sipariş, ödeme ve komisyon production yapılmaz.
7. FAZ 5 ticari hazırlık ve FAZ 6 ölçek/entegrasyon fazlarına devredilecek alanlar ayrılır.

## 6. Marketplace Kapsam Dışı

Bu adımda aşağıdakiler yapılmaz:

- Gerçek marketplace yayını yapılmaz.
- Gerçek sipariş kabul edilmez.
- Gerçek ödeme alınmaz.
- Gerçek komisyon tahsilatı yapılmaz.
- Pazar yeri public API finali yapılmaz.
- Webhook engine production yapılmaz.
- Seller onboarding production yapılmaz.
- Kargo/lojistik entegrasyonu yapılmaz.
- Kampanya/kupon sistemi yapılmaz.
- Tam arama motoru yapılmaz.

## 7. Profesyonel Mimari Not

Marketplace, ERP core'un içine gömülmemelidir.

Doğru ayrım:

- ERP core: ürün, stok, cari, satış, finansal hareket
- Marketplace layer: yayınlama, satıcı, katalog görünürlüğü, komisyon, sipariş alma
- Integration layer: webhook, public API, payment, shipping, external platform sync
- Reporting layer: satış performansı, komisyon, stok görünürlüğü

Bu ayrım Pix2pi'nin hem ERP hem ticaret platformu olarak büyümesini sağlar.

## 8. Oto Yedek Parça Marketplace Notu

Oto yedek parçada marketplace avantajı yüksektir çünkü:

- aynı parça birden fazla araca uyabilir,
- OEM numarası arama kalitesini artırır,
- eşdeğer/muadil parça önerisi satış ihtimalini artırır,
- araç uyum bilgisi yanlış siparişi azaltır,
- stok ve konum bilgisi ileride yakın satıcı önerisine dönüşebilir.

Bu fazda bu avantajlar sadece discovery olarak not edilir.

## 9. Oluşturulan Discovery UI Dosyası

web/marketplace-discovery/index.html

Bu dosya:
- statik marketplace discovery yüzeyidir,
- production marketplace değildir,
- gerçek sipariş almaz,
- ödeme/komisyon çalıştırmaz,
- 4D-9 için keşif kanıtıdır,
- 4D-10 Paraşüt discovery ve FAZ 5 commercial readiness için temel oluşturur.

## 10. Sonuç Alanı

FAZ_4D_9_MARKETPLACE_DISCOVERY_STATUS=PENDING
FAZ_4D_9_FINAL_STATUS=PENDING
FAZ_4D_10_READY=NO

## Not / Sonuç

[ buraya çıktı gelecek ]

## Evet / Hata

[ Evet / Hata ]
