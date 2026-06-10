# FAZ 5-10 — Public / Pricing / Developer Surfaces

## 1. Adım Kimliği

FAZ_NO=5
STEP_NO=5-10
STEP_NAME=Public / Pricing / Developer Surfaces
STEP_TITLE=Public pricing ve developer yüzeyleri
STEP_STATUS=PASS
STEP_SEAL_STATUS=SEALED
FAZ_5_10_PUBLIC_PRICING_DEVELOPER_STATUS=PASS
FAZ_5_10_PUBLIC_PRICING_DEVELOPER_SEAL_STATUS=SEALED
FAZ_5_11_READY=YES

## 2. Giriş Şartı

Bu adımın başlayabilmesi için:

FAZ_5_9_TEST_STATUS=PASS ✅
FAZ_5_9_REVENUE_METRICS_STATUS=PASS ✅
FAZ_5_9_REVENUE_METRICS_SEAL_STATUS=SEALED ✅
FAZ_5_10_READY=YES ✅

## 3. Amaç

Bu adımın amacı FAZ 5 içinde oluşturulan ticari paket, fiyatlama, entitlement, billing, legal, support, sales ve revenue kararlarını public ve developer yüzeylerine hazırlamaktır.

Bu adımda production public launch yapılmaz.

Bu adımın hedefi:

- Public site yüzeylerini tanımlamak
- Pricing UI kararlarını görünür hale getirmek
- Developer surface kapsamını tanımlamak
- Web dosyalarını oluşturmak
- Public / developer JSON contract oluşturmak
- 5-11 Commercial Readiness Test Suite adımına geçişi hazırlamak

## 4. 5-10.1 Public Site Yüzeyleri

### 5-10.1 Public site yüzeyleri

Public site yüzeyleri Pix2pi'nin dış dünyaya anlatılacak ticari vitrini olarak tanımlanır.

Durum:

DONE ✅

### 5-10.1.1 Landing page ticari metinleri

Landing page içinde Pix2pi'nin ana değer önerisi net yazılır.

Ana mesaj:

- Perakende, POS, ERP, stok, cari, rapor ve muhasebeci akışlarını tek ticari platformda birleştiren SaaS ERP.

Durum:

DONE ✅

### 5-10.1.2 Paket / fiyat sayfası

Paket / fiyat sayfası demo, starter, pro, enterprise ve muhasebeci paketlerini gösterir.

Durum:

DONE ✅

### 5-10.1.3 Paket karşılaştırma

Paket karşılaştırma yüzeyi hangi pakette hangi temel hakların olduğunu gösterir.

Durum:

DONE ✅

### 5-10.1.4 Demo başvuru sayfası

Demo başvuru yüzeyi müşteri adayından ilk bilgileri toplamak için planlanır.

Durum:

DONE ✅

### 5-10.1.5 İletişim / satış formu

İletişim / satış formu demo, teklif ve enterprise görüşme talepleri için planlanır.

Durum:

DONE ✅

### 5-10.1.6 Legal footer linkleri

Footer içinde kullanım şartları, gizlilik politikası, KVKK, çerez politikası ve iletişim linkleri yer almalıdır.

Durum:

DONE ✅

## 5. 5-10.2 Pricing UI

### 5-10.2 Pricing UI

Pricing UI, paketlerin müşteriye anlaşılır şekilde sunulmasını sağlar.

Durum:

DONE ✅

### 5-10.2.1 Demo kartı

Demo kartı ücretsiz deneme / satış öncesi keşif paketi olarak gösterilir.

Durum:

DONE ✅

### 5-10.2.2 Starter kartı

Starter kartı küçük işletme başlangıç paketi olarak gösterilir.

Durum:

DONE ✅

### 5-10.2.3 Pro kartı

Pro kartı ana büyüme paketi olarak gösterilir.

Durum:

DONE ✅

### 5-10.2.4 Enterprise özel teklif kartı

Enterprise kartı özel teklif ve özel SLA mantığıyla gösterilir.

Durum:

DONE ✅

### 5-10.2.5 Muhasebeci paket kartı

Muhasebeci paketi workspace + firma bazlı ücret modeliyle gösterilir.

Durum:

DONE ✅

### 5-10.2.6 Aylık / yıllık toggle

Aylık / yıllık toggle ileride UI davranışı olarak uygulanabilir.

Bu adımda karar yüzeyi hazırlanır.

Durum:

DONE ✅

### 5-10.2.7 KDV notu

Pricing yüzeyinde fiyatların KDV hariç olduğu not edilir.

