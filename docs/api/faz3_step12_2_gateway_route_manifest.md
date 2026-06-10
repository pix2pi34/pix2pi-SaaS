# FAZ 3 / STEP 12.2 — ERP Runtime API Gateway Route Manifest

## Endpoint

POST `/api/v1/erp/runtime/flows`

## Route Name

`erp.runtime.flows.create`

## Handler

`RuntimeFlowHTTPHandler`

## Request Contract

`RuntimeFlowAPIRequest`

## Response Contract

`RuntimeFlowAPIResponse`

## Error Response Contract

`RuntimeFlowAPIErrorResponse`

## Security Contract

- Auth zorunlu: evet
- Tenant header zorunlu: evet
- Request ID zorunlu: evet
- Idempotency key zorunlu: evet

## Gateway Beklentisi

Gateway bu endpoint'i tenant-aware olarak yönlendirmelidir.

Zorunlu başlıklar:

- `Authorization: Bearer <token>`
- `X-Tenant-ID`
- `X-Request-ID`

## Runtime Akışı

API Gateway → ERP Runtime API Surface → E2E Flow Orchestrator → PostgreSQL Runtime Flow Store

## Mühür Notu

Bu dosya Gateway bağlantı hazırlığı için route manifest sözleşmesidir.
