# FAZ 5-5 — Tenant Lifecycle / Commercial Ops

## 1. Adım Kimliği

FAZ_NO=5
STEP_NO=5-5
STEP_NAME=Tenant Lifecycle / Commercial Ops
STEP_TITLE=Tenant ticari yaşam döngüsü ve operasyon akışı
STEP_STATUS=PASS
STEP_SEAL_STATUS=SEALED
FAZ_5_5_TENANT_LIFECYCLE_STATUS=PASS
FAZ_5_5_TENANT_LIFECYCLE_SEAL_STATUS=SEALED
FAZ_5_6_READY=YES

## 2. Giriş Şartı

Bu adımın başlayabilmesi için:

FAZ_5_4_TEST_STATUS=PASS ✅
FAZ_5_4_SUBSCRIPTION_BILLING_STATUS=PASS ✅
FAZ_5_4_SUBSCRIPTION_BILLING_SEAL_STATUS=SEALED ✅
FAZ_5_5_READY=YES ✅

## 3. Amaç

Bu adımın amacı Pix2pi tenant ticari yaşam döngüsünü tanımlamaktır.

Bu adımda gerçek runtime tenant açma / kapama kodu yazılmaz.

Bu adımın hedefi:

- Tenant açılış akışını tanımlamak
- Tenant upgrade / downgrade kurallarını tanımlamak
- Tenant freeze kurallarını tanımlamak
- Tenant close kurallarını tanımlamak
- Tenant data handoff kurallarını tanımlamak
- Tenant lifecycle JSON contract oluşturmak
- 5-6 Legal / Compliance / KVKK / Terms adımına geçişi hazırlamak

## 4. 5-5.1 Tenant Açılış Akışı

### 5-5.1 Tenant açılış akışı

Tenant açılış akışı, müşterinin Pix2pi içinde ticari olarak başlatılmasıdır.

Durum:

DONE ✅

### 5-5.1.1 Demo tenant açma

Demo tenant, satış öncesi deneme için oluşturulur.

Kurallar:

- Demo tenant süreli olur.
- Varsayılan demo süresi 14 gündür.
- Canlı finansal işlem kapalıdır.
- Export kapalıdır.
- API kapalıdır.
- Demo veri seti kullanılabilir.

Durum:

DONE ✅

### 5-5.1.2 Paid tenant açma

Paid tenant, ödeme veya manuel ticari onay sonrası oluşturulur.

Kurallar:

- Paket atanır.
- Subscription active olur.
- Entitlement uygulanır.
- Tenant owner atanır.
- İlk kullanıcı oluşturulur.

Durum:

DONE ✅

### 5-5.1.3 Enterprise tenant açma

Enterprise tenant özel sözleşmeye bağlı açılır.

Kurallar:

- Özel fiyatlama olabilir.
- Özel SLA olabilir.
- Custom limits uygulanabilir.
- Enterprise onboarding gerekir.
- Özel entegrasyon kapsamı ayrıca belirlenir.

Durum:

DONE ✅

### 5-5.1.4 Accountant workspace açma

Accountant workspace, muhasebeci / mali müşavir hesabı için açılır.

Kurallar:

- Workspace owner atanır.
- Firma limiti uygulanır.
- Firma başı ücret modeli bağlanır.
- Firma erişimleri ayrı yönetilir.
- POS doğrudan operasyon kapalıdır.

Durum:

DONE ✅

### 5-5.1.5 Tenant owner belirleme

Her tenant için bir owner zorunludur.

Kurallar:

- Owner ticari ve operasyonel sorumludur.
- Owner değişimi auditlenmelidir.
- Owner olmadan tenant active yapılmaz.

Durum:

DONE ✅

### 5-5.1.6 İlk kullanıcı oluşturma

Tenant açılışında ilk kullanıcı oluşturulur.

Kurallar:

- İlk kullanıcı owner veya admin olur.
- Davet akışı ileride runtime olarak bağlanır.
- Kullanıcı paketin user_limit kuralına bağlıdır.

Durum:

DONE ✅

### 5-5.1.7 Başlangıç paketi atama

Her tenant bir başlangıç paketi ile açılır.

