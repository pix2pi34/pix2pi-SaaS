# FAZ 7-8P.4 Paraşüt OAuth Callback / Authorization Flow Readiness

## Amaç

FAZ 7-8P.4, Paraşüt entegrasyonunda kullanıcı "Paraşüt’e Bağlan" butonuna bastığında çalışacak OAuth authorization ve callback akışının contract/readiness katmanını kurar.

Bu modül gerçek Paraşüt API çağrısı yapmaz. Gerçek token exchange yapmaz. Authorization URL üretme, state/nonce güvenliği, callback doğrulama, authorization code intake ve token_ref handoff sözleşmesini hazırlar.

## Kullanıcı akışı

Panel → Ayarlar → Entegrasyonlar → Paraşüt → Bağlan / API Bilgileri

Kullanıcı "Paraşüt’e Bağlan" butonuna basar:

1. Sistem tenant ve role guard çalıştırır.
2. OAuth state üretilir.
3. Nonce üretilir / doğrulanır.
4. Authorization URL contract hazırlanır.
5. Kullanıcı Paraşüt authorization ekranına yönlendirilecek noktaya gelir.
6. Callback endpoint contract authorization code alır.
7. State / nonce / tenant doğrulanır.
8. Token exchange bu fazda dry-run blocked kalır.
9. Token ref handoff contract hazırlanır.

## Kapsam

### 7-8P.4.1 OAuth Connect Button / Surface Contract

- Paraşüt’e Bağlan button contract
- Panel path contract
- Callback path contract
- Allowed roles: TENANT_ADMIN, INTEGRATION_ADMIN
- Real token exchange disabled
- MFA önerisi

### 7-8P.4.2 Authorization URL Contract

- Client ID zorunlu
- Redirect URI zorunlu
- Scope listesi zorunlu
- State zorunlu
- Nonce zorunlu
- Tenant ID zorunlu
- Authorization URL query contract
- Production/live redirect gate kapalı

### 7-8P.4.3 Callback Intake Contract

- Authorization code intake
- Callback error intake
- Expected state validation
- Nonce validation
- Tenant guard
- Correlation guard
- Callback accepted status

### 7-8P.4.4 Token Exchange Dry-Run Gate

- Gerçek token exchange kapalı
- Provider live module açılmadan gerçek token alınmaz
- Real API approval olmadan token exchange reddedilir
- Dry-run blocked result
- Audit decision üretilir

### 7-8P.4.5 Token Ref Handoff Contract

- Access token ref contract
- Refresh token ref contract
- Token refs tenant-safe olmalı
- Token lifecycle contract ile uyum
- Credential storage contract ile uyum

### 7-8P.4.6 Final Closure

- Docs readiness
- Config readiness
- Code readiness
- Tests readiness
- Real implementation audit readiness
- OAuth callback readiness
- Real provider API remains closed

## Bilinçli sınır

Bu modül şunları yapmaz:

- Gerçek Paraşüt OAuth redirect başlatmaz
- Gerçek token exchange yapmaz
- Gerçek access token almaz
- Gerçek refresh token almaz
- Gerçek Paraşüt API çağrısı yapmaz
- Production credential resolver açmaz

Bu adım OAuth akışının güvenli contract/readiness katmanıdır.

## Final kapanış şartı

FAZ 7-8P.4 ancak aşağıdaki kontroller geçtiğinde PASS olur:

- Go testleri PASS
- OAuth connect button contract mevcut
- Authorization URL contract mevcut
- Callback intake contract mevcut
- State/nonce guard mevcut
- Token exchange dry-run gate mevcut
- Token ref handoff contract mevcut
- Real implementation audit PASS
- Real provider API gate kapalı
