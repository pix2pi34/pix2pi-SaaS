# FAZ 5-8 — Sales / Demo / CRM Operations

## 1. Adım Kimliği

FAZ_NO=5
STEP_NO=5-8
STEP_NAME=Sales / Demo / CRM Operations
STEP_TITLE=Satış, demo ve CRM operasyonu
STEP_STATUS=PASS
STEP_SEAL_STATUS=SEALED
FAZ_5_8_SALES_DEMO_CRM_STATUS=PASS
FAZ_5_8_SALES_DEMO_CRM_SEAL_STATUS=SEALED
FAZ_5_9_READY=YES

## 2. Giriş Şartı

Bu adımın başlayabilmesi için:

FAZ_5_7_TEST_STATUS=PASS ✅
FAZ_5_7_SUPPORT_SLA_STATUS=PASS ✅
FAZ_5_7_SUPPORT_SLA_SEAL_STATUS=SEALED ✅
FAZ_5_8_READY=YES ✅

## 3. Amaç

Bu adımın amacı Pix2pi için satış, demo ve CRM operasyon kurallarını tanımlamaktır.

Bu adımda gerçek CRM uygulaması veya canlı satış paneli kurulmaz.

Bu adımın hedefi:

- Lead yönetim aşamalarını belirlemek
- Demo tenant akışını netleştirmek
- Teklif operasyon kurallarını tanımlamak
- Satış kapanış akışını tanımlamak
- CRM JSON contract oluşturmak
- 5-9 Revenue Metrics / MRR / ARR / Churn adımına geçişi hazırlamak

## 4. 5-8.1 Lead Yönetimi

### 5-8.1 Lead yönetimi

Lead yönetimi, potansiyel müşterinin ilk temasından satış kapanışına kadar takip edilmesidir.

Durum:

DONE ✅

### 5-8.1.1 Lead created

Lead created, potansiyel müşteri ilk kez sisteme girdiğinde oluşan aşamadır.

Kaynaklar:

- Web form
- Telefon / WhatsApp
- Referans
- Pilot işletme
- Muhasebeci yönlendirmesi
- Saha satış

Durum:

DONE ✅

### 5-8.1.2 Lead qualified

Lead qualified, müşteri adayının Pix2pi için uygun olduğunun doğrulanmasıdır.

Kontrol alanları:

- İşletme tipi
- Şube sayısı
- Kullanıcı sayısı
- POS ihtiyacı
- ERP ihtiyacı
- Muhasebeci ihtiyacı
- Paket potansiyeli

Durum:

DONE ✅

### 5-8.1.3 Demo scheduled

Demo scheduled, müşteri adayına ürün demosu planlanmasıdır.

Kurallar:

- Demo tarihi belirlenir.
- Demo paketi belirlenir.
- Demo verisi hazırlanır.
- Müşteri ihtiyacı not edilir.

Durum:

DONE ✅

### 5-8.1.4 Proposal sent

Proposal sent, müşteriye ticari teklif gönderildiği aşamadır.

Kurallar:

- Paket belirtilir.
- Fiyat belirtilir.
- KDV notu belirtilir.
- Geçerlilik süresi belirtilir.
- Özel şartlar varsa not edilir.

Durum:

DONE ✅

### 5-8.1.5 Negotiation

Negotiation, müşterinin fiyat, paket, destek, entegrasyon veya sözleşme üzerinden görüşme yaptığı aşamadır.

Durum:

DONE ✅

### 5-8.1.6 Won

Won, satışın kazanıldığı aşamadır.

Sonraki adımlar:

- Subscription başlatılır.
- Tenant açılır.
- İlk ödeme veya manuel onay alınır.
- Onboarding başlatılır.
- Support kanalına alınır.

Durum:

DONE ✅

### 5-8.1.7 Lost

Lost, satışın kaybedildiği aşamadır.

Kayıp sebebi tutulmalıdır:

- Fiyat
- Özellik eksikliği
- Zamanlama
- Rakip ürün
- Müşteri vazgeçti
- Uygun değil

Durum:

