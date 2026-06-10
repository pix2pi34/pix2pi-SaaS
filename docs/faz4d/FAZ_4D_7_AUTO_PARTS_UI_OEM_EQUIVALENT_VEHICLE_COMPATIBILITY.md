# FAZ 4D-7 — Oto yedek parça UI: OEM / eşdeğer / araç uyum

## 1. Amaç

Bu adımın amacı, pilot işletme için oto yedek parça özel UI yüzeyini hazırlamak ve OEM, eşdeğer parça, araç uyum bilgilerinin core product modelinden ayrı tutulacağını mühürlemektir.

Bu adım, oto yedek parça sektörüne özel pilot yüzeydir.

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
FAZ_4D_7_READY=YES ✅

## 3. Oto Yedek Parça UI Kararları

| No | Karar | Açıklama | Durum |
|---:|---|---|---|
| 1 | Core product sade kalır | ERP ürün modeli sektör özel alanlarla şişirilmez | ACCEPTED |
| 2 | OEM alanı extension kalır | OEM numarası ürünün özel arama/uyum bilgisidir | ACCEPTED |
| 3 | Eşdeğer parça ilişkisi ayrı tutulur | Muadil/eşdeğer ürün ilişkisi core ürünün içine gömülmez | ACCEPTED |
| 4 | Araç uyum modeli ayrı tutulur | Marka, model, yıl, motor gibi bilgiler compatibility modelidir | ACCEPTED |
| 5 | Parça merkezli arama desteklenir | Kullanıcı parçadan uyumlu araçlara gidebilir | ACCEPTED |
| 6 | Araç merkezli arama desteklenir | Kullanıcı araçtan uyumlu parçalara gidebilir | ACCEPTED |
| 7 | Tenant-aware parça görünümü zorunludur | Pilot işletme başka tenant parça verisini görmemelidir | ACCEPTED |
| 8 | Barkod bu adımda opsiyonel kalır | Barkod özel notu 4D-8 altında kapatılır | ACCEPTED |
| 9 | Marketplace bu adımda production değildir | Uyumlu parçaların pazar yeri yayını 4D-9 discovery olur | ACCEPTED |
| 10 | UI mobile-ready korunur | Oto yedek parça yüzeyi mobil ekrana uyumlu tasarlanır | ACCEPTED |

## 4. Minimum Oto Yedek Parça Alanları

Pilot UI yüzeyinde şu alanlar bulunmalıdır:

- Parça arama
- OEM numarası
- Eşdeğer parça
- Muadil parça
- Araç uyum
- Marka
- Model
- Yıl
- Motor
- Stok durumu
- Tenant-safe görünüm
- Mobile-ready notu

## 5. Önerilen Veri Ayrımı

Core product:

- product_id
- tenant_id
- product_name
- sku
- category
- unit
- stock_tracking
- sale_status

Auto parts extension:

- product_id
- oem_number
- equivalent_group_id
- manufacturer
- compatibility_note

Vehicle compatibility:

- product_id
- vehicle_brand
- vehicle_model
- model_year_start
- model_year_end
- engine_code
- body_type

Bu ayrım sayesinde ERP core sade kalır, oto yedek parça sektörü ise güçlü arama ve uyum motoruna hazırlanır.

## 6. Pilot Minimum İş Akışı

1. Kullanıcı oto yedek parça yüzeyine girer.
2. Tenant/access bağlamı korunur.
3. Kullanıcı parça adı, SKU veya OEM numarası ile arama yapar.
4. Sistem eşdeğer/muadil parça ilişkisini gösterir.
5. Sistem araç uyum bilgisini gösterir.
6. Kullanıcı stok durumunu görür.
7. Gerekirse satış/sipariş akışına yönlenir.
8. Barkod bilgisi bu fazda opsiyonel not olarak bırakılır.
9. Marketplace ve Paraşüt bağlantıları bu ekranda production yapılmaz.

## 7. Kapsam Dışı

Bu adımda aşağıdakiler yapılmaz:

- Tam TECDOC entegrasyonu yapılmaz.
- Tam OEM veri sağlayıcı entegrasyonu yapılmaz.
- Tam araç veri tabanı importu yapılmaz.
- Tam production arama motoru yazılmaz.
- Tam barkod okutma yapılmaz.
- Tam marketplace yayını yapılmaz.
- Tam Paraşüt entegrasyonu yapılmaz.

## 8. Risk Notları

| Risk | Kontrol |
|---|---|
| Core product modeli şişer | OEM/eşdeğer/uyum extension olarak ayrılır |
| Parça arama sadece ürün adına bağlı kalır | OEM ve araç uyum araması yüzeye eklenir |
| Aynı parça farklı araçlara uyabilir | Compatibility modeli ayrı tutulur |
| Muadil parça ilişkisi kaybolur | Equivalent group yaklaşımı kullanılır |
| Tenant verisi karışabilir | Tenant-safe görünüm zorunlu |
| Barkod işi büyüyebilir | 4D-8 altında opsiyonel not olarak ayrılır |

## 9. Oluşturulan UI Dosyası

web/auto-parts-ui/index.html

Bu dosya:
- statik pilot oto yedek parça yüzeyidir,
- production deploy değildir,
- API entegrasyonu henüz yapılmaz,
- 4D-7 için UI kanıtıdır,
- 4D-8 barkod notu ve 4D-9 marketplace discovery için temel oluşturur.

## 10. Sonuç Alanı

FAZ_4D_7_AUTO_PARTS_UI_OEM_EQUIVALENT_VEHICLE_COMPATIBILITY_STATUS=PENDING
FAZ_4D_7_FINAL_STATUS=PENDING
FAZ_4D_8_READY=NO

## Not / Sonuç

[ buraya çıktı gelecek ]

## Evet / Hata

[ Evet / Hata ]
