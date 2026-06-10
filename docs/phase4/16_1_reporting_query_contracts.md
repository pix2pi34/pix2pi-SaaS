# FAZ 4 / 16.1 - Reporting Query Contracts

## 1. Success Response Envelope

Tekil obje:

{
  "status": "ok",
  "request_id": "req_xxx",
  "tenant_id": "tenant_7",
  "data": {}
}

Liste response:

{
  "status": "ok",
  "request_id": "req_xxx",
  "tenant_id": "tenant_7",
  "data": [],
  "meta": {
    "limit": 50,
    "next_cursor": null,
    "has_more": false
  }
}

## 2. Error Response Envelope

{
  "status": "error",
  "request_id": "req_xxx",
  "tenant_id": "tenant_7",
  "error": {
    "code": "REPORTING_QUERY_ERROR",
    "message": "Reporting query failed",
    "details": {}
  }
}

## 3. Error Codes

| Code | HTTP | Meaning |
|---|---:|---|
| AUTH_REQUIRED | 401 | Bearer token yok |
| TENANT_HEADER_REQUIRED | 400 | X-Tenant-ID yok |
| TENANT_MISMATCH | 403 | JWT tenant ile header uyumsuz |
| REPORTING_INVALID_FILTER | 400 | Filtre format hatali |
| REPORTING_LIMIT_EXCEEDED | 400 | Limit max degeri asti |
| REPORTING_CURSOR_INVALID | 400 | Cursor gecersiz |
| REPORTING_QUERY_ERROR | 500 | Query runtime hatasi |
| REPORTING_READMODEL_NOT_READY | 503 | Projection/readmodel hazir degil |

## 4. Pagination Contract

Request:
- limit default: 50
- limit max: 200
- cursor opaque string olmalidir
- cursor icinde raw SQL bulunmaz
- cursor tenant scoped olmalidir

Response meta:
- limit
- next_cursor
- has_more

## 5. Filter Contract

Genel:
- Date filters ISO format olmali.
- Boolean filters true/false kabul eder.
- Numeric filters negatif olamaz.
- Empty string filtre yok sayilir.
- Tenant filter client'tan alinmaz; middleware context'ten gelir.

## 6. Tenant Contract

Zorunlu:
- JWT tenant claim okunur.
- X-Tenant-ID header okunur.
- Ikisi eslesmezse TENANT_MISMATCH.
- Repository layer tum sorgularda tenant_id parametresini zorunlu alir.
- Reporting query tenant_id olmadan calismaz.

## 7. Readmodel Contract

Reporting query layer sadece su kaynaklardan okur:

readmodel.tenant_operational_snapshot
readmodel.daily_operational_metrics
readmodel.inventory_status_snapshot
readmodel.document_work_queue
readmodel.reconciliation_status_snapshot
readmodel.projection_state

Readmodel source-of-truth degildir. Event/projection ile rebuild edilebilir.

## 8. Observability Contract

Her endpoint response/log context:
- request_id
- tenant_id
- endpoint
- duration_ms
- result_count
- status
- error_code

Query text loglanmaz.

## 9. Future Contract Gates

Sonraki adimlar:
- 16.2 Readmodel repository layer
- 16.3 Reporting service layer
- 16.4 API endpoint skeleton
- 16.5 Query smoke tests / final closure
