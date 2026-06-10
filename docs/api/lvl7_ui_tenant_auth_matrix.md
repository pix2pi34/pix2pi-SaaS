# LVL7 UI Tenant Auth Matrix

## Amaç
Bu dokuman ilk UI panelinin baglanacagi endpointlerde:
- auth zorunlu mu
- tenant context zorunlu mu
- role / permission gerekli mi
- tenant mismatch durumunda ne donulecek
sorularini sabitler.

---

## Ortak kurallar

- tum endpointler Authorization Bearer token ister
- auth yoksa 401 donulur
- token gecersizse 401 donulur
- token suresi bitmisse 401 donulur
- tenant bagli endpointte tenant context yoksa 403 donulur
- tenant mismatch varsa 403 donulur
- request_id her response ve error response icinde zorunludur

---

## Matrix

| Endpoint | Auth | Tenant Context | Minimum Role/Permission | Tenant Mismatch | Not |
|---|---|---|---|---|---|
| GET /api/v1/auth/me | zorunlu | token icinden gelir | login olmus kullanici | 401/403 yok, token bazli | app init |
| GET /api/v1/tenant/current | zorunlu | zorunlu | authenticated user | 403 TENANT_FORBIDDEN | tenant bar |
| GET /api/v1/dashboard/summary | zorunlu | zorunlu | dashboard.read | 403 TENANT_FORBIDDEN | ana dashboard |
| GET /api/v1/monitoring/warnings | zorunlu | zorunlu | monitoring.read | 403 TENANT_FORBIDDEN | ops warning widget |
| GET /api/v1/monitoring/alerts | zorunlu | zorunlu | monitoring.read | 403 TENANT_FORBIDDEN | ops/security alert listesi |
| GET /api/v1/erp/event-summary | zorunlu | zorunlu | erp.read veya dashboard.read | 403 TENANT_FORBIDDEN | erp/event ozet |
| GET /api/v1/health/summary | zorunlu | zorunlu | monitoring.read veya dashboard.read | 403 TENANT_FORBIDDEN | servis health widget |

---

## Endpoint bazli detay

### GET /api/v1/auth/me
- auth: zorunlu
- tenant context: token claim icinden gelir
- minimum permission: yok
- hata kodlari:
  - AUTH_UNAUTHORIZED
  - AUTH_INVALID_TOKEN
  - AUTH_TOKEN_EXPIRED

### GET /api/v1/tenant/current
- auth: zorunlu
- tenant context: zorunlu
- minimum permission: yok
- hata kodlari:
  - AUTH_UNAUTHORIZED
  - TENANT_NOT_FOUND
  - TENANT_FORBIDDEN

### GET /api/v1/dashboard/summary
- auth: zorunlu
- tenant context: zorunlu
- minimum permission:
  - dashboard.read
- hata kodlari:
  - AUTH_UNAUTHORIZED
  - PERMISSION_DENIED
  - TENANT_FORBIDDEN
  - RESOURCE_NOT_FOUND

### GET /api/v1/monitoring/warnings
- auth: zorunlu
- tenant context: zorunlu
- minimum permission:
  - monitoring.read
- hata kodlari:
  - AUTH_UNAUTHORIZED
  - PERMISSION_DENIED
  - TENANT_FORBIDDEN
  - INVALID_CURSOR

### GET /api/v1/monitoring/alerts
- auth: zorunlu
- tenant context: zorunlu
- minimum permission:
  - monitoring.read
- hata kodlari:
  - AUTH_UNAUTHORIZED
  - PERMISSION_DENIED
  - TENANT_FORBIDDEN
  - INVALID_CURSOR

### GET /api/v1/erp/event-summary
- auth: zorunlu
- tenant context: zorunlu
- minimum permission:
  - erp.read
  - dashboard.read
- hata kodlari:
  - AUTH_UNAUTHORIZED
  - PERMISSION_DENIED
  - TENANT_FORBIDDEN
  - RESOURCE_NOT_FOUND
  - EVENTBUS_UNAVAILABLE

### GET /api/v1/health/summary
- auth: zorunlu
- tenant context: zorunlu
- minimum permission:
  - monitoring.read
  - dashboard.read
- hata kodlari:
  - AUTH_UNAUTHORIZED
  - PERMISSION_DENIED
  - TENANT_FORBIDDEN
  - SERVICE_UNAVAILABLE

---

## UI davranis kurallari

- auth/me fail olursa login ekranina don
- tenant/current fail olursa tenant baglami yok ekranina dus
- 401 gelirse session temizlenip login ekranina gidilsin
- 403 gelirse ilgili widget yerine yetki yok durumu gosterilsin
- dashboard/monitoring/health endpointleri tenant bagli calisacak
- auth/me disindaki tum ilk panel endpointleri tenant context gerektirecek

---

## Sabitleme kararlari

- ilk panelde auth opsiyonel degil
- ilk panelde guest kullanici yok
- ilk panelde tenant'siz dashboard yok
- permission isimleri simdilik:
  - dashboard.read
  - monitoring.read
  - erp.read
- role yerine permission kontrolu tercih edilir