Durum:

DONE ✅

### 5-10.2.8 Public fiyat yayın kararı

Bu adımda oluşturulan HTML public launch değil, FAZ 5 karar kanıtıdır.

Durum:

DONE ✅

## 6. 5-10.3 Developer Surface

### 5-10.3 Developer surface

Developer surface, ileride public API ve entegrasyon ekosistemi için dış geliştirici giriş yüzeyidir.

Durum:

DONE ✅

### 5-10.3.1 Developer docs landing

Developer docs landing, API, sandbox, webhook ve quota başlıklarını gösterir.

Durum:

DONE ✅

### 5-10.3.2 API docs taslak

API docs taslak, ileride endpoint dokümanlarına bağlanacak yüzeydir.

Durum:

DONE ✅

### 5-10.3.3 Sandbox açıklaması

Sandbox açıklaması geliştiricilerin test ortamında deneme yapacağını belirtir.

Durum:

DONE ✅

### 5-10.3.4 API key yönetim scope

API key yönetimi ileride panel üzerinden sağlanacak scope olarak tanımlanır.

Durum:

DONE ✅

### 5-10.3.5 Rate limit / quota açıklaması

Rate limit ve quota bilgisi paket ve entitlement kararlarına bağlıdır.

Durum:

DONE ✅

### 5-10.3.6 Webhook docs scope

Webhook docs ileride entegrasyon olaylarını dış sistemlere göndermek için planlanır.

Durum:

DONE ✅

## 7. 5-10.4 Web Dosyaları

### 5-10.4 Web dosyaları

Public pricing ve developer yüzeyleri için statik HTML kanıt dosyaları oluşturulur.

Durum:

DONE ✅

### 5-10.4.1 Public pricing HTML

Public pricing HTML dosyası oluşturulur.

Dosya:

web/faz5/pricing/index.html

Durum:

DONE ✅

### 5-10.4.2 Developer landing HTML

Developer landing HTML dosyası oluşturulur.

Dosya:

web/faz5/developer/index.html

Durum:

DONE ✅

### 5-10.4.3 Nginx / static route hazırlığı

Bu adımda Nginx route değiştirilmez; sadece static route'a hazır dosya yapısı oluşturulur.

Durum:

DONE ✅

### 5-10.4.4 Mobile responsive kontrol

HTML dosyalarında viewport ve responsive CSS marker bulunmalıdır.

Durum:

DONE ✅

### 5-10.4.5 İçerik match kontrolü

Test scripti pricing ve developer HTML içeriklerini kontrol eder.

Durum:

DONE ✅

## 8. 5-10.5 Test / Mühür

### 5-10.5 Test / mühür

Bu adım test scripti ve rapor ile doğrulanır.

Durum:

DONE ✅

### 5-10.5.1 Public pricing UI test

Pricing HTML içeriği test edilir.

Durum:

DONE ✅

### 5-10.5.2 Developer surface test

Developer HTML içeriği test edilir.

Durum:

DONE ✅

### 5-10.5.3 HTML content test

HTML dosyalarında gerekli ticari içerikler aranır.

Durum:

DONE ✅

### 5-10.5.4 Responsive marker test

HTML dosyalarında viewport ve media query marker kontrol edilir.

Durum:

DONE ✅

### 5-10.5.5 Report üretimi

Report dosyası üretilecektir.

Durum:

DONE ✅

### 5-10.5.6 5-11 geçiş izni

Test başarılı olursa 5-11 için geçiş izni verilir.

Durum:

DONE ✅

## 9. Kapsam Dışı

Bu adımda aşağıdakiler yapılmaz:

- Production public launch
- Nginx route değişikliği
- Canlı demo form backend
- Canlı ödeme linki
- Gerçek API key üretimi
- Gerçek developer portal login
- Gerçek webhook runtime
- SEO final yayını

Bu işler ileride ilgili public, developer ve production rollout adımlarında ele alınacaktır.

## 10. Oluşturulan Web Dosyaları

- web/faz5/pricing/index.html
- web/faz5/developer/index.html

## 11. 5-10 Mühür

FAZ_5_10_TEST_STATUS=PASS
FAZ_5_10_PUBLIC_PRICING_DEVELOPER_STATUS=PASS
FAZ_5_10_PUBLIC_PRICING_DEVELOPER_SEAL_STATUS=SEALED
FAZ_5_11_READY=YES

## Not / Sonuç

[ buraya çıktı gelecek ]

## Evet / Hata

[ Evet / Hata ]
