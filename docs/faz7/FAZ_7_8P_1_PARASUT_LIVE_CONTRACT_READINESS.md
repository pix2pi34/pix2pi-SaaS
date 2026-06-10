# FAZ 7-8P.1 Paraşüt Live Contract / OAuth + API Contract Readiness

## Amaç

FAZ 7-8P.1, Paraşüt Connector Foundation tamamlandıktan sonra gerçek provider entegrasyonuna yaklaşmadan önce kurulması gereken live contract hazırlık katmanıdır.

Bu modül gerçek Paraşüt API çağrısı yapmaz. OAuth, token lifecycle, endpoint contract, rate limit, timeout, response/error mapping ve live handoff gate standartlarını hazırlar.

## Kapsam

### 7-8P.1.1 OAuth Credential Contract

- Tenant bazlı OAuth credential contract
- Client ID zorunluluğu
- Secret değerinin kendisi değil secret reference kullanımı
- Redirect URI zorunluluğu
- Scope listesi zorunluluğu
- Webhook secret reference zorunluluğu
- Requested by / correlation zorunluluğu
- Real API enabled gate kapalı

### 7-8P.1.2 Token Lifecycle Contract

- Token reference modeli
- Access token ref / refresh token ref
- Issued at / expires at kontrolü
- Refresh window modeli
- ACTIVE / REFRESH_REQUIRED / EXPIRED / REVOKED statüleri

### 7-8P.1.3 Paraşüt API Endpoint Contract

- PULL_INVOICE endpoint contract
- PUSH_INVOICE endpoint contract
- SYNC_CUSTOMER endpoint contract
- SYNC_PRODUCT endpoint contract
- VERIFY_WEBHOOK endpoint contract
- HTTP method/path sözleşmesi
- Timeout policy
- Rate limit policy
- Real call enabled gate kapalı

### 7-8P.1.4 Provider Response / Error Mapping

- Unauthorized mapping
- Rate limit mapping
- Timeout mapping
- Validation error mapping
- Server error mapping
- Retryable / non-retryable ayrımı
- DLQ yönlendirme kararı

### 7-8P.1.5 Live Integration Safety Gate

- Legal approval guard
- Finance approval guard
- KVKK approval guard
- Secret management guard
- Rollback plan guard
- Provider contract guard
- Real API enabled kapalı olmadıkça block
- Production approval olmadan block

### 7-8P.1.6 Final Closure

- Docs readiness
- Config readiness
- Code readiness
- Tests readiness
- Real implementation audit readiness
- Paraşüt live contract readiness
- Real provider API status: CLOSED_UNTIL_APPROVALS_AND_PROVIDER_LIVE_MODULE

## Bilinçli sınır

Bu modül şunları yapmaz:

- Gerçek Paraşüt API çağrısı yapmaz
- Gerçek OAuth token almaz
- Gerçek refresh token yenilemez
- Gerçek müşteri/fatura verisi çekmez
- Production credential saklamaz
- Production entegrasyonu açmaz

Bunlar daha sonra provider live module içinde; hukuk, finans, KVKK, secret management, rollback ve provider sözleşme onaylarından sonra yapılacaktır.

## Final kapanış şartı

FAZ 7-8P.1 ancak aşağıdaki kontroller geçtiğinde PASS olur:

- Go testleri PASS
- OAuth credential contract mevcut
- Token lifecycle contract mevcut
- API endpoint contract mevcut
- Error mapping mevcut
- Live safety gate mevcut
- Config artifact mevcut
- Real implementation audit PASS
- Real provider API gate kapalı
