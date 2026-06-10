# FAZ 4D-4 — ERP core product apply / staging → core kararları

## 1. Amaç

Bu adımın amacı, pilot ticari zincirde oluşan ürün, stok, satış ve sipariş hareketlerinin ERP core tarafına nasıl uygulanacağını karar seviyesinde mühürlemektir.

Bu adım büyük ERP kodu yazma adımı değildir.

Bu adımın hedefi:
- ürün master kararını sabitlemek,
- stok etkisi kararını sabitlemek,
- satış/sipariş hareketinin ERP core'a taşınma kararını sabitlemek,
- staging ile core arasındaki sınırı netleştirmek,
- journal / ledger tarafında pilot için hangi seviyenin yeterli olduğunu belirlemek,
- oto yedek parça özel alanlarının core ürün modelini bozmadan nasıl ayrılacağını sabitlemektir.

## 2. Giriş Şartı

FAZ_4D_1_FINAL_STATUS=PASS ✅
FAZ_4D_1_SEAL_STATUS=SEALED ✅
FAZ_4D_2_FINAL_STATUS=PASS ✅
FAZ_4D_2_SEAL_STATUS=SEALED ✅
FAZ_4D_3_FINAL_STATUS=PASS ✅
FAZ_4D_3_SEAL_STATUS=SEALED ✅
FAZ_4D_4_READY=YES ✅

## 3. ERP Core Apply Kararları

| No | Karar | Açıklama | Durum |
|---:|---|---|---|
| 1 | Ürün master core kalır | Pilot UI ürünleri ERP core ürün/hizmet varlığına bağlanır | ACCEPTED |
| 2 | Stok etkisi zorunlu karar alanıdır | Stok takipli ürünlerde hareket oluşmadan satış tamam sayılmaz | ACCEPTED |
| 3 | Satış/sipariş ERP apply hattına bağlanır | Ticari hareket ERP core tarafından işlenebilir olmalı | ACCEPTED |
| 4 | Event/audit izi zorunludur | Apply işlemi izlenebilir ve replay-safe olmalıdır | ACCEPTED |
| 5 | Journal/ledger pilotta staging kabul edilir | Pilot için tam muhasebe final yerine staging karar kaydı yeterlidir | ACCEPTED |
| 6 | TDHP mapping core kararına bağlanır | 120 / 600 / 391 gibi hesap kararları ERP core tarafında korunur | ACCEPTED |
| 7 | Oto yedek parça detayları extension kalır | OEM, eşdeğer ve araç uyum core ürün modelini şişirmez | ACCEPTED |
| 8 | Marketplace ve Paraşüt bu adımda production değildir | Bu fazda discovery ve karar dokümanı seviyesinde kalır | ACCEPTED |
| 9 | Tenant-aware apply zorunludur | ERP apply hiçbir tenant bağlamı olmadan çalışmamalıdır | ACCEPTED |
| 10 | Idempotent apply hedeflenir | Aynı hareket iki kez finansal sonuç üretmemelidir | ACCEPTED |

## 4. Staging → Core Sınırı

### Core kabul edilenler

- tenant_id
- product_id veya item_id
- customer_id veya party_id
- stock movement niyeti
- sale/order movement niyeti
- event_id veya correlation_id
- ERP apply sonucu
- audit izi
- TDHP mapping kararı

### Staging kabul edilenler

- pilot ekranından gelen eksik ticari alanlar
- ürün açıklama zenginleştirme
- oto yedek parça OEM/eşdeğer/araç uyum detayları
- marketplace discovery notları
- Paraşüt discovery notları
- henüz production olmayan accounting export kararları

## 5. Pilot ERP Apply Minimum Akışı

Pilot için minimum ERP apply akışı şudur:

1. Tenant context oluşur.
2. Kullanıcı ürün veya hizmet seçer.
3. Cari / müşteri ilişkisi oluşur.
4. Satış veya sipariş hareketi oluşur.
5. Stok etkisi hesaplanır veya stok dışı ürün olarak işaretlenir.
6. ERP core apply çağrılır.
7. Event veya audit izi üretilir.
8. Journal / ledger tarafında staging veya core kayıt kararı oluşur.
9. Sonuç raporlanabilir hale gelir.

## 6. Oto Yedek Parça Kararı

Oto yedek parça özel alanları core ürün modelinin içine doğrudan gömülmeyecektir.

Bunun yerine:

- core product sade kalır,
- OEM numarası extension alanı olarak ele alınır,
- eşdeğer parça ilişkisi ayrı model olarak ele alınır,
- araç uyum bilgisi ayrı compatibility modeli olarak ele alınır,
- 4D-7 altında UI ve veri yüzeyi ayrıca işlenir.

Bu karar, ERP core'un perakende, pazar yeri, servis, stok ve farklı sektörlerde tekrar kullanılabilir kalmasını sağlar.

## 7. Pilot Kabul Kriterleri

4D-4 şu şartlarla PASS alır:

- 4D-3 raporu PASS olmalı.
- Master plan içinde 4D-4 IN_PROGRESS olmalı.
- ERP core karar dokümanı var olmalı.
- Ürün master kararı ACCEPTED olmalı.
- Stok etkisi kararı ACCEPTED olmalı.
- Satış/sipariş ERP apply kararı ACCEPTED olmalı.
- Event/audit izi kararı ACCEPTED olmalı.
- Journal/ledger staging kararı ACCEPTED olmalı.
- Oto yedek parça extension kararı ACCEPTED olmalı.
- Rapor dosyası üretilmeli.
- 4D-5'e geçiş izni oluşmalı.

## 8. Kapsam Dışı

Bu adımda aşağıdakiler yapılmaz:

- Tam ERP muhasebe final kodu yazılmaz.
- Tam ledger posting production final yapılmaz.
- Tam e-Fatura veya e-Arşiv entegrasyonu yapılmaz.
- Tam Paraşüt production entegrasyonu yapılmaz.
- Tam marketplace production entegrasyonu yapılmaz.
- Oto yedek parça UI bu adımda yazılmaz.

## 9. Risk Notları

| Risk | Kontrol |
|---|---|
| Ürün core modeli fazla şişebilir | Oto yedek parça alanları extension kalır |
| Satış var ama ERP apply yok | ERP apply kararı zorunlu ACCEPTED |
| Stok hareketi unutulabilir | Stok etkisi zorunlu karar alanı |
| Muhasebe finali pilotu yavaşlatabilir | Journal/ledger staging pilot için kabul edilir |
| Tenant karışması olabilir | Tenant-aware apply zorunlu |
| Duplicate hareket finansı bozabilir | Idempotent apply hedeflenir |

## 10. Sonuç Alanı

FAZ_4D_4_ERP_CORE_PRODUCT_APPLY_STAGING_CORE_DECISIONS_STATUS=PENDING
FAZ_4D_4_FINAL_STATUS=PENDING
FAZ_4D_5_READY=NO

## Not / Sonuç

[ buraya çıktı gelecek ]

## Evet / Hata

[ Evet / Hata ]
