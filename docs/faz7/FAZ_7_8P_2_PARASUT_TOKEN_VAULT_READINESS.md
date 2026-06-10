# FAZ 7-8P.2 Paraşüt Token Vault / Secret Reference / Credential Storage Readiness

## Amaç

FAZ 7-8P.2, Paraşüt entegrasyonunda kullanıcı tarafından girilecek API / OAuth / webhook gizli bilgilerinin güvenli şekilde saklanması için secret reference ve credential storage hazırlık katmanını kurar.

Bu modül gerçek Paraşüt API çağrısı yapmaz. Ham secret değerleri normal application DB içinde plaintext tutulmaz. Runtime ve credential storage tarafında sadece secret_ref modeli kullanılır.

## Kullanıcı API bilgisini nereden ekleyecek?

Kullanıcı API bilgisini Pix2pi panelinde şu yüzeyden ekler:

Panel → Ayarlar → Entegrasyonlar → Paraşüt → Bağlan / API Bilgileri

Bu ekran sadece yetkili kullanıcılar için açık olur:

- TENANT_ADMIN
- INTEGRATION_ADMIN

UI alanları:

- Client ID
- Client Secret
- Webhook Secret
- OAuth bağlan butonu
- Bağlantıyı kaydet
- Bağlantıyı test et
- Devre dışı bırak
- Secret rotate et

Güvenlik kuralı:

Kullanıcı ham secret değerini forma girer. Backend bu değeri alır, vault içine yazar ve uygulama DB tarafında sadece secret_ref saklar.

Örnek:

secret://pix2pi/tenant_7/parasut/client_secret/v1

## Kapsam

### 7-8P.2.1 Credential Entry Surface Contract

- Admin panel entegrasyon ekranı contract
- Tenant admin / integration admin rol guard
- MFA önerisi
- Secret plaintext never persisted kuralı
- API bilgisinin ekleneceği ürün yüzeyi

### 7-8P.2.2 Secret Reference Model

- Client secret ref
- Webhook secret ref
- Access token ref
- Refresh token ref
- Tenant-safe secret_ref formatı
- Provider key zorunluluğu
- Secret kind zorunluluğu
- Version modeli

### 7-8P.2.3 In-Memory Vault Contract Foundation

- Store secret
- Rotate secret
- Revoke secret
- Find secret reference
- Tenant-safe secret lookup
- Raw secret resolve real API kapalıyken reddedilir

### 7-8P.2.4 Credential Storage Contract

- Tenant credential set modeli
- Client ID plaintext olabilir
- Secret değerleri plaintext tutulmaz
- Client secret ref zorunlu
- Webhook secret ref zorunlu
- Access / refresh token ref opsiyonel ama ref olarak tutulur
- Credential status modeli

### 7-8P.2.5 Rotation / Revocation / Expiry Readiness

- Secret rotation modeli
- Eski secret rotated status
- Yeni secret active status
- Revoke guard
- Expiry metadata hazırlığı
- Audit correlation zorunluluğu

### 7-8P.2.6 Final Closure

- Docs readiness
- Config readiness
- Code readiness
- Tests readiness
- Real implementation audit readiness
- Real API remains closed
- Token vault readiness gate

## Bilinçli sınır

Bu modül şunları yapmaz:

- Gerçek HashiCorp Vault / cloud secret manager entegrasyonu yapmaz
- Gerçek Paraşüt API çağrısı yapmaz
- Gerçek OAuth token almaz
- Gerçek access token çözmez
- Production secret erişimini açmaz

Bu modül provider live integration öncesi güvenli secret reference sözleşmesini hazırlar.

## Final kapanış şartı

FAZ 7-8P.2 ancak aşağıdaki kontroller geçtiğinde PASS olur:

- Go testleri PASS
- Credential entry surface contract mevcut
- Secret reference model mevcut
- Vault contract foundation mevcut
- Credential storage contract mevcut
- Rotation/revocation guard mevcut
- Real implementation audit PASS
- Real provider API gate kapalı
