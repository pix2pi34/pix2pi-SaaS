# Pix2pi — FAZ 6-8 Performance / Load / Stress Readiness

## Faz Bilgisi

Faz: FAZ 6  
Adim: 6-8  
Adim Adi: Performance / Load / Stress Readiness  
Onceki Adim: 6-7 Security Hardening / Production Guardrails  
Onceki Adim Durumu: PASS  
Bu Adim Amaci: Pix2pi sisteminin performans, yuk, stress, bottleneck ve capacity readiness seviyesini kanitlamak  
Risk Seviyesi: Kontrollu  
Runtime Etkisi: Bu adimda agir load/stress calistirilmaz; safe baseline audit yapilir  
Sonraki Adim: 6-9 Release / Rollback / Deploy Safety  

---

# 6-8 Ana Karar

Production sistemde performans sadece "calisiyor" demek degildir.

Hedef:
- baseline performans sinyallerini toplamak,
- servis / DB / event bus / gateway darboğaz adaylarini gormek,
- load test icin guvenli metodoloji yazmak,
- stress test icin sinir ve durdurma kriterlerini yazmak,
- tek VDS uzerindeki kapasite sinirini anlamaya hazirlanmak,
- gereksiz risk almadan performans readiness kapisini kapatmaktir.

Bu adimda destructive veya agresif yuk testi yapilmaz.

---

# 6-8.1 Baseline Performance

Baseline hedefi:
- sistem bos/yakin normal durumda nasil davraniyor gormek,
- CPU/RAM/disk/network sinyali almak,
- servis health latency olcmek,
- DB ve event bus durumunu okumak,
- sonraki load test icin referans noktasi olusturmaktir.

Minimum baseline evidence:
- uptime/load average,
- free memory,
- disk usage,
- docker stats,
- listening ports,
- health endpoint timing,
- Prometheus targets,
- DB readiness,
- NATS readiness.

---

# 6-8.2 Load Test Readiness

Load test hedefi:
- normal beklenen trafik altinda sistem davranisini olcmek,
- API Gateway latency ve 5xx oranini izlemek,
- DB connection pool saturation var mi gormek,
- event backlog artiyor mu izlemek,
- resource kullanimi nasil degisiyor gormektir.

Load test kurallari:
- production uzerinde kontrolsuz load test yapilmaz.
- once staging veya kontrollu pencere kullanilir.
- test baslamadan once backup ve rollback hazir olmalidir.
- test sirasinda Prometheus/Grafana izlenir.
- test fail olursa durdurma kriteri uygulanir.

Minimum araclar:
- hey,
- wrk,
- ab,
- k6,
- vegeta,
- curl timing,
- custom smoke/load script.

---

# 6-8.3 Stress Test Readiness

Stress test hedefi:
- sistemin kirilma noktasini kontrollu sekilde bulmak,
- hangi kaynak once darbogaza giriyor gormek,
- scale kararini veriyle vermektir.

Stress test durdurma kriterleri:
- CPU surekli cok yuksek,
- RAM swap baskisi,
- disk IO sikismasi,
- DB connection saturation,
- gateway 5xx artisi,
- event backlog hizla artisi,
- servis crash,
- health endpoint fail,
- latency kabul edilemez seviyeye cikmasi.

---

# 6-8.4 Bottleneck Evidence

Bottleneck adaylari:
- DB query latency,
- connection pool bekleme,
- Nginx/gateway timeout,
- event consumer lag,
- Redis saturation,
- disk IO,
- CPU saturation,
- memory pressure,
- container resource limit,
- slow external integration.

Evidence kaynaklari:
- Prometheus,
- Grafana,
- application logs,
- DB slow query,
- NATS monitoring,
- docker stats,
- nginx logs,
- gateway metrics.

---

# 6-8.5 API Gateway Performance Readiness

Gateway icin kontrol:
- timeout ayarlari,
- upstream timeout,
- request latency metric,
- 4xx/5xx metric,
- rate limit davranisi,
- request body size limit,
- connection reuse,
- proxy header forwarding,
- health/readiness endpointleri.

---

# 6-8.6 DB Performance Readiness

DB icin kontrol:
- connection pool,
- query timeout,
- transaction timeout,
- index varligi,
- slow query izi,
- pg_stat_statements izi,
- tenant_id indexleri,
- read/write split izi,
- backup/restore etkisi,
- disk capacity.

---

# 6-8.7 Event Bus Performance Readiness

Event bus icin kontrol:
- publish/consume rate,
- backlog,
- pending,
- consumer lag,
- retry count,
- DLQ count,
- replay etkisi,
- ack wait,
- max deliver,
- consumer durability.

---

# 6-8.8 Tenant-aware Performance

Tenant seviyesinde performans:
- bir tenant tum sistemi yormamali,
- tenant bazli rate limit dusunulmeli,
- tenant bazli DB/query yukleri izlenmeli,
- tenant bazli event backlog izlenmeli,
- tenant bazli reporting/export etkisi izlenmeli.

---

# 6-8.9 Capacity / Scale Decision Gate

Scale kararlari veriyle verilir.

Karar sinyalleri:
- tek VDS yeterli mi?
- read replica gerekli mi?
- worker sayisi artmali mi?
- event consumer parallelism gerekli mi?
- Redis cache artirilmali mi?
- CDN/WAF/edge etkisi gerekli mi?
- multi-node veya cluster gecisi gerekli mi?

---

# 6-8.10 Performance Final Closure Gate

6-8 kapanis kriterleri:

- Performance dokumani hazir olmali.
- Visible checkpoint hazir olmali.
- Runtime audit evidence uretilmeli.
- Real implementation audit uretilmeli.
- Baseline performance evidence olmali.
- Load test readiness yazilmali.
- Stress test readiness yazilmali.
- Bottleneck evidence kaynaklari yazilmali.
- DB/gateway/event performance izleri kontrol edilmeli.
- Timeout/pool/rate-limit/pagination izleri kontrol edilmeli.
- Eksik implementasyon varsa net gorunmeli.
- PASS olmadan 6-9'a gecilmemeli.

---

# 6-8 Muhur Hedefi

FAZ_6_8_DOC_STATUS=READY ✅  
FAZ_6_8_VISIBLE_CHECKPOINTS_STATUS=READY ✅  
FAZ_6_8_RUNTIME_AUDIT_STATUS=COMPLETE ✅  
FAZ_6_8_REAL_IMPLEMENTATION_AUDIT_STATUS=COMPLETE ✅  
FAZ_6_8_TEST_STATUS=PASS ✅  
FAZ_6_8_FINAL_STATUS=PASS_OR_NEEDS_IMPLEMENTATION_REVIEW  
FAZ_6_9_READY=CONDITIONAL  

