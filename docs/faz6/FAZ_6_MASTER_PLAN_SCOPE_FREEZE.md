# Pix2pi — FAZ 6 Master Plan / Scope Freeze

## Faz Kimligi

Faz: FAZ 6  
Adim: 6-1  
Adim Adi: FAZ 6 Master Plan / Scope Freeze  
Durum: SCOPE_FREEZE  
Amac: Scale / SRE / DR / Production Hardening  
Onceki Faz: FAZ 5  
Onceki Faz Durumu: PASS / SEALED  
Sonraki Hazirlik: 6-2 DB-L8 HA / Scale / Ops Readiness  

---

## FAZ 5 Son Muhur

FAZ_5_12_TEST_STATUS=PASS ✅  
FAZ_5_FINAL_STATUS=PASS ✅  
FAZ_5_FINAL_SEAL_STATUS=SEALED ✅  
FAZ_5_COMMERCIAL_READY=YES ✅  
FAZ_5_FINAL_GO_DECISION=GO ✅  
FAZ_5_FINAL_BLOCKER_COUNT=0  
FAZ_6_READY=YES ✅  

---

# 6-1 — FAZ 6 Master Plan / Scope Freeze

## 6-1.1 Faz 6 Ana Hedefi

FAZ 6'nin ana hedefi Pix2pi sistemini ticari hazirliktan production-grade isletim seviyesine tasimaktir.

Bu fazda hedef:
- olceklenebilirlik hazirligi,
- SRE operasyon standardi,
- disaster recovery,
- backup / restore dogrulamalari,
- production hardening,
- edge / WAF / DNS duzeni,
- release / rollback guvenligi,
- incident / runbook disiplini,
- final production readiness gate.

## 6-1.2 Faz 6 Kapsam Karari

FAZ 6 yeni ticari ozellik fazi degildir.

Bu fazda ana odak:
- mevcut cekirdegi sertlestirmek,
- sistemin yuk altinda davranisini olcmek,
- hata durumunda geri donus kabiliyeti kurmak,
- observability ve alarm katmanini tamamlamak,
- production acilisina engel riskleri kapatmaktir.

## 6-1.3 Faz 6 Kapsam Disi Kararlar

Bu fazda asagidaki isler ana hedef degildir:

- Yeni ERP modulu yazmak
- Yeni marketplace ozelligi gelistirmek
- Gercek odeme saglayici entegrasyonunu tamamlamak
- Gercek CRM/runtime support sistemine gecmek
- Public launch kampanyasi yapmak
- Native mobil uygulama yazmak
- Muhasebe exportlarini derinlestirmek
- e-Fatura / e-Arsiv / e-Adisyon entegrasyonlarini tamamlamak

Bu isler FAZ 7 ve sonrasi icin ayrilir.

---

# FAZ 6 Master Sira

## 6-1 FAZ 6 Master Plan / Scope Freeze

### 6-1.1 Faz hedefi
FAZ 6 amaci netlestirilir.

### 6-1.2 Faz kapsami
Scale / SRE / DR / Production Hardening kapsami sabitlenir.

### 6-1.3 Faz disi isler
Faz disina alinacak isler belirlenir.

### 6-1.4 Test ve cikis kurali
Her adim icin test scripti ve PASS / FAIL muhru zorunlu hale getirilir.

### 6-1.5 Muhur
FAZ_6_1_STATUS=PASS olmadan 6-2'ye gecilmez.

---

## 6-2 DB-L8 HA / Scale / Ops Readiness

### 6-2.1 Read / write split readiness
Write DB ve read DB ayrimi icin strateji netlestirilir.

#### 6-2.1.1 Write path
Transactional yazma trafigi sadece write DB uzerinden akar.

#### 6-2.1.2 Read path
Raporlama ve yogun okuma trafigi read pool'a hazirlanir.

#### 6-2.1.3 Fallback
Read replica sorununda kontrollu fallback kurali yazilir.

### 6-2.2 Replica routing / read pool stratejisi
Gateway / repository katmaninda okuma yonlendirme karari hazirlanir.

### 6-2.3 Connection pool stratejisi
Max connection, idle connection, timeout ve pool saturation alarmi belirlenir.

### 6-2.4 Index / query performance tuning
Yavas sorgular, eksik indexler ve query plan analizleri icin kontrol seti kurulur.

