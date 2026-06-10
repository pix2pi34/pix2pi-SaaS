# FAZ 5-7 — Support / SLA / Incident / Escalation

## 1. Adım Kimliği

FAZ_NO=5
STEP_NO=5-7
STEP_NAME=Support / SLA / Incident / Escalation
STEP_TITLE=Destek, SLA, incident ve escalation operasyonu
STEP_STATUS=PASS
STEP_SEAL_STATUS=SEALED
FAZ_5_7_SUPPORT_SLA_STATUS=PASS
FAZ_5_7_SUPPORT_SLA_SEAL_STATUS=SEALED
FAZ_5_8_READY=YES

## 2. Giriş Şartı

Bu adımın başlayabilmesi için:

FAZ_5_6_TEST_STATUS=PASS ✅
FAZ_5_6_LEGAL_COMPLIANCE_STATUS=PASS ✅
FAZ_5_6_LEGAL_COMPLIANCE_SEAL_STATUS=SEALED ✅
FAZ_5_7_READY=YES ✅

## 3. Amaç

Bu adımın amacı Pix2pi için destek, SLA, incident ve escalation operasyon kurallarını tanımlamaktır.

Bu adımda gerçek ticket sistemi veya canlı çağrı merkezi kurulmaz.

Bu adımın hedefi:

- Destek kanallarını tanımlamak
- Paket bazlı SLA seviyelerini belirlemek
- Incident sınıflarını tanımlamak
- Escalation matrix oluşturmak
- Müşteri iletişim şablonlarını belirlemek
- Support / SLA JSON contract oluşturmak
- 5-8 Sales / Demo / CRM Operations adımına geçişi hazırlamak

## 4. 5-7.1 Destek Kanalları

### 5-7.1 Destek kanalları

Pix2pi destek kanalları paket ve müşteri türüne göre yönetilir.

Durum:

DONE ✅

### 5-7.1.1 E-posta destek

E-posta destek tüm paid paketler için temel destek kanalıdır.

Kurallar:

- Demo için best effort olabilir.
- Starter için standart destek kanalıdır.
- Pro için öncelikli cevap süresine bağlanabilir.
- Enterprise için SLA kapsamında izlenir.

Durum:

DONE ✅

### 5-7.1.2 WhatsApp / telefon destek kararı

WhatsApp veya telefon desteği başlangıçta sınırlı ve kontrollü verilir.

Kurallar:

- Starter için varsayılan kanal değildir.
- Pro için belirli saatlerde verilebilir.
- Enterprise için sözleşmeye bağlı olabilir.
- Muhasebeci paketi için operasyonel destek kanalı olabilir.

Durum:

DONE ✅

### 5-7.1.3 Panel içi destek talebi

Panel içi destek talebi ileride ticket sistemine bağlanacak ana kanaldır.

Kurallar:

- Tenant bilgisi otomatik taşınmalıdır.
- Kullanıcı bilgisi otomatik taşınmalıdır.
- Paket bilgisi otomatik taşınmalıdır.
- Incident sınıfı seçilebilir olmalıdır.

Durum:

DONE ✅

### 5-7.1.4 Enterprise özel kanal

Enterprise müşteriler için özel destek kanalı tanımlanabilir.

Örnek:

- Özel e-posta
- Özel WhatsApp/telefon
- SLA takip kanalı
- Belirlenmiş müşteri temsilcisi

Durum:

DONE ✅

### 5-7.1.5 Muhasebeci destek kanalı

Muhasebeci paketi için firma bazlı operasyon destek kanalı gerekir.

Kurallar:

- Firma erişim soruları
- Export sorunları
- TDHP çıktı sorunları
- Muhasebeci workspace erişim sorunları

Durum:

DONE ✅

## 5. 5-7.2 SLA Seviyeleri

### 5-7.2 SLA seviyeleri

SLA, paket seviyesine ve incident önemine göre uygulanır.

Durum:

DONE ✅

### 5-7.2.1 Demo SLA yok / best effort

Demo paket için garanti SLA verilmez.

Durum:

DONE ✅

### 5-7.2.2 Starter standart destek

Starter paket için standart destek uygulanır.

Kurallar:

- E-posta destek
- Standart cevap süresi
- Kritik olmayan talepler normal sıraya alınır

Durum:

DONE ✅

### 5-7.2.3 Pro öncelikli destek

Pro paket için öncelikli destek uygulanır.

Kurallar:

- Daha hızlı ilk cevap
- Ticari operasyon sorunlarında öncelik
- Reporting/export sorunlarında öncelik

Durum:

DONE ✅

### 5-7.2.4 Enterprise SLA

Enterprise için özel SLA uygulanır.

Kurallar:

- Sözleşmeye bağlı cevap süresi
- Sözleşmeye bağlı çözüm hedefi
- Özel escalation
- P0/P1 öncelikli müdahale

Durum:

DONE ✅

### 5-7.2.5 Muhasebeci operasyon desteği

Muhasebeci paketi için firma bazlı operasyon desteği uygulanır.

Kurallar:

- Firma erişim desteği
- Export desteği
- TDHP rapor desteği
- Çok firmalı workspace desteği

Durum:

DONE ✅

## 6. 5-7.3 Incident Sınıfları

### 5-7.3 Incident sınıfları

Incident sınıfları destek önceliğini ve escalation yolunu belirler.

Durum:

DONE ✅

### 5-7.3.1 P0 kritik sistem kesintisi

P0 tüm sistemi veya çok sayıda tenantı etkileyen kritik kesintidir.

Örnek:

- Sisteme erişilemiyor
- Gateway tamamen down
- Veritabanı erişimi yok
- Auth sistemi çalışmıyor

Durum:

DONE ✅

### 5-7.3.2 P1 finansal / veri riski

P1 finansal kayıt, veri bütünlüğü veya tenant izolasyonu riskidir.

Örnek:

- Yanlış muhasebe kaydı
- Veri kaybı riski
- Cross-tenant veri sızıntısı
- Kritik export hatası

Durum:

DONE ✅

### 5-7.3.3 P2 iş akışı bozulması

P2 müşteri operasyonunu etkileyen ama tüm sistemi durdurmayan sorundur.

Örnek:

- POS işlem hatası
- Stok güncelleme sorunu
- Rapor üretim hatası
- Entegrasyon gecikmesi

Durum:

DONE ✅

### 5-7.3.4 P3 düşük öncelikli hata

P3 düşük etkili hata veya küçük kullanım sorunudur.

Örnek:

- UI metin hatası
- Küçük görsel problem
- Düşük etkili validasyon hatası

Durum:

DONE ✅

### 5-7.3.5 P4 soru / istek

P4 müşteri sorusu, özellik isteği veya eğitim talebidir.

Durum:

DONE ✅

## 7. 5-7.4 Escalation Matrix

### 5-7.4 Escalation matrix

Escalation matrix destek talebinin hangi seviyeye taşınacağını belirler.

Durum:

DONE ✅

### 5-7.4.1 İlk triage

İlk triage destek talebinin sınıflandırılmasıdır.

Kontrol:

- Tenant bilgisi
- Kullanıcı bilgisi
- Paket bilgisi
- Incident seviyesi
- Etki alanı

Durum:

DONE ✅

### 5-7.4.2 Teknik inceleme

Teknik inceleme geliştirici veya teknik operasyon seviyesine taşınan incelemedir.

Durum:

DONE ✅

### 5-7.4.3 Güvenlik escalation

Güvenlik riski varsa talep güvenlik escalation seviyesine çıkarılır.

Örnek:

- Auth bypass
- Tenant izolasyon riski
- Secret sızıntısı
- Şüpheli erişim

Durum:

DONE ✅

### 5-7.4.4 Finansal escalation

Finansal kayıt, fatura, ödeme, muhasebe veya TDHP etkisi varsa finansal escalation yapılır.

Durum:

DONE ✅

### 5-7.4.5 Müşteri bilgilendirme

Müşteri bilgilendirme süreci incident durumuna göre yürütülür.

Kurallar:

- P0/P1 için hızlı bilgilendirme
- Durum güncellemesi
- Çözüm sonrası kapanış bildirimi
- Gerekiyorsa postmortem

Durum:

DONE ✅

### 5-7.4.6 Kapanış ve postmortem

Incident kapandığında root cause ve tekrar önleme notu tutulur.

Durum:

DONE ✅

## 8. 5-7.5 Destek Şablonları

### 5-7.5 Destek şablonları

Müşteri iletişiminde standart şablonlar kullanılmalıdır.

Durum:

DONE ✅

### 5-7.5.1 Talep alındı mesajı

Destek talebi alındığında müşteriye talebin alındığı bildirilir.

Durum:

DONE ✅

### 5-7.5.2 Kesinti bildirimi

P0/P1 kesintilerde müşteriye durum bildirimi yapılır.

Durum:

DONE ✅

### 5-7.5.3 Çözüm bildirimi

Sorun çözüldüğünde müşteriye çözüm bildirimi yapılır.

Durum:

DONE ✅

### 5-7.5.4 Planlı bakım bildirimi

Planlı bakım öncesi müşteriye zaman ve etki bilgisi verilir.

Durum:

DONE ✅

### 5-7.5.5 Gecikme bildirimi

SLA veya çözüm süresi gecikirse müşteriye gecikme bildirimi yapılır.

Durum:

DONE ✅

## 9. 5-7.6 Test / Mühür

### 5-7.6 Test / mühür

Bu adım test scripti ve rapor ile doğrulanır.

Durum:

DONE ✅

### 5-7.6.1 Support doc test

Doküman test edilecektir.

Durum:

DONE ✅

### 5-7.6.2 SLA JSON test

SLA JSON contract test edilecektir.

Durum:

DONE ✅

### 5-7.6.3 Incident class test

Incident class catalog test edilecektir.

Durum:

DONE ✅

### 5-7.6.4 Escalation matrix test

Escalation matrix test edilecektir.

Durum:

DONE ✅

### 5-7.6.5 Report üretimi

Report dosyası üretilecektir.

Durum:

DONE ✅

### 5-7.6.6 5-8 geçiş izni

Test başarılı olursa 5-8 için geçiş izni verilir.

Durum:

DONE ✅

## 10. Kapsam Dışı

Bu adımda aşağıdakiler yapılmaz:

- Gerçek ticket sistemi kurulumu
- Canlı çağrı merkezi kurulumu
- Runtime incident dashboard
- Gerçek status page yayını
- Otomatik SLA timer worker
- Otomatik müşteri bildirim servisi
- Gerçek postmortem portalı

Bu işler ileride ilgili ticari ve operasyonel fazlarda ele alınacaktır.

## 11. 5-7 Mühür

FAZ_5_7_TEST_STATUS=PASS
FAZ_5_7_SUPPORT_SLA_STATUS=PASS
FAZ_5_7_SUPPORT_SLA_SEAL_STATUS=SEALED
FAZ_5_8_READY=YES

## Not / Sonuç

[ buraya çıktı gelecek ]

## Evet / Hata

[ Evet / Hata ]
