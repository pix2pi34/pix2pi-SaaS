# Pix2pi — FAZ 6-3 Multi-node Foundation / Scale-out Readiness

## Faz Bilgisi

Faz: FAZ 6  
Adim: 6-3  
Adim Adi: Multi-node Foundation / Scale-out Readiness  
Onceki Adim: 6-2 DB-L8 HA / Scale / Ops Readiness  
Onceki Adim Durumu: PASS  
Bu Adim Amaci: Pix2pi servislerini tek node mantigindan cok node / scale-out hazirlik seviyesine tasimak  
Risk Seviyesi: Kontrollu  
Runtime Etkisi: Bu adimda servis restart, deploy veya destructive operasyon yoktur  
Sonraki Adim: 6-4 Event Bus / Queue / Backlog SRE Readiness  

---

# 6-3 Ana Karar

Pix2pi'nin uzun vadeli hedefi tek VDS uzerinde calisan sistemden, cok node'a tasinabilir production mimarisine evrilmektir.

Bu adimda hedef hemen Kubernetes veya full cluster kurmak degildir.

Bu adimda hedef:
- servislerin cok instance calisabilirligini kontrol etmek,
- stateful/stateless ayrimini netlestirmek,
- service discovery izlerini dogrulamak,
- load balancer / upstream hazirligini kontrol etmek,
- health/readiness/liveness standardini netlestirmek,
- graceful shutdown / deploy safety izlerini aramak,
- scale-out icin blocker var mi gormektir.

---

# 6-3.1 Cok Node Servis Yerlesimi

## 6-3.1.1 Servis Instance Mantigi

Cok node mimarisinde her servis tek process varsayimina bagli kalmamalidir.

Kontrol edilecek servis tipleri:
- identity-api
- api-gateway
- mission-control
- service-registry
- event-consumer
- plugin-erp
- reporting/read model servisleri
- background worker servisleri

Kural:
- Stateless servisler birden fazla instance olarak calisabilmelidir.
- Port ve config ENV uzerinden tasinabilmelidir.
- Instance sayisi arttiginda tenant isolation bozulmamalidir.

## 6-3.1.2 Runtime Yerlesim Modeli

Ilk asama yerlesim modeli:
- Tek VDS uzerinde cok servis
- Sonra ayni servisin birden fazla instance'i
- Sonra Nginx/Gateway uzerinden upstream dagitim
- Sonra ayri node'a servis tasima
- Sonra production cluster secenegi

## 6-3.1.3 Node Bagimsizligi

Servisler node local dosya sistemine kritik state yazmamalidir.

Kritik state su katmanlarda tutulmalidir:
- PostgreSQL
- Redis
- NATS / JetStream
- Object/file storage
- merkezi log / audit sistemi

---

# 6-3.2 Stateful / Stateless Ayrimi

## 6-3.2.1 Stateless Servisler

Stateless olmasi gerekenler:
- API Gateway
- Identity API runtime
- ERP API runtime
- Mission Control API
- Service Registry API
- Public API servisleri
- UI/static serving katmani

Bu servisler:
- local memory'de kritik session tutmamalidir,
- local dosyaya kritik state yazmamalidir,
- JWT / Redis / DB gibi merkezi kaynaklara dayanmalidir.

## 6-3.2.2 Stateful Katmanlar

Stateful katmanlar:
- PostgreSQL
- Redis
- NATS / JetStream
- backup repository
- file/object storage
- persistent logs

Bu katmanlar icin:
- backup,
- replication,
- restore,
- retention,
- monitoring,
- capacity alarmi zorunludur.

## 6-3.2.3 Session ve Tenant State

Tenant ve user bilgisi:
- JWT claims,
- DB tenant context,
- Redis namespace,
- event metadata,
- request context uzerinden tasinmalidir.

Local process memory tek kaynak olmamalidir.

---

# 6-3.3 Service Discovery Runtime Tuning

## 6-3.3.1 Service Registry

Service Registry hedefi:
- servis adlarini,
- host/port bilgilerini,
- health durumlarini,
- readiness durumlarini,
- versiyon bilgilerini merkezi gormektir.

## 6-3.3.2 Mission Control

Mission Control hedefi:
- servislerin UP/DOWN durumunu izlemek,
- health summary vermek,
- incident ve alarm katmanina veri saglamak,
- SRE dashboard'a kaynak olmaktir.

## 6-3.3.3 Discovery Failover

Service discovery sorununda:
- gateway sonsuz retry yapmamalidir,
- timeout kullanmalidir,
- downstream unavailable net donmelidir,
- incident kaydi uretilmelidir.

