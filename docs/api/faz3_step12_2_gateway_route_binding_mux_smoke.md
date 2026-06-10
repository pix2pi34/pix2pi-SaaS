# FAZ 3 / STEP 12.2C — ERP Runtime Gateway Route Binding Mux Smoke

## Amaç

ERP Runtime API route binding sözleşmesinin gerçek HTTP mux/router davranışıyla çalıştığını doğrulamak.

## Doğrulanan Endpoint

POST `/api/v1/erp/runtime/flows`

## Doğrulanan Davranışlar

- Route binding mux/router üzerine kaydediliyor.
- POST çağrısı HTTP handler'a ulaşıyor.
- Başarılı istek `200 OK` dönüyor.
- Yanlış HTTP method `405 Method Not Allowed` dönüyor.
- Yanlış path `404 Not Found` dönüyor.
- Service sadece doğru route + doğru method ile çağrılıyor.

## Sonuç

Gateway route binding contract, mux seviyesi smoke test ile doğrulandı.
