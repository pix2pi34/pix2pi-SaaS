# FAZ 5-9 — Revenue Metrics / MRR / ARR / Churn

## 1. Adım Kimliği

FAZ_NO=5
STEP_NO=5-9
STEP_NAME=Revenue Metrics / MRR / ARR / Churn
STEP_TITLE=Gelir metrikleri, MRR, ARR ve churn operasyonu
STEP_STATUS=PASS
STEP_SEAL_STATUS=SEALED
FAZ_5_9_REVENUE_METRICS_STATUS=PASS
FAZ_5_9_REVENUE_METRICS_SEAL_STATUS=SEALED
FAZ_5_10_READY=YES

## 2. Giriş Şartı

Bu adımın başlayabilmesi için:

FAZ_5_8_TEST_STATUS=PASS ✅
FAZ_5_8_SALES_DEMO_CRM_STATUS=PASS ✅
FAZ_5_8_SALES_DEMO_CRM_SEAL_STATUS=SEALED ✅
FAZ_5_9_READY=YES ✅

## 3. Amaç

Bu adımın amacı Pix2pi için ticari gelir metriklerini tanımlamaktır.

Bu adımda gerçek dashboard veya canlı revenue analytics sistemi kurulmaz.

Bu adımın hedefi:

- Ana gelir metriklerini tanımlamak
- Paket bazlı metrikleri tanımlamak
- Tahsilat metriklerini tanımlamak
- Raporlama veri kaynaklarını belirlemek
- Revenue metrics JSON contract oluşturmak
- 5-10 Public / Pricing / Developer Surfaces adımına geçişi hazırlamak

## 4. 5-9.1 Ana Gelir Metrikleri

### 5-9.1 Ana gelir metrikleri

Ana gelir metrikleri Pix2pi ticari sağlığını izlemek için kullanılır.

Durum:

DONE ✅

### 5-9.1.1 MRR

MRR, aylık tekrar eden gelir metriğidir.

Kural:

- Active paid subscription gelirleri dahil edilir.
- Demo dahil edilmez.
- Cancelled tenant dahil edilmez.
- Enterprise custom contract normalize edilerek dahil edilir.
- Accountant firma bazlı gelir MRR içinde izlenir.

Durum:

DONE ✅

### 5-9.1.2 ARR

ARR, yıllık tekrar eden gelir metriğidir.

Kural:

- ARR = MRR x 12
- Yıllık ödemeler aylık normalize edilir.
- Enterprise sözleşmeler aylık karşılığa çevrilir.

Durum:

DONE ✅

### 5-9.1.3 Churn

Churn, müşteri veya gelir kaybını ölçer.

Türler:

- Logo churn
- Revenue churn
- Package downgrade churn
- Accountant company churn

Durum:

DONE ✅

### 5-9.1.4 Expansion revenue

Expansion revenue mevcut müşteriden gelen ek gelirdir.

Örnek:

- Ek kullanıcı
- Ek şube
- Starter → Pro
- Pro → Enterprise
- Ek firma
- API kota artırımı
- Premium destek

Durum:

DONE ✅

### 5-9.1.5 Contraction revenue

Contraction revenue mevcut müşteride gelir azalmasıdır.

Örnek:

- Paket downgrade
- Kullanıcı azaltma
- Şube azaltma
- Firma sayısı azaltma
- Modül kapatma

Durum:

DONE ✅

### 5-9.1.6 Net revenue retention

Net revenue retention mevcut müşteri gelirinin expansion ve contraction sonrası durumunu ölçer.

Durum:

DONE ✅

### 5-9.1.7 Gross revenue retention

Gross revenue retention mevcut müşteri gelirinin expansion hariç korunma oranını ölçer.

Durum:

DONE ✅

## 5. 5-9.2 Paket Bazlı Metrikler

### 5-9.2 Paket bazlı metrikler

Paket bazlı metrikler hangi ürün ailesinin nasıl büyüdüğünü gösterir.

Durum:

DONE ✅

### 5-9.2.1 Demo sayısı

Demo tenant sayısı satış hunisinin başlangıç göstergesidir.

Durum:

DONE ✅

### 5-9.2.2 Starter müşteri sayısı

Starter müşteri sayısı küçük işletme giriş kanalını gösterir.

Durum:

DONE ✅

### 5-9.2.3 Pro müşteri sayısı

Pro müşteri sayısı ana büyüme paketinin sağlığını gösterir.

Durum:

DONE ✅

### 5-9.2.4 Enterprise müşteri sayısı

Enterprise müşteri sayısı kurumsal satış başarısını gösterir.

Durum:

DONE ✅

### 5-9.2.5 Muhasebeci workspace sayısı

Muhasebeci workspace sayısı muhasebeci kanalının büyüklüğünü gösterir.

Durum:

DONE ✅

### 5-9.2.6 Firma başı gelir

Firma başı gelir, muhasebeci paketindeki şirket bazlı geliri gösterir.

