# LVL7 UI Error Standard

## 1) V1 hata response envelope

Tum V1 endpointleri hata durumunda asagidaki zarf ile donecek:

```json
{
  "error": {
    "code": "AUTH_UNAUTHORIZED",
    "message": "gecersiz veya eksik token",
    "details": []
  },
  "meta": {
    "request_id": "req_123",
    "timestamp": "2026-04-20T19:00:00Z",
    "tenant_id": "tenant_42"
  }
}
```

Kurallar:
- `error.code` zorunlu
- `error.message` zorunlu
- `error.details` her zaman array olacak
- `meta.request_id` zorunlu
- `meta.timestamp` zorunlu
- tenant bagli endpointlerde `meta.tenant_id` zorunlu
- hata response'unda `data` donulmeyecek

---

## 2) HTTP status standardi

### 400 Bad Request
Kullanim:
- query param hatasi
- request format hatasi
- gecersiz alan degeri

Ornek code:
- BAD_REQUEST
- INVALID_QUERY
- INVALID_CURSOR

### 401 Unauthorized
Kullanim:
- token yok
- bearer format bozuk
- token gecersiz
- token suresi bitmis

Ornek code:
- AUTH_UNAUTHORIZED
- AUTH_INVALID_BEARER
- AUTH_TOKEN_EXPIRED
- AUTH_INVALID_TOKEN

### 403 Forbidden
Kullanim:
- tenant mismatch
- yetki yok
- bu endpoint icin role/permission yetersiz

Ornek code:
- TENANT_FORBIDDEN
- PERMISSION_DENIED
- ROLE_FORBIDDEN

### 404 Not Found
Kullanim:
- tenant bulunamadi
- projection bulunamadi
- istenen kaynak yok

Ornek code:
- RESOURCE_NOT_FOUND
- TENANT_NOT_FOUND
- PROJECTION_NOT_FOUND

### 409 Conflict
Kullanim:
- replay/duplicate conflict
- conflict olusturan is akisi
- state mismatch

Ornek code:
- DUPLICATE_EVENT
- REPLAY_CONFLICT
- STATE_CONFLICT

### 422 Unprocessable Entity
Kullanim:
- semantic validation hatasi
- kurala uygun olmayan payload
- domain validation hatasi

Ornek code:
- DOMAIN_VALIDATION_FAILED
- RULE_NOT_FOUND
- JOURNAL_UNBALANCED

### 429 Too Many Requests
Kullanim:
- rate limit
- quota limit

Ornek code:
- RATE_LIMITED
- QUOTA_EXCEEDED

### 500 Internal Server Error
Kullanim:
- beklenmeyen sistem hatasi
- maplenemeyen ic hata

Ornek code:
- INTERNAL_ERROR

### 503 Service Unavailable
Kullanim:
- downstream servis ayakta degil
- db / event bus / cache gecici erisilemiyor
- health kritik seviyede

Ornek code:
- SERVICE_UNAVAILABLE
- DATABASE_UNAVAILABLE
- EVENTBUS_UNAVAILABLE

---

## 3) UI yuzeyi icin minimum hata kodlari

### GET /api/v1/auth/me
- AUTH_UNAUTHORIZED
- AUTH_INVALID_TOKEN
- AUTH_TOKEN_EXPIRED
- INTERNAL_ERROR

### GET /api/v1/tenant/current
- AUTH_UNAUTHORIZED
- TENANT_NOT_FOUND
- TENANT_FORBIDDEN
- INTERNAL_ERROR

### GET /api/v1/dashboard/summary
- AUTH_UNAUTHORIZED
- TENANT_FORBIDDEN
- RESOURCE_NOT_FOUND
- INTERNAL_ERROR
- SERVICE_UNAVAILABLE

### GET /api/v1/monitoring/warnings
- AUTH_UNAUTHORIZED
- TENANT_FORBIDDEN
- INVALID_CURSOR
- INTERNAL_ERROR

### GET /api/v1/monitoring/alerts
- AUTH_UNAUTHORIZED
- TENANT_FORBIDDEN
- INVALID_CURSOR
- INTERNAL_ERROR

### GET /api/v1/erp/event-summary
- AUTH_UNAUTHORIZED
- TENANT_FORBIDDEN
- RESOURCE_NOT_FOUND
- EVENTBUS_UNAVAILABLE
- INTERNAL_ERROR

### GET /api/v1/health/summary
- AUTH_UNAUTHORIZED
- TENANT_FORBIDDEN
- SERVICE_UNAVAILABLE
- INTERNAL_ERROR

---

## 4) Ornek hata response'lari

### 401 Unauthorized
```json
{
  "error": {
    "code": "AUTH_TOKEN_EXPIRED",
    "message": "token suresi bitmis",
    "details": []
  },
  "meta": {
    "request_id": "req_123",
    "timestamp": "2026-04-20T19:00:00Z",
    "tenant_id": "tenant_42"
  }
}
```

### 403 Forbidden
```json
{
  "error": {
    "code": "TENANT_FORBIDDEN",
    "message": "aktif tenant ile istenen kaynak uyusmuyor",
    "details": []
  },
  "meta": {
    "request_id": "req_123",
    "timestamp": "2026-04-20T19:00:00Z",
    "tenant_id": "tenant_42"
  }
}
```

### 429 Too Many Requests
```json
{
  "error": {
    "code": "RATE_LIMITED",
    "message": "istek limiti asildi",
    "details": []
  },
  "meta": {
    "request_id": "req_123",
    "timestamp": "2026-04-20T19:00:00Z",
    "tenant_id": "tenant_42"
  }
}
```

### 503 Service Unavailable
```json
{
  "error": {
    "code": "SERVICE_UNAVAILABLE",
    "message": "servis gecici olarak kullanilamiyor",
    "details": []
  },
  "meta": {
    "request_id": "req_123",
    "timestamp": "2026-04-20T19:00:00Z",
    "tenant_id": "tenant_42"
  }
}
```

---

## 5) Sabitleme kararlari

- tum hata response'lari tek zarf ile donecek
- `error.code` makine dostu olacak
- `error.message` UI gostermeye uygun kisa metin olacak
- `error.details` simdilik bos array olabilir ama alan korunacak
- request_id her hata response'unda zorunlu olacak
- auth/tenant problemleri 401 ve 403'e net ayrilacak
- beklenmeyen tum maplenemeyen hatalar `INTERNAL_ERROR` olacak