### 6-2.5 PITR / restore drill readiness
Point-in-time recovery stratejisi ve restore tatbikati hazirlanir.

### 6-2.6 Partition / shard readiness modeli
Buyuk tablolar icin partition ve ileride shard karari dokumante edilir.

### 6-2.7 DB observability / perf evidence seti
DB metrikleri, slow query evidence ve capacity sinirlari takip edilir.

### 6-2.8 DB final closure gate
DB-L8 kapanis testi ve muhru yapilir.

---

## 6-3 Multi-node Foundation / Scale-out Readiness

### 6-3.1 Cok node servis yerlesimi
Servislerin tek makineden cok node'a tasinabilirligi kontrol edilir.

### 6-3.2 Stateful / stateless ayrimi
Stateless servisler yatay olceklenebilir hale getirilir.

### 6-3.3 Service discovery runtime tuning
Servis bulma ve upstream davranisi sertlestirilir.

### 6-3.4 Load balancer hazirligi
Nginx / edge / gateway uzerinden cok instance yonlendirme modeli hazirlanir.

### 6-3.5 Health / readiness / liveness standardi
Servislerin ayakta olmasi ile hazir olmasi ayrilir.

### 6-3.6 Scale-out closure gate
Multi-node hazirlik testi ve muhru yapilir.

---

## 6-4 Event Bus / Queue / Backlog SRE Readiness

### 6-4.1 Event bus runtime health
NATS / JetStream saglik kontrolleri production seviyesine tasinir.

### 6-4.2 Backlog olcum standardi
Queue backlog, consumer lag ve pending message alarmi tanimlanir.

### 6-4.3 DLQ operasyon standardi
DLQ'ya dusen eventlerin nasil incelenecegi belirlenir.

### 6-4.4 Replay operasyon standardi
Replay islemleri kontrollu, tenant-safe ve idempotent hale getirilir.

### 6-4.5 Poison message runbook
Surekli fail eden mesajlar icin operasyon plani yazilir.

### 6-4.6 Event bus closure gate
Backlog / DLQ / replay testleri ile kapanis yapilir.

---

## 6-5 Observability / Early Warning / SRE Dashboard

### 6-5.1 Prometheus metrik standardi
Servis, DB, event bus, gateway ve sistem metrikleri standartlasir.

### 6-5.2 Grafana dashboard seti
Production izleme panelleri hazirlanir.

### 6-5.3 Early warning alarm matrisi
CPU, RAM, IO, DB, event backlog, service down ve latency alarmlari kurulur.

### 6-5.4 Tenant etkisi izleme
Tenant bazli yuk, hata ve gecikme ayrimi takip edilir.

### 6-5.5 SRE dashboard closure gate
Alarm ve dashboard testleri ile kapanis yapilir.

---

## 6-6 Backup / Restore / Disaster Recovery

### 6-6.1 Backup inventory
Hangi verinin nerede ve ne siklikla yedeklendigi netlestirilir.

### 6-6.2 Restore drill
Yedekten geri donus tatbikati yapilir.

### 6-6.3 RPO / RTO hedefleri
Veri kaybi toleransi ve geri donus suresi hedefleri belirlenir.

### 6-6.4 Disaster scenario seti
DB kaybi, servis kaybi, disk dolumu, config bozulmasi, node kaybi senaryolari yazilir.

### 6-6.5 DR closure gate
Backup / restore / DR testi ile kapanis yapilir.

---

## 6-7 Security Hardening / Production Guardrails

### 6-7.1 Secret / env hardening
Secret degerleri, env dosyalari ve permission kontrolleri sertlestirilir.

### 6-7.2 Nginx hardening
Header, timeout, body size, TLS ve public/private route ayrimi kontrol edilir.

### 6-7.3 Firewall / port policy
Acik portlar ve servis exposure kontrol edilir.

### 6-7.4 Tenant isolation production check
Tenant guvenligi production kapisinda tekrar dogrulanir.

### 6-7.5 Security closure gate
Security hardening testi ile kapanis yapilir.

---

## 6-8 Performance / Load / Stress Readiness

### 6-8.1 Baseline performance
Mevcut tek node performans siniri olculur.

### 6-8.2 Load test
Normal yuk altinda servis davranisi test edilir.

### 6-8.3 Stress test
Sistemin kirilma noktasi kontrollu sekilde bulunur.

