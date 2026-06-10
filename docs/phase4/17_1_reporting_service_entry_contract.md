# FAZ 4 / 17.1 - Reporting Service Entry Contract

## Entry Contract

Reporting runtime entry su zinciri kurmalidir:

repo := repository.New()
svc  := service.New(repo)
h    := api.NewHandler(svc)
h.Register(mux)

## Required Imports

Hedef katmanlar:

github.com/divrigili/pix2pi-SaaS/internal/platform/reporting/repository
github.com/divrigili/pix2pi-SaaS/internal/platform/reporting/service
github.com/divrigili/pix2pi-SaaS/internal/platform/reporting/api

## API Handler Contract

Mevcut API handler:
- net/http uyumlu ServeHTTP saglar.
- Register(mux *http.ServeMux) methodu saglar.
- Runtime server baslatmaz.
- Service interface ile calisir.
- Auth Bearer ve X-Tenant-ID skeleton kontrolu yapar.
- Context tenant claim mismatch kontrolunu destekler.

## Service Contract

Service layer:
- 6 reporting method saglar.
- TenantID zorunlu validation yapar.
- Repository interface uzerinden query spec uretir.
- DB execute etmez.
- Error code mapping yapar.

## Repository Contract

Repository layer:
- 6 readmodel query spec methodu saglar.
- QuerySpec read-only olmalidir.
- TenantID zorunludur.
- Limit default 50, max 200 sozlesmesini uygular.
- Mutation SQL uretmez.

## Runtime Config Contract

17.2 veya 17.3'te eklenecek runtime config:
- REPORTING_API_ENABLED
- REPORTING_API_BASE_PATH=/api/v1/reporting
- REPORTING_API_READ_ONLY=true
- REPORTING_API_REQUIRE_BEARER=true
- REPORTING_API_REQUIRE_TENANT_HEADER=true

## Safety Contract

DB_MUTATION=NO
QUERY_TEXT_PRINTED=NO
SERVICE_RUNTIME_STARTED=NO_IN_17_1
HTTP_HANDLER_ALREADY_CREATED=YES_IN_16_4
