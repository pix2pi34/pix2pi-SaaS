# FAZ 7-8P.5 Paraşüt Token Exchange / Refresh Runtime Dry-Run Readiness

## Amaç

FAZ 7-8P.5, Paraşüt OAuth callback ile alınan authorization_code sonrasında çalışacak token exchange ve refresh runtime akışının dry-run/readiness katmanını kurar.

Bu modül gerçek Paraşüt token endpoint çağrısı yapmaz. Gerçek access token veya refresh token almaz. Token exchange request contract, simulated provider token response, token_ref storage, token lifecycle ve refresh rotation sözleşmesini hazırlar.

## Akış

1. Kullanıcı Paraşüt OAuth callback ile authorization_code getirir.
2. Sistem token exchange request contract oluşturur.
3. Real token exchange gate kapalı olduğu için canlı token endpoint çağrısı yapılmaz.
4. Simulated provider token response ile access_token_ref ve refresh_token_ref üretilir.
5. Token lifecycle oluşturulur.
6. Refresh required / expired / revoked guard çalışır.
7. Simulated refresh response ile token rotation test edilir.
8. Gerçek provider API kapalı kalır.

## Kapsam

### 7-8P.5.1 Token Exchange Request Contract

- Tenant ID zorunlu
- App key zorunlu
- Authorization code zorunlu
- Redirect URI zorunlu
- Client ID zorunlu
- Client secret ref zorunlu
- Correlation ID zorunlu
- Real token exchange disabled gate

### 7-8P.5.2 Simulated Token Response / Secret Ref Storage

- Simulated access token kabulü
- Simulated refresh token kabulü
- Access token secret_ref oluşturma
- Refresh token secret_ref oluşturma
- Token ref handoff contract
- Token lifecycle contract bridge
- Plaintext token DB’ye yazılmaz

### 7-8P.5.3 Refresh Readiness / Lifecycle Guard

- ACTIVE token refresh gerekmez
- REFRESH_REQUIRED token refresh adayıdır
- EXPIRED access token refresh adayıdır
- REVOKED token refresh edilemez
- Refresh token ref tenant-safe olmalıdır
- Real refresh endpoint kapalıdır

### 7-8P.5.4 Simulated Refresh Rotation

- Current access token ref rotate edilir
- Optional refresh token ref rotate edilir
- Eski token rotated status alır
- Yeni token active status alır
- Tenant-safe rotation guard
- Correlation zorunludur

### 7-8P.5.5 Token Endpoint Error Mapping

- Unauthorized non-retryable
- Timeout retryable
- Rate limit retryable
- Validation non-retryable
- Server error retryable
- Unknown provider error DLQ

### 7-8P.5.6 Final Closure

- Docs readiness
- Config readiness
- Code readiness
- Tests readiness
- Real implementation audit readiness
- Token exchange dry-run readiness
- Refresh runtime dry-run readiness
- Real provider API remains closed

## Bilinçli sınır

Bu modül şunları yapmaz:

- Gerçek Paraşüt token endpoint çağrısı yapmaz
- Gerçek authorization_code exchange etmez
- Gerçek access token almaz
- Gerçek refresh token almaz
- Gerçek Paraşüt API çağrısı yapmaz
- Production token resolver açmaz

Bu adım canlı provider token runtime öncesi dry-run/readiness katmanıdır.

## Final kapanış şartı

FAZ 7-8P.5 ancak aşağıdaki kontroller geçtiğinde PASS olur:

- Go testleri PASS
- Token exchange request contract mevcut
- Simulated token response storage mevcut
- Token ref handoff mevcut
- Token lifecycle bridge mevcut
- Refresh readiness guard mevcut
- Simulated refresh rotation mevcut
- Token endpoint error mapping mevcut
- Real implementation audit PASS
- Real provider API gate kapalı
