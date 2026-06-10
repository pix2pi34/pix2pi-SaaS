# FAZ 3 / STEP 12.3C — ERP Runtime Gateway Mount Binding Mux Smoke

## Amaç

ERP Runtime API Gateway mount binding sözleşmesinin gerçek mux/router davranışıyla çalıştığını doğrulamak.

## Mount

- Mount name: `erp.runtime.api.mount`
- Service name: `erp-runtime-api`
- Mount path: `/api/v1/erp/runtime`
- Upstream mode: `in_process_handler`

## Endpoint

POST `/api/v1/erp/runtime/flows`

## Doğrulanan Davranışlar

- Mount binding route'u mux/router üzerine kaydediyor.
- POST çağrısı HTTP handler'a ulaşıyor.
- Başarılı istek `200 OK` dönüyor.
- Yanlış HTTP method `405 Method Not Allowed` dönüyor.
- Yanlış path `404 Not Found` dönüyor.
- Service sadece doğru path + doğru method ile çağrılıyor.
- Service yoksa mount binding hata dönüyor.

## Sonuç

Gateway mount binding mux smoke başarıyla doğrulanmıştır.
