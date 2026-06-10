# FAZ 7-8P.3 Paraşüt Credential UI / Admin Integration Surface Readiness

## Amaç

FAZ 7-8P.3, Paraşüt API bilgilerinin Pix2pi panelinde hangi ekrandan ekleneceğini, hangi rollerin bu işlemi yapabileceğini, secret alanlarının nasıl saklanacağını ve kullanıcı aksiyonlarının backend contract karşılığını tanımlar.

Bu modül gerçek Paraşüt API çağrısı yapmaz. Kullanıcı arayüzü ve backend yüzeyi hazırlar.

## Kullanıcı API bilgisini nereden ekleyecek?

Kullanıcı API bilgisini şu yüzeyden ekler:

Panel → Ayarlar → Entegrasyonlar → Paraşüt → Bağlan / API Bilgileri

Bu ekranın amacı:

- Paraşüt entegrasyonunu tenant bazlı yönetmek
- API credential bilgilerini almak
- Secret değerlerini düz yazı saklamadan vault referansına çevirmek
- Kullanıcıya secret alanlarını maskeli göstermek
- Bağlantı testini bu fazda sadece dry-run olarak yapmak
- Gerçek provider API çağrısını kapalı tutmak

## Kapsam

### 7-8P.3.1 Admin Integration Surface Contract

- Panel path contract
- Paraşüt entegrasyon kartı
- Bağlan / API Bilgileri ekranı
- Yetkili roller: TENANT_ADMIN, INTEGRATION_ADMIN
- Yetkisiz rollerin reddi
- MFA önerisi

### 7-8P.3.2 Credential Form Contract

Form alanları:

- Client ID
- Client Secret
- Webhook Secret
- OAuth Callback URL gösterimi
- Entegrasyon durumu
- Kaydet
- Test Et
- Devre Dışı Bırak
- Secret Rotate Et

Kurallar:

- Client ID non-secret olarak saklanabilir
- Client Secret plaintext saklanmaz
- Webhook Secret plaintext saklanmaz
- Secret alanları UI tarafında maskelenir
- Boş secret submit reddedilir
- Correlation ID zorunlu

### 7-8P.3.3 Save Credential Action

- Kullanıcı ham secret girer
- Backend secret değerini vault contract'a gönderir
- DB/persistent contract tarafında sadece secret_ref saklanır
- Credential set oluşturulur
- Audit decision üretilir

### 7-8P.3.4 Test Connection Action

- Bu fazda gerçek Paraşüt API çağrısı yapılmaz
- Test action dry-run çalışır
- Config, role, tenant, secret_ref ve endpoint contract varlığı kontrol edilir
- Real API kapalı olduğu için live test sonucu BLOCKED_REAL_API_CLOSED döner
- Kullanıcıya "Canlı test için provider live module gerekir" mesajı verilir

### 7-8P.3.5 Disable / Rotate Action

- Disable action entegrasyonu pasif duruma alır
- Rotate action yeni secret_ref üretir
- Eski secret rotated status alır
- Tenant-safe rotation guard uygulanır
- Audit correlation zorunludur

### 7-8P.3.6 Final Closure

- Docs readiness
- Config readiness
- Code readiness
- Tests readiness
- Real implementation audit readiness
- Credential UI readiness
- Real API remains closed

## Bilinçli sınır

Bu modül şunları yapmaz:

- Gerçek HTML/CSS panel ekranı yayınlamaz
- Gerçek frontend route bağlamaz
- Gerçek Paraşüt API çağrısı yapmaz
- Gerçek OAuth connect başlatmaz
- Production secret resolver açmaz

Bu adım ürün yüzeyi ve backend contract hazırlığıdır.

## Final kapanış şartı

FAZ 7-8P.3 ancak aşağıdaki kontroller geçtiğinde PASS olur:

- Go testleri PASS
- Panel path contract mevcut
- Credential form contract mevcut
- Save credential action mevcut
- Test connection dry-run action mevcut
- Disable action mevcut
- Rotate action mevcut
- Secret masking mevcut
- Role guard mevcut
- Real implementation audit PASS
- Real provider API gate kapalı
