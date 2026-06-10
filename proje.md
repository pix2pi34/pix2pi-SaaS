# Pix2pi SaaS Proje Notlari

Bu dosya, sonraki Codex sohbetlerinde projeyi hizli anlamak icin hazirlandi. Proje cok genis ve icinde aktif kod, eski sayfalar, yedekler, raporlar, faz bazli test/script dosyalari ve uretilmis artefaktlar birlikte duruyor. Yeni calismalarda once ilgili alt alan daraltilmali.

## Kisa Ozet

Pix2pi SaaS; cok kiracili bir SaaS/ERP platformu olarak kurgulanmis. Ana backend Go ile yazilmis. Web tarafi React + TypeScript + Vite. Bazi musteri kayit/giris/onay akislari Node.js servisleriyle ayrica tutuluyor. Altyapida PostgreSQL, Redis, NATS/JetStream, API Gateway, observability, edge/nginx ve faz bazli operasyon/test paketleri var.

Repo su ana eksenlere ayriliyor:

- Backend servisleri: `cmd/`, `internal/`, `pkg/`, `kernel/`
- Web uygulamasi: `web/`
- Eski/statik web yuzeyleri: `pix2pi_www/`, `oldweb/`
- Ek kucuk servisler: `services/`
- Veritabani: `db/migrations/`, `db/seeds/`, `db/tests/`, `migrations/`, `sql/`
- Deploy/ops: `deploy/`, `infra/`, `grafana/`, `ops/`
- Test ve rapor arkeolojisi: `scripts/`, `test/`, `tests/`, `reports/`, `uat/`, `docs/`
- Yedek/uretilmis alanlar: `backups/`, `.backup/`, `.backups/`, `_backup/`, `_backup_archive/`, `tmp/`, `web/dist/`, `node_modules/`

## Teknoloji

- Go module: `github.com/divrigili/pix2pi-SaaS`
- Go surumu: `go 1.24.0`
- Go ana kutuphaneler: `net/http`, `gorm`, `pgx`, `gofiber`, `jwt/v5`, `go-redis/v9`, `nats.go`, `golang-migrate`
- Web: React 18, TypeScript, Vite, React Query, Zustand, React Router, Vitest
- Node servisleri: vanilla `http` server yaklasimi, dosya tabanli JSON kayitlari
- Veri/altyapi: PostgreSQL, Redis, NATS/JetStream, Docker Compose, nginx, Prometheus/Grafana/Loki/Tempo

## Ana Giris Noktalari

- API Gateway: `cmd/api-gateway/api_gateway_main.go`
  - Varsayilan port `9010`
  - Env: `API_GATEWAY_PORT`, `GATEWAY_PORT`, `GATEWAY_INTERNAL_KEY`
  - Public health route'lari: `/health`, `/health/live`, `/health/ready`, `/health/db`, `/health/replica`, `/health/gateway-policy`, `/health/upstreams`, `/health/aggregate`, `/health/routes`
  - Protected ornek route'lar: `/api/me`, `/api/query/users`, `/api/query/users/list`, `/api/query/users/`, `/api/v1/erp/runtime/flows`

- Identity API: `cmd/identity-api/identity_api_main.go`
  - Varsayilan port `9012`
  - `/register` ile kullanici olusturup `pix2pi.user.created` NATS event'i yayinliyor
  - `/health` basit servis health donduruyor

- Reporting service: `cmd/reporting-service/reporting_service_main.go`
  - NATS subject: `pix2pi.>`
  - Durable consumer: `reporting_service`
  - `sale.created`, `sale.updated`, `sale.completed` event'lerini query read model'e yansitiyor
  - Env: `NATS_URL`, `QUERY_READ_MODEL_URL`

- Web app: `web/src/app/App.tsx`
  - Runtime config: `web/src/core/config/runtime-config.ts`
  - Default API: `http://localhost:9010`
  - Operasyon ekranlari: service registry, mission control, jobs queue, webhook/workflow/plugin/public API/notification/early warning/incident audit/runtime topology/realtime monitor
  - Tenant admin route'lari icin `TENANT_ADMIN` rolu bekleniyor

- Customer registration API: `services/customer-register-submit-api/server.js`
  - Varsayilan port `9036`
  - Basvuru JSON dosyalarini varsayilan olarak `web/customer-register/data/applications` altina yazar
  - Form alanlarini Turkce/Ing form varyantlariyla normalize eder

## Veritabani Notlari

- Temel migration dizini: `db/migrations/`
- Faz bazli migration alt dizinleri: `db/migrations/faz1`, `faz2`, `faz3`, `faz4`
- SQL testleri: `db/tests/`
- Faz4 seed: `db/seeds/faz4/20260508_134200_faz_4_14_2_reference_data_seed_standard.sql`
- Dev PostgreSQL compose:
  - `deploy/docker-compose.yml`: Postgres 15, port `5432`, db `pix2pi_saas`
  - `deploy/dev/docker-compose.pg.yml`: Postgres 16, host port `5433`, db/user/pass `pix2pi`