Durum:

DONE ✅

## 6. 5-9.3 Tahsilat Metrikleri

### 5-9.3 Tahsilat metrikleri

Tahsilat metrikleri ödeme operasyonunun sağlığını gösterir.

Durum:

DONE ✅

### 5-9.3.1 Başarılı ödeme oranı

Başarılı ödeme oranı paid invoice oranını gösterir.

Durum:

DONE ✅

### 5-9.3.2 Başarısız ödeme oranı

Başarısız ödeme oranı failed payment oranını gösterir.

Durum:

DONE ✅

### 5-9.3.3 Past due müşteri sayısı

Past due müşteri sayısı ödeme gecikmesi yaşayan tenant sayısını gösterir.

Durum:

DONE ✅

### 5-9.3.4 Suspended tenant sayısı

Suspended tenant sayısı erişimi kısıtlanmış ticari hesapları gösterir.

Durum:

DONE ✅

### 5-9.3.5 İptal oranı

İptal oranı cancelled subscription oranını gösterir.

Durum:

DONE ✅

### 5-9.3.6 Ortalama gelir / tenant

Ortalama gelir / tenant müşteri başına ortalama geliri gösterir.

Durum:

DONE ✅

## 7. 5-9.4 Raporlama Kaynakları

### 5-9.4 Raporlama kaynakları

Revenue metrics farklı ticari veri kaynaklarından beslenir.

Durum:

DONE ✅

### 5-9.4.1 Subscription data

Subscription data abonelik durumlarını ve paketleri sağlar.

Durum:

DONE ✅

### 5-9.4.2 Billing data

Billing data invoice, payment ve tahsilat durumlarını sağlar.

Durum:

DONE ✅

### 5-9.4.3 Tenant lifecycle data

Tenant lifecycle data tenant durumlarını ve ticari yaşam döngüsünü sağlar.

Durum:

DONE ✅

### 5-9.4.4 Sales CRM data

Sales CRM data lead, demo, teklif, won/lost ve satış hunisi bilgisini sağlar.

Durum:

DONE ✅

### 5-9.4.5 Support churn sinyalleri

Support churn sinyalleri müşteri memnuniyeti ve kayıp riskini gösterir.

Durum:

DONE ✅

## 8. 5-9.5 Revenue JSON Contract

### 5-9.5 Revenue JSON contract

Gelir metrikleri için makine okunabilir contract oluşturulur.

Durum:

DONE ✅

### 5-9.5.1 Metric catalog

Metric catalog gelir metriklerini listeler.

Durum:

DONE ✅

### 5-9.5.2 Formula catalog

Formula catalog metriklerin nasıl hesaplanacağını tanımlar.

Durum:

DONE ✅

### 5-9.5.3 Data source mapping

Data source mapping metriklerin hangi verilerden besleneceğini tanımlar.

Durum:

DONE ✅

### 5-9.5.4 Dashboard readiness

Dashboard readiness ileride revenue dashboard için gerekli alanları tanımlar.

Durum:

DONE ✅

### 5-9.5.5 Alert threshold readiness

Alert threshold readiness ileride ticari alarm eşikleri için hazırlık sağlar.

Durum:

DONE ✅

## 9. 5-9.6 Test / Mühür

### 5-9.6 Test / mühür

Bu adım test scripti ve rapor ile doğrulanır.

Durum:

DONE ✅

### 5-9.6.1 Revenue doc test

Doküman test edilecektir.

Durum:

DONE ✅

### 5-9.6.2 Metrics JSON test

Metrics JSON contract test edilecektir.

Durum:

DONE ✅

### 5-9.6.3 Formula test

Formula catalog test edilecektir.

Durum:

DONE ✅

### 5-9.6.4 Dashboard source test

Dashboard source mapping test edilecektir.

Durum:

DONE ✅

### 5-9.6.5 Report üretimi

Report dosyası üretilecektir.

Durum:

DONE ✅

### 5-9.6.6 5-10 geçiş izni

Test başarılı olursa 5-10 için geçiş izni verilir.

Durum:

DONE ✅

## 10. Kapsam Dışı

Bu adımda aşağıdakiler yapılmaz:

- Gerçek revenue dashboard
- Gerçek BI sistemi
- Gerçek ödeme sağlayıcı raporu
- Gerçek muhasebe mutabakatı
- Runtime MRR hesaplama worker
- Otomatik churn prediction
- Canlı ticari alarm sistemi

Bu işler ileride ilgili ticari, reporting ve observability fazlarında ele alınacaktır.

## 11. 5-9 Mühür

FAZ_5_9_TEST_STATUS=PASS
FAZ_5_9_REVENUE_METRICS_STATUS=PASS
FAZ_5_9_REVENUE_METRICS_SEAL_STATUS=SEALED
FAZ_5_10_READY=YES

## Not / Sonuç

[ buraya çıktı gelecek ]

## Evet / Hata

[ Evet / Hata ]