DONE ✅

## 5. 5-8.2 Demo Tenant Akışı

### 5-8.2 Demo tenant akışı

Demo tenant akışı, müşteri adayına kontrollü ürün denemesi sağlamak için kullanılır.

Durum:

DONE ✅

### 5-8.2.1 Demo başvuru

Demo başvuru web, telefon, saha satış veya referans kanalıyla alınabilir.

Durum:

DONE ✅

### 5-8.2.2 Demo tenant oluşturma

Demo tenant oluşturulurken demo paket ve trial limitleri uygulanır.

Kurallar:

- package_code: demo
- trial_days: 14
- live_financial_operation: false
- api_access: disabled
- export_access: disabled

Durum:

DONE ✅

### 5-8.2.3 Demo kullanıcı daveti

Demo kullanıcı daveti müşteri adayının ürüne girişini sağlar.

Kurallar:

- En fazla 2 kullanıcı
- Owner bilgisi alınır
- Demo erişim süresi belirtilir

Durum:

DONE ✅

### 5-8.2.4 Demo veri seti

Demo tenant için örnek veri seti kullanılabilir.

Örnek:

- Test ürünleri
- Test müşterileri
- Test stok hareketleri
- Test POS satışları
- Test raporları

Durum:

DONE ✅

### 5-8.2.5 Demo süre takibi

Demo süresi takip edilir.

Kurallar:

- Başlangıç tarihi tutulur.
- Bitiş tarihi tutulur.
- Süre dolmadan önce müşteri bilgilendirilir.
- Süre sonunda paid dönüşüm veya erişim kısıtı uygulanır.

Durum:

DONE ✅

### 5-8.2.6 Demo → paid dönüşüm

Demo başarılı olursa müşteri paid pakete geçirilir.

Dönüşüm seçenekleri:

- Demo → Starter
- Demo → Pro
- Demo → Enterprise
- Demo → Accountant

Durum:

DONE ✅

## 6. 5-8.3 Teklif Operasyonu

### 5-8.3 Teklif operasyonu

Teklif operasyonu müşteri adayına fiyat ve kapsam sunma sürecidir.

Durum:

DONE ✅

### 5-8.3.1 Starter teklif

Starter teklif küçük işletme için hazırlanır.

İçerik:

- Aylık fiyat
- Yıllık fiyat
- 1 şube
- 3 kullanıcı
- Temel ERP/POS
- Standart destek

Durum:

DONE ✅

### 5-8.3.2 Pro teklif

Pro teklif büyüyen işletme için hazırlanır.

İçerik:

- Aylık fiyat
- Yıllık fiyat
- 3 şube
- 10 kullanıcı
- Gelişmiş rapor
- Export
- Marketplace discovery
- Paraşüt discovery
- Öncelikli destek

Durum:

DONE ✅

### 5-8.3.3 Enterprise teklif

Enterprise teklif özel sözleşme ile hazırlanır.

İçerik:

- Özel fiyat
- Özel SLA
- Özel entegrasyon
- Custom limits
- Enterprise onboarding
- Sözleşme şartları

Durum:

DONE ✅

### 5-8.3.4 Muhasebeci teklif

Muhasebeci teklif firma bazlı modelle hazırlanır.

İçerik:

- Workspace ücreti
- Dahil firma limiti
- Firma başı ek ücret
- Export hakları
- TDHP çıktı hakkı
- Muhasebeci support

Durum:

DONE ✅

### 5-8.3.5 İndirim kuralları

İndirim kuralları kontrollü tutulmalıdır.

Örnek:

- Yıllık ödeme indirimi
- Pilot müşteri indirimi
- Enterprise sözleşme indirimi
- Muhasebeci çok firma indirimi

Durum:

DONE ✅

### 5-8.3.6 Teklif geçerlilik süresi

Teklifin geçerlilik süresi olmalıdır.

Varsayılan:

- Standart teklif: 7 gün
- Enterprise teklif: 15 gün
- Muhasebeci teklif: 15 gün

Durum:

DONE ✅

## 7. 5-8.4 Satış Kapanış Akışı