## Web Notlari

Ana modern web uygulamasi `web/` altinda. `package.json` komutlari:

```bash
cd web
npm run dev
npm run build
npm run test
```

`web/src/features/operations/*` altinda her operasyon modulu icin genelde su yapi var:

- `...Page.tsx`
- `...Page.test.tsx`
- `...-api.ts`
- `types.ts`

`web/` altinda ayrica cok sayida statik/faz bazli yuzey var: `customer-login`, `customer-register`, `owner-panel`, `panel`, `pos`, `market`, `pilot-*`, `faz*` vb. Bunlar modern `web/src` uygulamasindan ayri ele alinmali.

## Backend Notlari

`cmd/` altinda cok sayida servis/runtime/test executable var. En onemlileri:

- `api-gateway`
- `identity-api`
- `auth-api`
- `accounting-service`
- `cache-service`
- `event-bus`
- `event-consumer`
- `query-read-model`
- `reporting-service`
- `mission-control`
- `service-registry`
- `jobs-runtime`
- `notification-runtime`
- `workflow-runtime`
- `publicapi-runtime`
- `realtime-runtime`, `realtime-sse`, `realtime-ws`
- `plugin-runtime`
- `stock-service`

Domain kodu buyuk olcude `internal/` altinda:

- `internal/platform`: auth, audit, db, gateway, eventbus/eventstore, reporting, service registry, workflow, plugins, publicapi, realtime, tenancy, security vb.
- `internal/erp`: ERP core, runtime, persistence, Turkiye uyumluluk modulleri, satis/alis/stok/cari/ledger/tax/ebelge alanlari
- `internal/auth`, `internal/identity`, `internal/commercial`, `internal/onboarding`: kullanici, ticari ve onboarding akislarinin parcalari

Go komutlari:

```bash
go test ./...
go run ./cmd/api-gateway
go run ./cmd/identity-api
go run ./cmd/reporting-service
```

Not: `go test ./...` repo genisligi nedeniyle uzun surebilir ve uretilmis/eski alanlardan etkilenebilir. Dar kapsamli calismalarda once ilgili paketin testini calistirmak daha saglikli.

## Env Notlari

`.env_example` su ana degiskenleri listeliyor:

- `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`
- `DB_READ_DSN`, `DB_WRITE_DSN`, `DB_DSN`
- `REDIS_HOST`, `REDIS_PORT`
- `APP_ENV`, `APP_NAME`
- `JWT_SECRET`

Gateway tarafinda ek olarak `API_GATEWAY_PORT`, `GATEWAY_PORT`, `GATEWAY_INTERNAL_KEY` kullaniliyor. Reporting tarafinda `NATS_URL` ve `QUERY_READ_MODEL_URL` var. Node musteri servislerinde genelde `HOST`, `PORT` ve servis ozel dizin env'leri kullaniliyor.

## Dikkat Edilecekler

- Calisma agaci su anda cok kirli: pek cok modified/deleted/untracked dosya var. Yeni degisikliklerde kullanicinin mevcut degisiklikleri geri alinmamali.
- `README.md` bos gorunuyor; proje bilgisi klasor yapisi ve koddan cikarildi.
- `rg --files` normal haliyle `node_modules`, yedekler ve dist dosyalari yuzunden asiri buyuk cikiyor. Arama yaparken su tur dislamalar kullan:

```bash
rg --files -g '!**/node_modules/**' -g '!backups/**' -g '!tmp/**' -g '!web/dist/**'
```

- `web/node_modules/`, `apps/*/node_modules/`, `backups/`, `.backup/`, `_backup*`, `tmp/`, `web/dist/` gibi alanlar genelde kaynak degil; ozellikle istenmedikce dokunma.
- Repo icinde eski `.ok_...`, `.bak_...`, faz raporlari ve yedek scriptleri var. Benzer isimli dosyalarda aktif dosyayi ayirt etmek icin entrypoint ve import zincirine bak.
- Kullanicinin IDE'sinde `.env_example`, `.env`, `.env copy`, `.gitignore` acik. `.env` dosyasinda gizli bilgi olabilir; gerekmedikce icerigini final mesajlarda paylasma.

## Sonraki Sohbetlerde Iyi Baslangic

Bir is geldiginde once alanini belirle:

1. Web UI ise `web/src` mi, yoksa statik `web/*`/`pix2pi_www` sayfasi mi?
2. Backend ise hangi servis: gateway, identity, reporting, ERP runtime, platform runtime?
3. DB ise `db/migrations` mi yoksa faz alt dizinleri mi?
4. Operasyon/deploy ise `deploy/edge`, `deploy/observability`, `deploy/platform`, `deploy/quality` gibi ilgili alt alan hangisi?
5. Test isteniyorsa once dar paket/script calistir, sonra gerekirse genis suite'e cik.

Bu proje icin en guvenli calisma bicimi: ilgili entrypoint'i ve testini bul, komsu dosyalardaki yerel paterni izle, degisikligi dar tut, sonra hedefli test calistir.
