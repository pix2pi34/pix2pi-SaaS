# FAZ 3 / STEP 13.1E — Gateway ERP Runtime Route Catalog Wiring

## Amaç

ERP Runtime endpoint'ini gerçek Gateway route catalog / policy listesine eklemek.

## Endpoint

POST `/api/v1/erp/runtime/flows`

## Route Policy

- Route name: `erp.runtime.flows.create`
- Scope: protected
- Auth required: true
- Tenant required: true
- Prefix: false
- Method: POST

## Yapılan İş

`gatewayRouteRules()` fonksiyonu ERP Runtime route rule'u otomatik append edecek şekilde güncellendi.

## Doğrulanan Testler

- `gatewayRouteRules()` ERP Runtime route'u içeriyor.
- `matchRouteRule()` ERP Runtime route'u buluyor.
- POST method izinli.
- GET method reddediliyor.

## Not

Bu adım sadece route policy/catalog wiring yapar. Handler mount işlemi sonraki adımda yapılacaktır.