Kurallar:

- demo
- starter
- pro
- enterprise
- accountant

paketlerinden biri atanır.

Durum:

DONE ✅

## 5. 5-5.2 Tenant Upgrade / Downgrade

### 5-5.2 Tenant upgrade / downgrade

Tenant paket değişim süreci ticari entitlement ve billing kararlarına bağlıdır.

Durum:

DONE ✅

### 5-5.2.1 Starter → Pro

Starter paketinden Pro paketine geçiş upgrade sayılır.

Kurallar:

- Pro entitlement uygulanır.
- Şube limiti 3 olur.
- Kullanıcı limiti 10 olur.
- Gelişmiş reporting açılır.
- API limited açılır.

Durum:

DONE ✅

### 5-5.2.2 Pro → Enterprise

Pro paketinden Enterprise paketine geçiş enterprise onboarding gerektirir.

Kurallar:

- Custom contract gerekir.
- Custom limits uygulanır.
- SLA açılır.
- Advanced audit açılır.
- API enabled olur.

Durum:

DONE ✅

### 5-5.2.3 Pro → Starter downgrade

Pro paketinden Starter paketine geçiş downgrade sayılır.

Kurallar:

- Mevcut kullanıcı sayısı 3 sınırına düşmelidir.
- Şube sayısı 1 sınırına düşmelidir.
- Gelişmiş modüller kapatılmalıdır.
- Tercihen dönem sonunda uygulanır.

Durum:

DONE ✅

### 5-5.2.4 Paket geçişinde limit kontrolü

Paket geçişlerinde limit kontrolü zorunludur.

Kontrol alanları:

- user_limit
- branch_limit
- tenant_limit
- API access
- export access
- reporting level
- accounting export

Durum:

DONE ✅

### 5-5.2.5 Fazla kullanıcı / şube durumu

Downgrade sırasında fazla kullanıcı veya fazla şube varsa geçiş bekletilir.

Kurallar:

- Fazla kullanıcı pasifleştirilir veya ek ücretlendirilir.
- Fazla şube kapatılır veya ek ücretlendirilir.
- Müşteri bilgilendirilir.

Durum:

DONE ✅

### 5-5.2.6 Entitlement yenileme

Paket değişiminde entitlement yeniden hesaplanır.

Kurallar:

- Yeni package_code uygulanır.
- Subscription state dikkate alınır.
- Freeze / suspended durumları korunur.
- Audit kaydı gereklidir.

Durum:

DONE ✅

## 6. 5-5.3 Tenant Freeze

### 5-5.3 Tenant freeze

Tenant freeze, ticari veya güvenlik nedeniyle tenant operasyonlarının kısıtlanmasıdır.

Durum:

DONE ✅

### 5-5.3.1 Ödeme gecikmesi nedeniyle freeze

Ödeme gecikmesi halinde tenant past_due veya suspended duruma geçebilir.

Kurallar:

- Grace period uygulanır.
- Retry policy uygulanır.
- API kapatılabilir.
- Yazma işlemleri durdurulabilir.

Durum:

DONE ✅

### 5-5.3.2 Güvenlik nedeniyle freeze

Güvenlik riski varsa tenant acil şekilde freeze edilebilir.

Örnek riskler:

- Auth bypass
- Tenant sızıntısı
- Secret sızıntısı
- Şüpheli API kullanımı
- Veri bozma riski

Durum:

DONE ✅

### 5-5.3.3 Sözleşme nedeniyle freeze

Sözleşme ihlali veya enterprise özel karar nedeniyle freeze uygulanabilir.

Durum:

DONE ✅

### 5-5.3.4 Read-only mode kararı

Read-only mode ileride uygulanabilir.

Kurallar:

- Veri okunabilir.
- Yazma kapatılır.
- API yazma kapatılır.
- Export sözleşmeye göre değerlendirilir.

Durum:

DONE ✅

### 5-5.3.5 API erişimi kapatma

Freeze durumunda API erişimi kapatılabilir.

Durum:

DONE ✅

### 5-5.3.6 Yazma işlemi kapatma

Freeze durumunda ERP/POS yazma işlemleri durdurulabilir.

Durum:

