# Pix2pi — FAZ 6-4 Event Bus / Queue / Backlog SRE Readiness

## Faz Bilgisi

Faz: FAZ 6  
Adim: 6-4  
Adim Adi: Event Bus / Queue / Backlog SRE Readiness  
Onceki Adim: 6-3 Multi-node Foundation / Scale-out Readiness  
Onceki Adim Durumu: PASS  
Bu Adim Amaci: Event bus, queue, backlog, retry, DLQ, replay ve SRE operasyon hazirligini kanitlamak  
Risk Seviyesi: Kontrollu  
Runtime Etkisi: Bu adimda destructive event operasyonu yoktur  
Sonraki Adim: 6-5 Observability / Early Warning / SRE Dashboard  

---

# 6-4 Ana Karar

Pix2pi mimarisinde event bus kritik omurgadir.

Bu adimda hedef:
- NATS / JetStream runtime sagligini kontrol etmek,
- consumer / subscriber izlerini dogrulamak,
- backlog / pending / lag sinyallerini okumak,
- retry / ack / nack davranisini kontrol etmek,
- DLQ ve dead-letter izlerini dogrulamak,
- replay kabiliyetini audit etmek,
- poison message ve failed event davranisini netlestirmek,
- tenant-aware event metadata izlerini kontrol etmek,
- SRE kapanis kapisini olusturmaktir.

---

# 6-4.1 Event Bus Runtime Health

## 6-4.1.1 NATS / JetStream Runtime

Kontrol edilecekler:
- NATS container veya service ayakta mi?
- 4222 client portu dinliyor mu?
- 8222 monitoring portu dinliyor mu?
- JetStream aktif mi?
- stream / consumer bilgisi okunabiliyor mu?

## 6-4.1.2 Event Publisher

Publisher katmani:
- event schema kullanmali,
- event_id uretmeli,
- tenant_id tasimali,
- correlation_id tasimali,
- created_at tasimali,
- publish sonucunu loglamali.

## 6-4.1.3 Event Consumer

Consumer katmani:
- durable consumer kullanmali,
- ack/nack davranisi net olmali,
- retry davranisi net olmali,
- idempotency ile duplicate etkisini engellemeli,
- fail durumunda DLQ veya failed state uretmeli.

---

# 6-4.2 Backlog / Pending / Lag Standardi

Backlog SRE icin kritik sinyaldir.

Kontrol edilecekler:
- pending message sayisi,
- consumer lag,
- ack floor,
- redelivery sayisi,
- consumer inactive durumu,
- max deliver yaklasma durumu,
- stream storage buyumesi,
- queue processing latency.

Alarm karari:
- backlog surekli artiyorsa alarm uretir.
- consumer down ise alarm uretir.
- DLQ artiyorsa alarm uretir.
- replay sonrasi backlog anormal buyurse alarm uretir.

---

# 6-4.3 Retry / Ack / Nack Standardi

Retry standardi:
- gecici hata retry edilir,
- kalici hata DLQ veya failed event olarak ayrilir,
- retry sayisi sinirlidir,
- retry davranisi loglanir,
- retry idempotent olmalidir.

Ack standardi:
- is basariliysa ack edilir,
- islenemeyen ama tekrar denenebilir mesaj nack edilir,
- poison mesaj sonsuz retry edilmez,
- ack kaybi finansal duplicate uretmemelidir.

---

# 6-4.4 DLQ / Dead-letter Standardi

DLQ hedefi:
- islenemeyen event kaybolmasin,
- ana queue tikanmasin,
- operator inceleyebilsin,
- replay veya manuel fix karari verilebilsin.

DLQ kaydinda olmasi gerekenler:
- original event_id,
- tenant_id,
- subject/topic,
- failure reason,
- retry count,
- first failure time,
- last failure time,
- payload snapshot veya referans,
- correlation_id.

---

# 6-4.5 Replay Standardi

Replay hedefi:
- kaybolan projection yeniden kurulabilsin,
- event store’dan kontrollu yeniden isleme yapilabilsin,
- tenant bazli replay mumkun olsun,
- idempotency duplicate etkiyi engellesin.

Replay kurallari:
- production replay operator onayi ister.
- tenant filtresi zorunludur.
- replay dry-run modu olmalidir.
- replay sonucu evidence uretmelidir.
- replay finansal double-posting yaratmamalidir.

---

# 6-4.6 Poison Message Runbook

Poison message:
- her retry’da fail eden,
- schema bozuk olan,
- tenant bilgisi eksik olan,
- domain validation’dan gecmeyen,
- consumer bug’ini tetikleyen mesajdir.

Runbook:
- mesaj DLQ’ya ayrilir,
- incident kaydi acilir,
- root cause bulunur,
- fix uygulanir,
- gerekiyorsa replay yapilir,
- operator kapanis notu yazar.

---

# 6-4.7 Idempotency / Dedupe Standardi

Event platformda idempotency zorunludur.

Kontrol:
- event_id tekilligi,
- idempotency key,
- processed event store,
- duplicate event testi,
- replay-safe consumer,
- accounting double-posting korumasi.

---

# 6-4.8 Tenant-aware Event Safety

Her event tenant-aware olmalidir.

Zorunlu alanlar:
- tenant_id veya tenant_uuid,
- event_id,
- event_type,
- correlation_id,
- causation_id,
- created_at,
- source_service.

Kurallar:
- tenant_id eksik event islenmez.
- tenant mismatch event islenmez.
- cross-tenant replay yasaktir.
- DLQ ve audit kayitlari tenant bilgisini tasir.

---

# 6-4.9 Event Observability

Event bus observability:
- publish count,
- consume count,
- ack count,
- nack count,
- retry count,
- DLQ count,
- backlog gauge,
- consumer lag,
- replay count,
- poison message count,
- processing latency.

Bu metrikler 6-5 Observability adiminda dashboard / alert tarafina baglanacaktir.

---

# 6-4.10 Event Bus Final Closure Gate

6-4 kapanis kriterleri:

- Event bus SRE dokumani hazir olmali.
- Visible checkpoint hazir olmali.
- Runtime audit evidence uretilmeli.
- Real implementation audit uretilmeli.
- NATS / JetStream izi kontrol edilmeli.
- Consumer / subscriber izi kontrol edilmeli.
- Ack / nack / retry izi kontrol edilmeli.
- DLQ izi kontrol edilmeli.
- Replay izi kontrol edilmeli.
- Idempotency izi kontrol edilmeli.
- Tenant-aware event metadata izi kontrol edilmeli.
- Backlog / lag / pending izi kontrol edilmeli.
- Eksik implementasyon varsa net gorunmeli.
- PASS olmadan 6-5'e gecilmemeli.

---

# 6-4 Muhur Hedefi

FAZ_6_4_DOC_STATUS=READY ✅  
FAZ_6_4_VISIBLE_CHECKPOINTS_STATUS=READY ✅  
FAZ_6_4_RUNTIME_AUDIT_STATUS=COMPLETE ✅  
FAZ_6_4_REAL_IMPLEMENTATION_AUDIT_STATUS=COMPLETE ✅  
FAZ_6_4_TEST_STATUS=PASS ✅  
FAZ_6_4_FINAL_STATUS=PASS_OR_NEEDS_IMPLEMENTATION_REVIEW  
FAZ_6_5_READY=CONDITIONAL  

