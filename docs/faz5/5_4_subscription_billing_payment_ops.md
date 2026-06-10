# FAZ 5-4 — Subscription / Billing / Payment Ops

## 1. Adım Kimliği

FAZ_NO=5
STEP_NO=5-4
STEP_NAME=Subscription / Billing / Payment Ops
STEP_TITLE=Abonelik, faturalama ve ödeme operasyonu
STEP_STATUS=PASS
STEP_SEAL_STATUS=SEALED
FAZ_5_4_SUBSCRIPTION_BILLING_STATUS=PASS
FAZ_5_4_SUBSCRIPTION_BILLING_SEAL_STATUS=SEALED
FAZ_5_5_READY=YES

## 2. Giriş Şartı

Bu adımın başlayabilmesi için:

FAZ_5_3_TEST_STATUS=PASS ✅
FAZ_5_3_ENTITLEMENT_MATRIX_STATUS=PASS ✅
FAZ_5_3_ENTITLEMENT_MATRIX_SEAL_STATUS=SEALED ✅
FAZ_5_4_READY=YES ✅

## 3. Amaç

Bu adımın amacı Pix2pi için abonelik, faturalama ve ödeme operasyon kurallarını netleştirmektir.

Bu adımda gerçek ödeme kuruluşu entegrasyonu yapılmaz.

Bu adımın hedefi:

- Subscription lifecycle tanımlamak
- Billing model tanımlamak
- Payment ops durumlarını tanımlamak
- Subscription durumlarının entitlement üzerindeki etkisini tanımlamak
- Billing JSON contract oluşturmak
- 5-5 Tenant Lifecycle / Commercial Ops adımına geçişi hazırlamak

## 4. 5-4.1 Subscription Lifecycle

### 5-4.1 Subscription lifecycle

Abonelik yaşam döngüsü Pix2pi ticari operasyonunun ana omurgasıdır.

Durum:

DONE ✅

### 5-4.1.1 Trial başlatma

Trial başlatma demo veya kontrollü deneme süreci için kullanılır.

Kurallar:

- Trial süresi paket veya kampanya kararına göre belirlenir.
- Demo için varsayılan trial süresi 14 gündür.
- Trial içinde canlı finansal işlem kapalı olabilir.
- Trial sonunda paid subscription akışına geçilir veya erişim kısıtlanır.

Durum:

DONE ✅

### 5-4.1.2 Abonelik başlatma

Paid subscription başlatıldığında:

- Tenant ticari olarak active olur.
- Paket atanır.
- Entitlement hakları uygulanır.
- Billing cycle başlatılır.
- İlk fatura/tahsilat kaydı üretilir veya manuel ödeme beklenir.

Durum:

DONE ✅

### 5-4.1.3 Abonelik yenileme

Abonelik yenileme aylık veya yıllık periyoda göre çalışır.

Kurallar:

- Yenileme tarihinde invoice oluşturulur.
- Tahsilat başarılıysa subscription active kalır.
- Tahsilat başarısızsa past_due durumuna geçilir.
- Grace period içinde tekrar ödeme denenebilir.

Durum:

DONE ✅

### 5-4.1.4 Paket upgrade

Upgrade daha yüksek pakete geçiştir.

Örnek:

- Starter → Pro
- Pro → Enterprise
- Accountant ekstra firma hakkı

Kurallar:

- Yeni entitlement hakları uygulanır.
- Fiyat farkı billing policy ile hesaplanır.
- Upgrade genelde anında aktif olur.

Durum:

DONE ✅

### 5-4.1.5 Paket downgrade

Downgrade daha düşük pakete geçiştir.

Örnek:

- Pro → Starter
- Enterprise → Pro

Kurallar:

- Mevcut kullanım yeni paketin limitlerini aşıyorsa downgrade beklemeye alınır.
- Fazla kullanıcı, fazla şube veya fazla modül kullanımı kapatılmadan downgrade tamamlanmaz.
- Downgrade tercihen dönem sonunda uygulanır.

Durum:

DONE ✅

### 5-4.1.6 Abonelik iptali

İptal durumunda:

- Subscription cancelled durumuna geçebilir.
- Tenant close veya read-only/data handoff süreci 5-5 içinde ele alınır.
- Veri saklama ve export hakları legal/commercial policy ile belirlenir.

Durum:

DONE ✅

### 5-4.1.7 Abonelik yeniden açma

Yeniden açma durumunda:

- Eski tenant korunuyorsa aynı tenant yeniden active yapılır.
- Yeni paket atanabilir.
- Past_due veya suspended durumundan active duruma dönüş yapılabilir.
- Ödeme veya manuel onay gerektirir.

