# Pix2pi — FAZ 6-5 Observability / Early Warning / SRE Dashboard

## Faz Bilgisi

Faz: FAZ 6  
Adim: 6-5  
Adim Adi: Observability / Early Warning / SRE Dashboard  
Onceki Adim: 6-4 Event Bus / Queue / Backlog SRE Readiness  
Onceki Adim Durumu: PASS  
Bu Adim Amaci: Pix2pi sisteminin metrik, dashboard, erken uyari, servis sagligi ve SRE izleme katmanini production readiness seviyesine tasimak  
Risk Seviyesi: Kontrollu  
Runtime Etkisi: Bu adimda destructive operasyon yoktur  
Sonraki Adim: 6-6 Backup / Restore / Disaster Recovery  

---

# 6-5 Ana Karar

Pix2pi production sisteminde sorun olduktan sonra fark etmek kabul edilemez.

Bu adimda hedef:
- sistemin kendini izleyebilmesi,
- darboğazlari erken gosterebilmesi,
- servis down / DB sorun / event backlog / disk dolumu gibi riskleri sinyale cevirmesi,
- SRE dashboard ile tek ekrandan operasyon gorunurlugu vermesi,
- FAZ 6-6 DR adimina guvenli gecis saglamasidir.

---

# 6-5.1 Prometheus Metric Standardi

Prometheus hedefi:
- servis metriklerini toplamak,
- sistem metriklerini toplamak,
- container metriklerini toplamak,
- DB / event / gateway sinyallerini izlemek,
- alarm kurallarina kaynak olmaktir.

Minimum metrik gruplari:
- request count,
- request latency,
- error count,
- service up/down,
- DB connection pool,
- DB latency,
- event publish/consume count,
- event backlog,
- DLQ count,
- CPU/RAM/disk/network,
- container health.

---

# 6-5.2 Grafana Dashboard Seti

Grafana hedefi:
- SRE ekibinin sistemi tek ekrandan gormesi,
- sorun kaynagini hizli ayirmasi,
- servis / DB / event / node seviyelerini ayri panellerde takip etmesidir.

Minimum dashboard seti:
- System Overview,
- Service Health Overview,
- API Gateway Dashboard,
- DB Performance Dashboard,
- Event Bus / Backlog Dashboard,
- Container Runtime Dashboard,
- Tenant Impact Dashboard,
- Incident / Alarm Overview.

---

# 6-5.3 Exporters / System Metrics

Exporters hedefi:
- node seviyesinde CPU/RAM/disk/network gormek,
- container seviyesinde kaynak kullanimi gormek,
- DB / Redis / NATS gibi altyapi katmanlarini metriklestirmektir.

Minimum exporter seti:
- node_exporter,
- cAdvisor,
- Prometheus scrape config,
- opsiyonel postgres_exporter,
- opsiyonel redis_exporter,
- opsiyonel nats exporter veya NATS monitoring endpointleri.

---

# 6-5.4 Early Warning Alarm Matrix

Early warning hedefi:
- sistem kirilmadan once sinyal uretmek,
- scale / upgrade / incident kararini erken verdirmektir.

Alarm kategorileri:
- CPU surekli yuksek,
- RAM surekli yuksek,
- disk doluluk riski,
- disk IO darboğazi,
- DB connection saturation,
- DB query latency artisi,
- event backlog artisi,
- DLQ artisi,
- gateway 5xx artisi,
- servis down,
- response latency artisi,
- backup gecikmesi,
- tenant bazli anormal trafik.

---

# 6-5.5 Service Health / Mission Control

Service health hedefi:
- servislerin UP/DOWN durumunu gormek,
- health summary uretmek,
- Mission Control / Service Registry tarafina kaynak olmaktir.

Minimum kontroller:
- identity-api health,
- api-gateway health,
- mission-control health,
- service-registry health,
- event-consumer health,
- DB health,
- Redis health,
- NATS health,
- Grafana / Prometheus health.

---

# 6-5.6 DB / Event / Gateway Signals

DB sinyalleri:
- connection pool kullanimi,
- slow query,
- transaction latency,
- replication/readiness,
- disk buyumesi,
- backup durumu.

Event sinyalleri:
- publish rate,
- consume rate,
- backlog,
- pending,
- retry,
- DLQ,
- replay,
- consumer health.

Gateway sinyalleri:
- request count,
- latency,
- 4xx,
- 5xx,
- upstream timeout,
- rate limit,
- tenant bazli trafik.

---

# 6-5.7 Tenant-level Observability

Tenant seviyesinde izleme hedefi:
- tek tenant sistem kaynaklarini zorluyor mu gormek,
- tenant bazli hata oranini gormek,
- tenant bazli event backlog veya rapor yukunu gormek,
- cross-tenant sorunlari ayirmaktir.

Minimum tenant sinyalleri:
- tenant_id request count,
- tenant_id error count,
- tenant_id latency,
- tenant_id event count,
- tenant_id DB/query etkisi,
- tenant_id export/report etkisi.

---

# 6-5.8 Log / Trace / Correlation

Log ve trace hedefi:
- request_id ile istegi izlemek,
- correlation_id ile event zincirini izlemek,
- tenant_id ile izolasyonlu olay takibi yapmak,
- incident root cause analizini kolaylastirmaktir.

Minimum alanlar:
- request_id,
- correlation_id,
- causation_id,
- tenant_id,
- user_id opsiyonel,
- service_name,
- route,
- status_code,
- duration_ms,
- error_code.

---

# 6-5.9 SRE Dashboard Closure Gate

6-5 kapanis kriterleri:

- Observability dokumani hazir olmali.
- Visible checkpoint hazir olmali.
- Runtime audit evidence uretilmeli.
- Real implementation audit uretilmeli.
- Prometheus izi kontrol edilmeli.
- Grafana izi kontrol edilmeli.
- node_exporter / cAdvisor izi kontrol edilmeli.
- service health izi kontrol edilmeli.
- early warning / alert izi kontrol edilmeli.
- DB / event / gateway sinyalleri kontrol edilmeli.
- tenant-aware observability izi kontrol edilmeli.
- log / trace / correlation izi kontrol edilmeli.
- Eksik implementasyon varsa net gorunmeli.
- PASS olmadan 6-6'ya gecilmemeli.

---

# 6-5 Muhur Hedefi

FAZ_6_5_DOC_STATUS=READY ✅  
FAZ_6_5_VISIBLE_CHECKPOINTS_STATUS=READY ✅  
FAZ_6_5_RUNTIME_AUDIT_STATUS=COMPLETE ✅  
FAZ_6_5_REAL_IMPLEMENTATION_AUDIT_STATUS=COMPLETE ✅  
FAZ_6_5_TEST_STATUS=PASS ✅  
FAZ_6_5_FINAL_STATUS=PASS_OR_NEEDS_IMPLEMENTATION_REVIEW  
FAZ_6_6_READY=CONDITIONAL  