---

# 6-3.4 Load Balancer / Upstream Hazirligi

## 6-3.4.1 Nginx Upstream Modeli

Nginx veya gateway tarafinda upstream modeli gerekir.

Kontrol edilecekler:
- upstream tanimi,
- proxy_pass kullanimi,
- timeout ayarlari,
- health davranisi,
- client body limit,
- header forwarding,
- request id forwarding.

## 6-3.4.2 Gateway Upstream Modeli

API Gateway ileride ayni servisin birden fazla instance'ina route edebilmelidir.

Kural:
- route config ENV veya config dosyasi ile yonetilmelidir.
- servis URL'leri kod icine gomulu kalmamalidir.
- retry, timeout ve circuit breaker ileride eklenebilir olmalidir.

## 6-3.4.3 Edge / Internal Ayrimi

Public edge:
- Cloudflare / WAF / CDN / Nginx

Internal routing:
- API Gateway
- service registry
- internal service URLs

Public endpoint ile internal endpoint karismamalidir.

---

# 6-3.5 Health / Readiness / Liveness Standardi

## 6-3.5.1 Health

Health endpoint servis process ayakta mi sorusuna cevap verir.

Minimum cevap:
- service name
- status
- timestamp
- version opsiyonel
- dependency summary opsiyonel

## 6-3.5.2 Readiness

Readiness endpoint servis trafik almaya hazir mi sorusuna cevap verir.

Kontrol edilecekler:
- DB baglantisi
- Redis baglantisi
- NATS baglantisi
- required config
- migration uyumu
- dependency availability

## 6-3.5.3 Liveness

Liveness endpoint process takildi mi / yasiyor mu sorusuna cevap verir.

Kural:
- Liveness cok agir dependency kontrolu yapmamalidir.
- Readiness ile karistirilmamalidir.

---

# 6-3.6 Graceful Shutdown / Deploy Safety

## 6-3.6.1 Graceful Shutdown

Servisler SIGTERM aldiginda:
- yeni is almayi durdurmali,
- devam eden requestleri bitirmeli,
- DB/event connection kapatmali,
- timeout sonunda temiz cikmalidir.

## 6-3.6.2 Rolling Update Hazirligi

Rolling update icin:
- readiness once false olabilir,
- trafik drain edilir,
- sonra process durdurulur,
- yeni instance ayaga kalkar,
- readiness pass olunca trafik alir.

## 6-3.6.3 Worker Drain

Worker servisleri:
- event/message claim ettikten sonra yarim birakmamalidir,
- ack/nack kurallari net olmalidir,
- shutdown sirasinda idempotency bozulmamalidir.

---

# 6-3.7 Scale-out Blocker Listesi

Scale-out onundeki muhtemel blockerlar:
- hard-coded localhost endpointleri,
- portlarin ENV yerine kodda sabit olmasi,
- local file state kullanimi,
- local memory session kullanimi,
- health endpoint eksigi,
- readiness endpoint eksigi,
- graceful shutdown eksigi,
- service discovery eksigi,
- Nginx upstream eksigi,
- DB connection pool kontrolsuzlugu,
- event consumer idempotency eksigi,
- tenant izolasyonu eksigi.

---

# 6-3.8 Multi-node Final Closure Gate

6-3 kapanis kriterleri:

- Multi-node plan dokumani hazir olmali.
- Stateful/stateless ayrimi yazilmis olmali.
- Service registry / mission control hedefi yazilmis olmali.
- Nginx / gateway upstream hazirlik kontrolu yazilmis olmali.
- Health/readiness/liveness standardi yazilmis olmali.
- Graceful shutdown / rolling update hedefi yazilmis olmali.
- Runtime audit evidence uretilmis olmali.
- Real implementation audit uretilmis olmali.
- Eksik implementasyon varsa net gorunmeli.
- PASS olmadan 6-4'e gecilmemeli.

---

# 6-3 Muhur Hedefi

FAZ_6_3_DOC_STATUS=READY ✅  
FAZ_6_3_VISIBLE_CHECKPOINTS_STATUS=READY ✅  
FAZ_6_3_RUNTIME_AUDIT_STATUS=COMPLETE ✅  
FAZ_6_3_REAL_IMPLEMENTATION_AUDIT_STATUS=COMPLETE ✅  
FAZ_6_3_TEST_STATUS=PASS ✅  
FAZ_6_3_FINAL_STATUS=PASS_OR_NEEDS_IMPLEMENTATION_REVIEW  
FAZ_6_4_READY=CONDITIONAL  