Durum:

DONE ✅

### 5-4.1.8 Enterprise özel sözleşme durumu

Enterprise müşteriler için:

- Custom pricing uygulanabilir.
- Özel SLA uygulanabilir.
- Özel ödeme vadesi uygulanabilir.
- Enterprise hold durumu kullanılabilir.
- Sözleşmeye göre entitlement override yapılabilir.

Durum:

DONE ✅

## 5. 5-4.2 Billing Model

### 5-4.2 Billing model

Billing model Pix2pi paket, kullanıcı, şube ve firma bazlı ücretlendirme kurallarını tanımlar.

Durum:

DONE ✅

### 5-4.2.1 Aylık faturalama

Aylık faturalama standart ödeme modelidir.

Kurallar:

- Billing period aylık ilerler.
- Her ay invoice üretilir.
- Ödeme başarısız olursa past_due süreci başlar.

Durum:

DONE ✅

### 5-4.2.2 Yıllık faturalama

Yıllık faturalama teşvik edilen ödeme modelidir.

Kurallar:

- Yaklaşık 10 ay öde 12 ay kullan yaklaşımı uygulanır.
- Annual price catalog üzerinden okunur.
- Yıllık ödeme yapan tenant dönem boyunca active kalır.

Durum:

DONE ✅

### 5-4.2.3 Kullanıcı bazlı ek ücret

Paket limitinin üstündeki kullanıcılar için ek ücret uygulanabilir.

Durum:

DONE ✅

### 5-4.2.4 Şube bazlı ek ücret

Paket limitinin üstündeki şubeler için ek ücret uygulanabilir.

Durum:

DONE ✅

### 5-4.2.5 Firma bazlı muhasebeci ücretlendirme

Muhasebeci paketi için firma bazlı ücret modeli uygulanır.

Varsayılan:

- 10 firma dahil
- Firma başı aylık ek ücret: 149 TRY

Durum:

DONE ✅

### 5-4.2.6 Enterprise özel fiyatlama

Enterprise fiyatları public catalog ile sabitlenmez.

Kurallar:

- Özel teklif
- Özel sözleşme
- Özel SLA
- Özel ödeme vadesi
- Özel entegrasyon bedeli

Durum:

DONE ✅

### 5-4.2.7 KDV hariç / iç gösterim kararı

İç ticari catalog KDV hariç tutulur.

Public pricing sayfasında KDV notu açıkça gösterilecektir.

Durum:

DONE ✅

### 5-4.2.8 Fatura dönem başlangıç / bitiş kuralı

Billing period:

- start_at
- end_at
- due_at
- paid_at

alanlarıyla takip edilir.

Durum:

DONE ✅

## 6. 5-4.3 Payment Ops

### 5-4.3 Payment ops

Payment ops ödeme durumları, retry, grace period, askıya alma ve iptal davranışlarını tanımlar.

Durum:

DONE ✅

### 5-4.3.1 Ödeme başarılı akışı

Ödeme başarılı olduğunda:

- invoice paid olur.
- subscription active kalır.
- entitlement tam paket haklarına döner.
- tenant commercial status active olur.

Durum:

DONE ✅

### 5-4.3.2 Ödeme başarısız akışı

Ödeme başarısız olduğunda:

- invoice unpaid veya failed olur.
- subscription past_due durumuna geçebilir.
- retry policy devreye girer.
- müşteri bilgilendirme süreci başlar.

Durum:

DONE ✅

### 5-4.3.3 Retry / tekrar deneme politikası

Varsayılan retry policy:

- 1. deneme: ödeme günü
- 2. deneme: +3 gün
- 3. deneme: +7 gün
- Sonrası: suspended adayı

Durum:

DONE ✅

### 5-4.3.4 Grace period

Grace period müşteri erişimini hemen kesmemek için kullanılır.

Varsayılan:

- Starter: 3 gün
- Pro: 7 gün
- Enterprise: sözleşmeye bağlı
- Accountant: 7 gün

Durum:

DONE ✅

### 5-4.3.5 Past due durumu

Past due durumda:

- Login açık kalabilir.
- Yazma işlemleri kademeli kısıtlanabilir.
- API erişimi kapatılabilir.
- Müşteriye ödeme uyarısı gösterilir.

Durum:

DONE ✅

### 5-4.3.6 Suspended durumu

Suspended durumda:

- Ticari erişim kısıtlanır.
- Yazma işlemleri kapatılır.
- API erişimi kapatılır.
- Data handoff ve export politikası ayrıca değerlendirilir.

Durum:

DONE ✅

### 5-4.3.7 Cancelled durumu

Cancelled durumda:

