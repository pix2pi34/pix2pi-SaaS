# FAZ 4 / 17.3 - Reporting Auth / Tenant Gate Contract

## Auth Gate

Tum reporting endpointleri icin zorunlu:

Authorization: Bearer <token>

Eksik veya hatali Bearer davranisi:
- HTTP 401
- error.code=AUTH_REQUIRED

## Tenant Header Gate

Tum reporting endpointleri icin zorunlu:

X-Tenant-ID: <tenant_id>

Eksik tenant header davranisi:
- HTTP 400
- error.code=TENANT_HEADER_REQUIRED

## Tenant Mismatch Gate

JWT tenant claim ile X-Tenant-ID uyumsuzsa:
- HTTP 403
- error.code=TENANT_MISMATCH

## Request ID Gate

Gateway su header'i gecirmelidir:

X-Request-ID

Yoksa handler req_unknown kullanabilir.
Production gateway tarafinda request_id uretilmesi onerilir.

## Allowed Methods

Sadece GET.

Diger methodlar:
- HTTP 405
- error.code=METHOD_NOT_ALLOWED

## Reporting Route Allowlist

/api/v1/reporting/operational/summary
/api/v1/reporting/operational/daily-metrics
/api/v1/reporting/inventory/status
/api/v1/reporting/documents/work-queue
/api/v1/reporting/reconciliation/status
/api/v1/reporting/projections/state

## Security Assertions

- Cross-tenant query yasak.
- Tenant filtresi client query parametresinden alinmaz.
- Tenant upstream auth context + X-Tenant-ID sozlesmesi ile belirlenir.
- Raw SQL loglanmaz.
- Query text response icine basilmaz.
- Reporting endpoints read-only kabul edilir.
- Gateway rate-limit ileride eklenebilir.

## Gate Result Target

AUTH_TENANT_MIDDLEWARE_GATE=PASS
BEARER_AUTH_REQUIRED=YES
TENANT_HEADER_REQUIRED=YES
TENANT_MISMATCH_GATE=YES
QUERY_TEXT_LOGGING_ALLOWED=NO