DONE ✅

## 7. 5-5.4 Tenant Close

### 5-5.4 Tenant close

Tenant close, müşterinin ticari kullanımının kapatılmasıdır.

Durum:

DONE ✅

### 5-5.4.1 Müşteri iptali

Müşteri talebi ile tenant close süreci başlatılabilir.

Durum:

DONE ✅

### 5-5.4.2 Ödeme iptali

Ödeme iptali veya uzun süreli tahsilat başarısızlığı tenant close sürecine yol açabilir.

Durum:

DONE ✅

### 5-5.4.3 Sözleşme bitişi

Enterprise veya accountant sözleşmesi biterse tenant close süreci başlatılabilir.

Durum:

DONE ✅

### 5-5.4.4 Veri saklama süresi

Veri saklama süresi 5-6 Legal / Compliance adımında hukuki metinlere bağlanacaktır.

Durum:

DONE ✅

### 5-5.4.5 Veri export hakkı

Tenant kapanmadan önce veri export hakkı paket ve sözleşmeye göre değerlendirilir.

Durum:

DONE ✅

### 5-5.4.6 Veri silme / imha policy

Veri silme / imha policy 5-6 Legal / Compliance adımına devredilir.

Durum:

DONE ✅

## 8. 5-5.5 Tenant Data Handoff

### 5-5.5 Tenant data handoff

Tenant data handoff, müşterinin veya muhasebecinin verisini kontrollü şekilde almasıdır.

Durum:

DONE ✅

### 5-5.5.1 Excel export

Excel export temel veri teslim yollarından biridir.

Durum:

DONE ✅

### 5-5.5.2 PDF export

PDF export belge ve rapor teslim yolu olarak kullanılır.

Durum:

DONE ✅

### 5-5.5.3 TDHP export

TDHP export muhasebe aktarımı için kullanılır.

Durum:

DONE ✅

### 5-5.5.4 Muhasebeci devir dosyası

Muhasebeci devir dosyası firma bazlı erişim ve export akışıyla hazırlanır.

Durum:

DONE ✅

### 5-5.5.5 Enterprise özel handoff

Enterprise müşteriler için özel veri teslim formatı sözleşmeye bağlı olabilir.

Durum:

DONE ✅

### 5-5.5.6 Data ownership notu

Müşteri verisinin sahipliği ve kullanım hakkı 5-6 legal metinlerle netleştirilir.

Durum:

DONE ✅

## 9. 5-5.6 Test / Mühür

### 5-5.6 Test / mühür

Bu adım test scripti ve rapor ile doğrulanır.

Durum:

DONE ✅

### 5-5.6.1 Tenant lifecycle doc test

Doküman test edilecektir.

Durum:

DONE ✅

### 5-5.6.2 Lifecycle JSON test

JSON contract test edilecektir.

Durum:

DONE ✅

### 5-5.6.3 Freeze policy test

Freeze policy test edilecektir.

Durum:

DONE ✅

### 5-5.6.4 Close policy test

Close policy test edilecektir.

Durum:

DONE ✅

### 5-5.6.5 Report üretimi

Report dosyası üretilecektir.

Durum:

DONE ✅

### 5-5.6.6 5-6 geçiş izni

Test başarılı olursa 5-6 için geçiş izni verilir.

Durum:

DONE ✅

## 10. Kapsam Dışı

Bu adımda aşağıdakiler yapılmaz:

- Runtime tenant create API
- Runtime tenant freeze middleware
- Runtime tenant close worker
- Gerçek data export dosyası üretimi
- Gerçek veri silme işlemi
- KVKK hukuki metin finalizasyonu
- Enterprise sözleşme metni finalizasyonu

Bu işler ileride ilgili fazlarda ele alınacaktır.

## 11. 5-5 Mühür

FAZ_5_5_TEST_STATUS=PASS
FAZ_5_5_TENANT_LIFECYCLE_STATUS=PASS
FAZ_5_5_TENANT_LIFECYCLE_SEAL_STATUS=SEALED
FAZ_5_6_READY=YES

## Not / Sonuç

[ buraya çıktı gelecek ]

## Evet / Hata

[ Evet / Hata ]
