# FAZ 7-5P — Payment Provider Adapter Module Foundation

## 7-5P.1 Modul siniri

Bu modul, Pix2pi commercial core icinden ayrilan odeme saglayici baglanti katmanidir.

Amac:
- Billing core icinde fatura, KDV, plan ucreti ve invoice draft kalir.
- Payment Provider Adapter ayri modul olur.
- Gercek odeme saglayicilari bu modulun adapter interface'i arkasina baglanir.
- Commercial core, dogrudan herhangi bir banka/POS/PSP SDK'sina baglanmaz.

Bu adimda gercek para cekimi yoktur.

## 7-5P.2 Provider abstraction

Bu modulde odeme saglayici bagimsiz calisma modeli kurulur.

Temel kararlar:
- Provider bagimsiz interface vardir.
- SIMULATION, SANDBOX ve PRODUCTION mode ayrimi vardir.
- AUTHORIZE, CAPTURE, REFUND, VOID ve WEBHOOK_VERIFY operasyonlari standartlastirilir.
- Provider config ile hangi operasyonlarin acik oldugu belirlenir.
- Tenant, correlation ve idempotency bilgileri olmadan kritik odeme karari verilmez.

## 7-5P.3 Real payment gate

Bu adimda production odeme kapisi bilerek kapali tutulur.

Kural:
- Mode PRODUCTION olsa bile real_payment_enabled=false ise islem reddedilir.
- Gercek banka/POS/PSP anlasmasi, hukuk, vergi ve operasyon onaylari tamamlanmadan real payment acilmaz.
- Bu karar audit edilebilir sekilde kod, config, test ve dokumanda tutulur.

## 7-5P.4 Tenant / idempotency / audit zorunlulugu

Adapter kararlarinda su bilgiler zorunludur:
- tenant_id
- correlation_id
- idempotency_key
- para birimi
- tutar
- operasyon tipi

Bu sayede:
- tenant karismasi engellenir
- cift odeme riski azaltilir
- odeme karari audit trail icin izlenebilir olur
- ileride provider webhook dogrulama ve settlement akisi guvenli sekilde eklenebilir

## 7-5P.5 Bu adimda kurulan dosyalar

- docs/faz7/FAZ_7_5P_PAYMENT_PROVIDER_ADAPTER_MODULE_FOUNDATION.md
- configs/faz7/payment_provider_adapter.v1.json
- internal/platform/commercial/paymentadapter/adapter.go
- internal/platform/commercial/paymentadapter/adapter_test.go
- docs/faz7/evidence/FAZ_7_5P_REAL_IMPLEMENTATION_AUDIT.md

## 7-5P.6 Kapanis kosulu

Bu adim ancak su kosullarla PASS sayilir:
- Modul dokumani var
- Config artifact var
- Go runtime kodu var
- Provider abstraction var
- Real payment gate var
- Tenant/idempotency/correlation guard var
- Unit testler PASS
- Real implementation audit PASS