### 5-8.4 Satış kapanış akışı

Satış kapanış akışı won durumundan tenant aktivasyonuna kadar olan süreci tanımlar.

Durum:

DONE ✅

### 5-8.4.1 Paket seçimi

Müşteri için uygun paket seçilir.

Seçenekler:

- starter
- pro
- enterprise
- accountant

Durum:

DONE ✅

### 5-8.4.2 Sözleşme / onay

Müşteriden gerekli sözleşme veya kullanım onayı alınır.

Durum:

DONE ✅

### 5-8.4.3 İlk ödeme

İlk ödeme veya manuel ticari onay alınır.

Durum:

DONE ✅

### 5-8.4.4 Tenant aktivasyonu

Tenant aktif hale getirilir.

Bağımlılıklar:

- Paket seçimi
- Subscription
- Entitlement
- Tenant owner
- İlk kullanıcı

Durum:

DONE ✅

### 5-8.4.5 Onboarding başlatma

Müşteri onboarding süreci başlatılır.

Örnek:

- Kullanıcı eğitimi
- Ürün/stok yükleme
- POS hazırlık
- ERP temel ayarlar
- Muhasebeci bağlantısı

Durum:

DONE ✅

### 5-8.4.6 Support kanalına alma

Müşteri pakete uygun destek kanalına alınır.

Durum:

DONE ✅

## 8. 5-8.5 CRM JSON Contract

### 5-8.5 CRM JSON contract

Satış ve demo operasyonu için makine okunabilir CRM contract oluşturulur.

Durum:

DONE ✅

### 5-8.5.1 Lead state catalog

Lead aşamaları kataloglanır.

Durum:

DONE ✅

### 5-8.5.2 Demo state catalog

Demo aşamaları kataloglanır.

Durum:

DONE ✅

### 5-8.5.3 Proposal state catalog

Teklif aşamaları kataloglanır.

Durum:

DONE ✅

### 5-8.5.4 Won / lost reason catalog

Satış kazanma ve kayıp sebepleri kataloglanır.

Durum:

DONE ✅

### 5-8.5.5 Sales handoff checklist

Satıştan operasyon ve support tarafına devir checklisti hazırlanır.

Durum:

DONE ✅

## 9. 5-8.6 Test / Mühür

### 5-8.6 Test / mühür

Bu adım test scripti ve rapor ile doğrulanır.

Durum:

DONE ✅

### 5-8.6.1 Sales doc test

Doküman test edilecektir.

Durum:

DONE ✅

### 5-8.6.2 CRM JSON test

CRM JSON contract test edilecektir.

Durum:

DONE ✅

### 5-8.6.3 Demo flow test

Demo flow test edilecektir.

Durum:

DONE ✅

### 5-8.6.4 Proposal flow test

Proposal flow test edilecektir.

Durum:

DONE ✅

### 5-8.6.5 Report üretimi

Report dosyası üretilecektir.

Durum:

DONE ✅

### 5-8.6.6 5-9 geçiş izni

Test başarılı olursa 5-9 için geçiş izni verilir.

Durum:

DONE ✅

## 10. Kapsam Dışı

Bu adımda aşağıdakiler yapılmaz:

- Gerçek CRM uygulaması kurulumu
- Gerçek satış pipeline dashboard
- Gerçek demo tenant runtime otomasyonu
- Gerçek teklif PDF üretimi
- Gerçek e-imza entegrasyonu
- Gerçek ödeme bağlantısı üretimi
- Gerçek lead form backend entegrasyonu

Bu işler ileride ilgili ticari ve operasyonel fazlarda ele alınacaktır.

## 11. 5-8 Mühür

FAZ_5_8_TEST_STATUS=PASS
FAZ_5_8_SALES_DEMO_CRM_STATUS=PASS
FAZ_5_8_SALES_DEMO_CRM_SEAL_STATUS=SEALED
FAZ_5_9_READY=YES

## Not / Sonuç

[ buraya çıktı gelecek ]

## Evet / Hata

[ Evet / Hata ]
