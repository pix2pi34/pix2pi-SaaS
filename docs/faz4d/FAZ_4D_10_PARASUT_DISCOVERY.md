# FAZ 4D-10 — Paraşüt discovery

## 1. Amaç

Bu adımın amacı, Pix2pi ERP core ile Paraşüt arasında ileride kurulabilecek entegrasyon sınırlarını keşif seviyesinde belgelemek ve production entegrasyona büyütmeden mühürlemektir.

Bu adım production Paraşüt entegrasyonu değildir.

Bu adımın hedefi:
- Paraşüt bağlantı kapsamını keşfetmek,
- cari/müşteri, ürün, satış, fatura ve tahsilat alanlarını ayırmak,
- Pix2pi ERP core'un ana kayıt kaynağı olarak kalmasını sağlamak,
- tenant izolasyonunu korumak,
- credential ve secret bilgisini repo içine koymamak,
- e-Fatura/e-Arşiv kapsamını ayrı tutmak,
- marketplace ile Paraşüt entegrasyonunun birbirine karışmasını engellemek,
- sonraki fazlar için API/export/import karar kapısını hazırlamaktır.

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
FAZ_4D_9_FINAL_STATUS=PASS ✅
FAZ_4D_9_SEAL_STATUS=SEALED ✅
FAZ_4D_10_READY=YES ✅

## 3. Paraşüt Discovery Kararları

| No | Karar | Açıklama | Durum |
|---:|---|---|---|
| 1 | Paraşüt bu fazda discovery kalır | Production API bağlantısı yapılmaz | ACCEPTED |
| 2 | Pix2pi ERP core ana kaynak kalır | Paraşüt Pix2pi core'u ezmez | ACCEPTED |
| 3 | Cari/müşteri eşleme keşfedilir | Customer/party mapping sonraki faza hazırlanır | ACCEPTED |
| 4 | Ürün/hizmet eşleme keşfedilir | Product/item mapping ayrı karar alanıdır | ACCEPTED |
| 5 | Satış/fatura akışı keşfedilir | Satıştan fatura/fiş çıktısına giden sınır belirlenir | ACCEPTED |
| 6 | Tahsilat/ödeme akışı keşfedilir | Ödeme ve tahsilat sync production yapılmaz | ACCEPTED |
| 7 | TDHP ve muhasebe mapping korunur | Pix2pi UFK/TDHP kararları Paraşüt tarafından bozulmaz | ACCEPTED |
| 8 | e-Fatura/e-Arşiv ayrı tutulur | Bu adım e-belge production entegrasyonu değildir | ACCEPTED |
| 9 | Credential/secret repo içine yazılmaz | API key, token, client secret bu adımda tutulmaz | ACCEPTED |
| 10 | Tenant-aware integration zorunludur | Her tenant kendi Paraşüt bağlantısına sahip olmalıdır | ACCEPTED |
| 11 | Marketplace ile karıştırılmaz | Pazar yeri satış kanalı ve ön muhasebe bağlantısı ayrıdır | ACCEPTED |
| 12 | API/export/import kararı sonraki faza bırakılır | En doğru bağlantı yöntemi sonraki entegrasyon fazında seçilir | ACCEPTED |

## 4. Paraşüt Minimum Discovery Alanları

Paraşüt keşif seviyesinde şu alanlar not edilir:

- tenant_id
- parasut_connection_status
- external_customer_id
- external_product_id
- external_invoice_id
- customer_mapping_status
- product_mapping_status
- sale_invoice_mapping_status
- payment_collection_mapping_status
- tax_mapping_status
- tdhp_mapping_status
- sync_direction
- sync_status
- last_sync_at
- error_message
- credential_storage_policy

## 5. Olası Entegrasyon Sınırları

Paraşüt tarafı için ileride değerlendirilecek sınırlar:

- cari/müşteri aktarımı
- ürün/hizmet aktarımı
- satış/fatura aktarımı
- tahsilat/ödeme aktarımı
- fatura durumu geri okuma
- muhasebe/ön muhasebe mutabakatı
- hata kuyruğu ve yeniden deneme
- tenant bazlı bağlantı yönetimi

Bu adımda bu maddeler sadece discovery seviyesinde tutulur.

## 6. Pix2pi Ana Kaynak Kararı

Pix2pi ERP core ana kayıt kaynağı olarak kalacaktır.

Bu kararın anlamı:

- Pix2pi ürün/stok/satış kararını üretir.
- Paraşüt entegrasyonu bu kararı destekleyen dış sistem bağlantısı olur.
- Paraşüt tarafındaki veri Pix2pi core'u kontrolsüz ezmez.
- Her sync işlemi audit/event iziyle izlenebilir olmalıdır.
- Tenant bazlı bağlantı ayrımı zorunludur.

## 7. Kapsam Dışı

Bu adımda aşağıdakiler yapılmaz:

- Gerçek Paraşüt API çağrısı yapılmaz.
- API key, token veya client secret yazılmaz.
- Canlı müşteri verisi gönderilmez.
- Canlı fatura oluşturulmaz.
- Canlı tahsilat veya ödeme işlenmez.
- e-Fatura/e-Arşiv production yapılmaz.
- Webhook production yapılmaz.
- Otomatik sync worker yazılmaz.
- Error retry/DLQ entegrasyonu yapılmaz.
- Marketplace satışları Paraşüt'e bağlanmaz.

## 8. Risk Notları

| Risk | Kontrol |
|---|---|
| Paraşüt Pix2pi core'u ezer | Pix2pi ana kaynak kararı |
| Secret repo içine yazılır | Credential/secret yasak kararı |
| Tenant bağlantıları karışır | Tenant-aware integration zorunlu |
| Marketplace ile ön muhasebe karışır | Marketplace ve Paraşüt ayrı discovery |
| e-belge kapsamı büyür | e-Fatura/e-Arşiv ayrı tutulur |
| Sync çift kayıt üretir | İleride idempotent sync kararı gerekir |
| Hata yönetimi unutulur | Error/retry sonraki fazda ayrı ele alınır |

## 9. Oluşturulan Discovery UI Dosyası

web/parasut-discovery/index.html

Bu dosya:
- statik Paraşüt discovery yüzeyidir,
- production Paraşüt entegrasyonu değildir,
- gerçek API çağrısı yapmaz,
- credential tutmaz,
- canlı veri göndermez,
- 4D-10 için keşif kanıtıdır,
- 4D-11 Controlled Pilot Go-Live öncesi entegrasyon kapsamını temiz tutar.

## 10. Sonuç Alanı

FAZ_4D_10_PARASUT_DISCOVERY_STATUS=PENDING
FAZ_4D_10_FINAL_STATUS=PENDING
FAZ_4D_11_READY=NO

## Not / Sonuç

[ buraya çıktı gelecek ]

## Evet / Hata

[ Evet / Hata ]