- Ticari erişim kapatılır.
- Tenant close süreci 5-5 içinde ele alınır.
- Veri saklama ve imha süreci 5-6 legal policy ile bağlanır.

Durum:

DONE ✅

### 5-4.3.8 Manual payment / banka havale opsiyonu

İlk ticari dönemde manuel ödeme desteklenebilir.

Örnek:

- Banka havalesi
- Manuel onay
- Enterprise sözleşmeli ödeme
- Muhasebeci yıllık ödeme

Durum:

DONE ✅

### 5-4.3.9 İade / iptal politikası

İade ve iptal politikası:

- Public legal metinlere bağlanacaktır.
- Enterprise özel sözleşmeye bağlanabilir.
- Kullanılmamış dönem iadesi ayrı karar gerektirir.

Durum:

DONE ✅

## 7. 5-4.4 Subscription → Entitlement Etkisi

### 5-4.4 Subscription → entitlement etkisi

Subscription state değiştiğinde entitlement davranışı da değişir.

Durum:

DONE ✅

### 5-4.4.1 Active durumda tam paket hakları

active durumda paket hakları normal uygulanır.

Durum:

DONE ✅

### 5-4.4.2 Trialing durumda demo / trial limitleri

trialing durumda demo veya trial limitleri uygulanır.

Durum:

DONE ✅

### 5-4.4.3 Past due durumda yazma kısıtı

past_due durumda yazma işlemleri kademeli olarak kısıtlanabilir.

Durum:

DONE ✅

### 5-4.4.4 Suspended durumda erişim kısıtı

suspended durumda ticari erişim ve API erişimi kısıtlanır.

Durum:

DONE ✅

### 5-4.4.5 Cancelled durumda erişim kapatma

cancelled durumda ticari erişim kapatılır.

Durum:

DONE ✅

### 5-4.4.6 Enterprise hold özel kural

enterprise_hold durumunda sözleşmeye göre özel karar uygulanır.

Durum:

DONE ✅

## 8. 5-4.5 Billing JSON Contract

### 5-4.5 Billing JSON contract

Makine tarafından okunabilir subscription/billing contract oluşturulmuştur.

Durum:

DONE ✅

### 5-4.5.1 Subscription state catalog

Subscription state catalog oluşturulmuştur.

Durum:

DONE ✅

### 5-4.5.2 Billing cycle catalog

Billing cycle catalog oluşturulmuştur.

Durum:

DONE ✅

### 5-4.5.3 Payment state catalog

Payment state catalog oluşturulmuştur.

Durum:

DONE ✅

### 5-4.5.4 Grace period config

Grace period config oluşturulmuştur.

Durum:

DONE ✅

### 5-4.5.5 Retry policy config

Retry policy config oluşturulmuştur.

Durum:

DONE ✅

### 5-4.5.6 Package transition rules

Package transition rules oluşturulmuştur.

Durum:

DONE ✅

## 9. 5-4.6 Test / Mühür

### 5-4.6 Test / mühür

Bu adım test scripti ve rapor ile doğrulanır.

Durum:

DONE ✅

### 5-4.6.1 Subscription doc test

Doküman test edilecektir.

Durum:

DONE ✅

### 5-4.6.2 Billing JSON test

JSON contract test edilecektir.

Durum:

DONE ✅

### 5-4.6.3 Payment state test

Payment state catalog test edilecektir.

Durum:

DONE ✅

### 5-4.6.4 Entitlement dependency test

5-3 entitlement dependency test edilecektir.

Durum:

DONE ✅

### 5-4.6.5 Report üretimi

Report dosyası üretilecektir.

Durum:

DONE ✅

### 5-4.6.6 5-5 geçiş izni

Test başarılı olursa 5-5 için geçiş izni verilir.

Durum:

DONE ✅

## 10. Kapsam Dışı

Bu adımda aşağıdakiler yapılmaz:

- Gerçek ödeme kuruluşu entegrasyonu
- Sanal POS canlı bağlantısı
- Gerçek invoice PDF üretimi
- GİB/e-Belge entegrasyonu
- Runtime subscription middleware
- Tenant freeze runtime
- Banka mutabakat entegrasyonu

Bu işler ileride ilgili fazlarda ele alınacaktır.

## 11. 5-4 Mühür

FAZ_5_4_TEST_STATUS=PASS
FAZ_5_4_SUBSCRIPTION_BILLING_STATUS=PASS
FAZ_5_4_SUBSCRIPTION_BILLING_SEAL_STATUS=SEALED
FAZ_5_5_READY=YES

## Not / Sonuç

[ buraya çıktı gelecek ]

## Evet / Hata

[ Evet / Hata ]
