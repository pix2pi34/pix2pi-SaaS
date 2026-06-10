# FAZ 4D-8 — Barkod opsiyonel UI notu

## 1. Amaç

Bu adımın amacı, oto yedek parça pilot yüzeyinde barkod desteğinin zorunlu değil opsiyonel olduğunu mühürlemektir.

Barkod, pilot iş akışını bloke etmeyecektir.

Kullanıcı parçayı şu yollarla bulabilmelidir:

- Parça adı
- SKU
- OEM numarası
- Eşdeğer parça ilişkisi
- Muadil parça ilişkisi
- Araç marka/model/yıl/motor uyumu
- Barkod veya EAN/GTIN, varsa

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
FAZ_4D_8_READY=YES ✅

## 3. Barkod Kararları

| No | Karar | Açıklama | Durum |
|---:|---|---|---|
| 1 | Barkod opsiyonel kalır | Pilot satış/parça arama akışı barkoda bağlı olmaz | ACCEPTED |
| 2 | SKU manuel arama desteklenir | Kullanıcı barkodsuz SKU ile ürün bulabilir | ACCEPTED |
| 3 | OEM manuel arama desteklenir | Oto yedek parçada OEM barkoddan daha kritik olabilir | ACCEPTED |
| 4 | EAN/GTIN alanı staging kabul edilir | Barkod standardı daha sonra core/extension kararına bağlanır | ACCEPTED |
| 5 | Kamera ile barkod okutma production yapılmaz | Bu fazda native/camera scanner yapılmaz | ACCEPTED |
| 6 | Harici barkod okuyucu gelecekte desteklenebilir | USB/bluetooth okuyucu ileride POS/PWA ile ele alınır | ACCEPTED |
| 7 | Barkod yoksa ürün satışı bloke edilmez | Barkodsuz ürün pilotta işlenebilir | ACCEPTED |
| 8 | Barkod tenant-safe olmalıdır | Barkod eşleşmesi başka tenant ürününe gitmemelidir | ACCEPTED |
| 9 | Mobile-ready notu korunur | PWA tarafında gelecekte scanner uyumu değerlendirilebilir | ACCEPTED |
| 10 | Barkod finali FAZ 5/6 sonrası değerlendirilebilir | Pilot fazda kapsam büyütülmez | ACCEPTED |

## 4. Pilot UI Notu

Pilot UI üzerinde barkod için gösterilecek not:

Barkod opsiyoneldir. Ürün veya parça; SKU, OEM numarası, parça adı, eşdeğer parça veya araç uyum bilgisiyle de bulunabilir. Barkod okutma üretim finali bu fazın kapsamında değildir.

## 5. Teknik Yaklaşım

Bu fazda barkod için production cihaz entegrasyonu yapılmaz.

Bunun yerine şu bilgi alanları desteklenebilir olarak not edilir:

- sku
- barcode
- ean
- gtin
- oem_number
- equivalent_group_id
- vehicle_compatibility

Barkod alanı core product içine zorunlu alan olarak eklenmez. İlk aşamada opsiyonel alan veya extension alanı olarak ele alınır.

## 6. Kapsam Dışı

Bu adımda aşağıdakiler yapılmaz:

- Kamera ile barkod okutma yapılmaz.
- Native mobil barcode scanner yapılmaz.
- USB/bluetooth barkod okuyucu production entegrasyonu yapılmaz.
- Barkod standardı finalleştirilmez.
- Barkoddan otomatik stok düşme production yapılmaz.
- Barkoddan marketplace yayını yapılmaz.
- Barkoddan Paraşüt eşleştirme yapılmaz.

## 7. Risk Notları

| Risk | Kontrol |
|---|---|
| Barkod işi pilotu büyütür | Opsiyonel not olarak mühürlenir |
| Barkodsuz ürün satılamaz sanılır | Barkodsuz satış/parça arama serbest bırakılır |
| OEM yerine barkoda aşırı bağımlılık oluşur | OEM manuel arama desteklenir |
| Kamera scanner kapsamı büyütür | Production scanner kapsam dışı |
| Barkod tenant karışıklığı yaratır | Tenant-safe barkod eşleşmesi zorunlu karar olur |
| POS/PWA işi büyür | Barkod finali sonraki faza bırakılır |

## 8. Oluşturulan UI Not Dosyası

web/auto-parts-ui/barcode-optional-note.html

Bu dosya:
- statik pilot barkod not yüzeyidir,
- production scanner değildir,
- API entegrasyonu yapmaz,
- barkodun opsiyonel kaldığını gösterir,
- 4D-9 marketplace discovery için kapsamı temiz tutar.

## 9. Sonuç Alanı

FAZ_4D_8_BARCODE_OPTIONAL_UI_NOTE_STATUS=PENDING
FAZ_4D_8_FINAL_STATUS=PENDING
FAZ_4D_9_READY=NO

## Not / Sonuç

[ buraya çıktı gelecek ]

## Evet / Hata

[ Evet / Hata ]
