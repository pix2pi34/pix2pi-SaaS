# LVL7 UI Surface Contracts

## 1) Basari response envelope

Tum V1 read endpointleri asagidaki basari zarfi ile donecek:

```json
{
  "data": {},
  "meta": {
    "request_id": "req_123",
    "timestamp": "2026-04-20T19:00:00Z",
    "tenant_id": "tenant_42"
  }
}
```

Kurallar:
- `data` zorunlu
- `meta.request_id` zorunlu
- `meta.timestamp` zorunlu
- tenant bagli endpointlerde `meta.tenant_id` zorunlu
- liste endpointlerinde `data.items` kullanilir
- tekil endpointlerde `data` object olur

---

## 2) GET /api/v1/auth/me

### Request
Method:
- GET

Query:
- yok

Body:
- yok

Headers:
- Authorization: Bearer <token>

### Response
```json
{
  "data": {
    "user_id": "user_123",
    "email": "user@example.com",
    "tenant_id": "tenant_42",
    "tenant_uuid": "uuid-42",
    "roles": ["owner"],
    "permissions": ["dashboard.read"]
  },
  "meta": {
    "request_id": "req_123",
    "timestamp": "2026-04-20T19:00:00Z",
    "tenant_id": "tenant_42"
  }
}
```

---

## 3) GET /api/v1/tenant/current

### Request
Method:
- GET

Query:
- yok

Body:
- yok

Headers:
- Authorization: Bearer <token>

### Response
```json
{
  "data": {
    "tenant_id": "tenant_42",
    "tenant_uuid": "uuid-42",
    "tenant_name": "Demo Tenant",
    "plan_code": "starter",
    "status": "active"
  },
  "meta": {
    "request_id": "req_123",
    "timestamp": "2026-04-20T19:00:00Z",
    "tenant_id": "tenant_42"
  }
}
```

---

## 4) GET /api/v1/dashboard/summary

### Request
Method:
- GET

Query:
- yok

Body:
- yok

Headers:
- Authorization: Bearer <token>

### Response
```json
{
  "data": {
    "cards": [
      {
        "key": "today_events",
        "label": "Bugunku Event",
        "value": 128
      },
      {
        "key": "open_warnings",
        "label": "Acik Warning",
        "value": 3
      },
      {
        "key": "service_health",
        "label": "Saglikli Servis",
        "value": 6
      }
    ]
  },
  "meta": {
    "request_id": "req_123",
    "timestamp": "2026-04-20T19:00:00Z",
    "tenant_id": "tenant_42"
  }
}
```

---

## 5) GET /api/v1/monitoring/warnings

### Request
Method:
- GET

Query:
- limit (opsiyonel)
- cursor (opsiyonel)

Body:
- yok

Headers:
- Authorization: Bearer <token>

### Response
```json
{
  "data": {
    "items": [
      {
        "signal_type": "database.pressure",
        "source": "postgres-primary",
        "severity": "high",
        "metric_key": "db_connection_usage_pct",
        "metric_value": 92,
        "message": "postgres-primary: database connection usage pressure detected",
        "observed_at": "2026-04-20T19:00:00Z"
      }
    ]
  },
  "meta": {
    "request_id": "req_123",
    "timestamp": "2026-04-20T19:00:00Z",
    "tenant_id": "tenant_42",
    "next_cursor": ""
  }
}
```

---

## 6) GET /api/v1/monitoring/alerts

### Request
Method:
- GET

Query:
- limit (opsiyonel)
- cursor (opsiyonel)

Body:
- yok

Headers:
- Authorization: Bearer <token>

### Response
```json
{
  "data": {
    "items": [
      {
        "kind": "security_alarm",
        "signal_type": "auth.rejected",
        "source": "security.auth",
        "severity": "high",
        "metric_key": "p2_urgent",
        "message": "security alarm category=auth escalation=p2_urgent alert=true ticket=true",
        "observed_at": "2026-04-20T19:00:00Z"
      }
    ]
  },
  "meta": {
    "request_id": "req_123",
    "timestamp": "2026-04-20T19:00:00Z",
    "tenant_id": "tenant_42",
    "next_cursor": ""
  }
}
```

---

## 7) GET /api/v1/erp/event-summary

### Request
Method:
- GET

Query:
- yok

Body:
- yok

Headers:
- Authorization: Bearer <token>

### Response
```json
{
  "data": {
    "event_store_status": "healthy",
    "replay_status": "healthy",
    "dlq_depth": 0,
    "retry_pressure": "low",
    "last_event_at": "2026-04-20T18:59:00Z"
  },
  "meta": {
    "request_id": "req_123",
    "timestamp": "2026-04-20T19:00:00Z",
    "tenant_id": "tenant_42"
  }
}
```

---

## 8) GET /api/v1/health/summary

### Request
Method:
- GET

Query:
- yok

Body:
- yok

Headers:
- Authorization: Bearer <token>

### Response
```json
{
  "data": {
    "services": [
      {
        "name": "identity-api",
        "status": "UP",
        "latency_ms": 42
      },
      {
        "name": "finance-api",
        "status": "UP",
        "latency_ms": 55
      }
    ]
  },
  "meta": {
    "request_id": "req_123",
    "timestamp": "2026-04-20T19:00:00Z",
    "tenant_id": "tenant_42"
  }
}
```

---

## 9) Sabitleme kararlari

- tum endpointler GET
- tum endpointler success envelope ile donecek
- tum read endpointleri body almiyor
- liste endpointlerinde `items` kullanilacak
- liste endpointlerinde `meta.next_cursor` placeholder var
- `status`, `severity`, `retry_pressure` gibi alanlar string enum mantigi ile kullanilacak
- `observed_at`, `timestamp`, `last_event_at` alanlari RFC3339 tarih olacak
