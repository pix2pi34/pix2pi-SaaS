# FAZ 4 / 17.1 - Reporting Runtime Wiring Plan

## Scope

Bu plan 16.x ile hazirlanan reporting API zincirini runtime'a baglamak icin izlenecek wiring modelini tanimlar.

Mevcut katmanlar:
- internal/platform/reporting/repository
- internal/platform/reporting/service
- internal/platform/reporting/api

Hedef runtime zinciri:

HTTP request
  -> Gateway / upstream auth tenant middleware
  -> Reporting API handler
  -> Reporting service
  -> Readmodel repository
  -> Readmodel DB query layer

## Runtime Entry Model

17.2 ve sonrasi icin hedef entry:

repository.New()
  -> service.New(repository)
  -> api.NewHandler(service)
  -> handler.Register(mux/router)

## Bu Adimda Yapilmayanlar

RUNTIME_STARTED=NO
GATEWAY_CONFIG_CHANGED=NO
NGINX_CONFIG_CHANGED=NO
DB_MUTATION=NO
DB_MIGRATION_CREATED=NO
CONTAINER_RESTARTED=NO

## 17.x Uygulama Sirasi

17.1 Reporting runtime wiring plan / service entry contract
17.2 Reporting API route registration
17.3 Gateway route manifest / auth-tenant middleware gate
17.4 Runtime smoke test
17.5 Reporting API final closure

## Runtime Safety

- Runtime entry read-only reporting endpointleri icindir.
- POST/PUT/PATCH/DELETE bu blokta yoktur.
- Query text response icinde donmez.
- Raw SQL loglanmaz.
- Tenant ID her request'te zorunludur.
- Cross-tenant query yasaktir.

## Expected Runtime Package Direction

17.2 icin muhtemel hedefler:
- internal/platform/reporting/runtime
- veya mevcut API handler'in gateway/router tarafina baglanmasi
- route manifest dosyasinin service registry/gateway dokumanina eklenmesi

Bu karar 17.2'de mevcut proje yapisina gore uygulanacaktir.