### 6-8.4 Bottleneck evidence
DB, CPU, RAM, IO, event backlog ve gateway darboğazlari raporlanir.

### 6-8.5 Performance closure gate
Load / stress evidence ile kapanis yapilir.

---

## 6-9 Release / Rollback / Deploy Safety

### 6-9.1 Release standardi
Versiyonlama, release notu ve deploy hazirlik listesi kurulur.

### 6-9.2 Rollback standardi
Kod, config, DB migration ve static dosyalar icin geri donus plani yazilir.

### 6-9.3 Pre-deploy check
Deploy oncesi otomatik kontrol scripti hazirlanir.

### 6-9.4 Post-deploy check
Deploy sonrasi saglik ve smoke testleri zorunlu hale getirilir.

### 6-9.5 Release closure gate
Rollback ve deploy safety testi ile kapanis yapilir.

---

## 6-10 CDN / WAF / DNS / Edge Readiness

### 6-10.1 DNS inventory
Domain, subdomain, routing ve hedef servisler listelenir.

### 6-10.2 CDN policy
Static dosya ve public sayfa cache stratejisi belirlenir.

### 6-10.3 WAF policy
Bot, rate limit, path protection ve basic threat rules hazirlanir.

### 6-10.4 Edge rate limit
Gateway ve edge rate limit uyumu kontrol edilir.

### 6-10.5 Edge closure gate
DNS / CDN / WAF testi ile kapanis yapilir.

---

## 6-11 Ops Console / Incident / Runbook Readiness

### 6-11.1 Ops console inventory
Hangi operasyonlarin panelden gorulecegi belirlenir.

### 6-11.2 Incident severity matrix
P1 / P2 / P3 olay siniflandirmasi yapilir.

### 6-11.3 Runbook seti
Service down, DB issue, event backlog, disk full, restore, rollback runbooklari yazilir.

### 6-11.4 Incident log standardi
Incident kaydi, aksiyon, kok neden ve kapanis standardi kurulur.

### 6-11.5 Ops closure gate
Runbook / incident testi ile kapanis yapilir.

---

## 6-12 Production Readiness / Final Hardening Gate

### 6-12.1 Final checklist
Tum FAZ 6 kontrolleri tek final listede toplanir.

### 6-12.2 Blocker review
Kritik engeller ve production riskleri sayilir.

### 6-12.3 Final smoke test
Gateway, DB, event bus, backup, observability ve public endpointler test edilir.

### 6-12.4 Final Go / No-Go
Production hardening icin final karar verilir.

### 6-12.5 Final seal
FAZ_6_FINAL_STATUS=PASS ise FAZ 6 muhurlenir.

---

# Faz 6 Genel Cikis Kriterleri

FAZ 6 bitmis sayilmasi icin:

- DB HA / scale / ops readiness tamamlanmis olmali
- Multi-node hazirlik dokumante ve test edilmis olmali
- Event bus backlog / DLQ / replay operasyon standardi hazir olmali
- Observability dashboard ve early warning alarm seti olmali
- Backup / restore / DR tatbikati gecmis olmali
- Security hardening production guardrail testleri gecmis olmali
- Performance / load / stress evidence olusmus olmali
- Release / rollback / deploy safety testleri gecmis olmali
- CDN / WAF / DNS / edge readiness tamamlanmis olmali
- Ops console / incident / runbook hazir olmali
- Final production hardening gate PASS olmali

---

# Faz 6 Uygulama Kurali

Her adimda:

1. Once yedek alinir.
2. Dosya gerekiyorsa `cat <<'EOF'` ile tam yazilir.
3. EOF kesilmez.
4. Test scripti yazilir.
5. Test ciktisinda 6-x, 6-x.x, 6-x.x.x seviyeleri tek tek OK ✅ gorunur.
6. Test sonunda net sonuc verilir:
   - OK ✅
   - HATA ❌
7. Adim bitince yapilan isler alt dallariyla ozetlenir.
8. PASS olmadan sonraki adima gecilmez.

---

# FAZ 6-1 Muhur Hedefi

FAZ_6_1_PLAN_FILE=READY ✅  
FAZ_6_1_SCOPE_FREEZE=YES ✅  
FAZ_6_1_TEST_SCRIPT=READY ✅  
FAZ_6_1_TEST_STATUS=PASS ✅  
FAZ_6_1_FINAL_STATUS=PASS ✅  
FAZ_6_2_READY=YES ✅  

