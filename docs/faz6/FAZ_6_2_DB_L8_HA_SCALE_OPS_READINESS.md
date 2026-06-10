# Pix2pi — FAZ 6-2 DB-L8 HA / Scale / Ops Readiness

## Faz Bilgisi

Faz: FAZ 6  
Adim: 6-2  
Adim Adi: DB-L8 HA / Scale / Ops Readiness  
Onceki Adim: 6-1 FAZ 6 Master Plan / Scope Freeze  
Onceki Adim Durumu: PASS  
Bu Adim Amaci: PostgreSQL katmanini production scale, HA, ops ve restore hazirligina tasimak  
Risk Seviyesi: Kontrollu  
Runtime Etkisi: Bu adimda destructive DB islemi yoktur  
Sonraki Adim: 6-3 Multi-node Foundation / Scale-out Readiness  

---

# 6-2 Ana Karar

Pix2pi icin DB-L8 hedefi, veritabanini sadece calisan bir PostgreSQL olmaktan cikarip production-ready data platform seviyesine tasimaktir.

Bu adimda hedef:
- read/write split stratejisi,
- replica routing hazirligi,
- connection pool standardi,
- index ve query performans kontrolu,
- PITR / restore drill hazirligi,
- partition / shard readiness modeli,
- DB observability evidence seti,
- final DB-L8 closure gate.

---

# 6-2.1 Read / Write Split Readiness

## 6-2.1.1 Write Path

Transactional yazma islemleri sadece primary/write DB uzerinden yapilir.

Write path kapsami:
- siparis olusturma,
- stok hareketi yazma,
- muhasebe journal yazma,
- ledger posting,
- tenant config yazma,
- kritik audit log yazma,
- idempotency state yazma.

Kural:
- Write islemi read replica uzerinden calismaz.
- Write repository katmani DB_WRITE_DSN veya primary connection kullanir.
- Transaction gereken islerde read fallback yapilmaz.

## 6-2.1.2 Read Path

Okuma trafigi zamanla read DB veya read pool tarafina alinabilir.

Read path kapsami:
- dashboard sorgulari,
- listeleme ekranlari,
- reporting sorgulari,
- export hazirlik sorgulari,
- arama / filtreleme sorgulari,
- read model / projection okumasi.

Kural:
- Kritik anlik tutarlilik gerektiren sorgular primary DB'den okunabilir.
- Reporting ve dashboard trafigi transactional DB'yi yormayacak sekilde ayrilir.
- Read replica lag varsa sistem bunu alarm olarak gorur.

## 6-2.1.3 Fallback

Read replica veya read pool sorununda fallback kontrollu olmalidir.

Fallback kurali:
- Sistem otomatik olarak primary DB'ye sinirsiz yuk bindirmemelidir.
- Fallback sadece kisa sureli ve kontrollu olmalidir.
- Fallback olaylari loglanmalidir.
- Fallback artarsa early warning alarmi uretmelidir.

---

# 6-2.2 Replica Routing / Read Pool Stratejisi

Replica routing amaci:
- okuma yukunu primary DB'den ayirmak,
- raporlama trafigini izole etmek,
- dashboard sorgularinda performans kazanmak,
- ileride reporting store ve projection mimarisine gecisi kolaylastirmak.

Minimum route karar seti:
- write query -> primary
- strongly consistent read -> primary
- eventually consistent read -> read replica
- reporting read -> reporting/read store
- export read -> reporting/read store
- admin audit read -> ihtiyaca gore primary veya replica

Ilk uygulama yaklasimi:
- DB_WRITE_DSN zorunlu kabul edilir.
- DB_READ_DSN varsa read path icin kullanilir.
- DB_READ_DSN yoksa sistem tek DB modunda calisabilir.
- Bu durum production icin warning kabul edilir, blocker degildir.

---

# 6-2.3 Connection Pool Stratejisi

Connection pool olmadan yuk altinda DB darboğazi erken baslar.

Minimum pool politikalari:
- max open connections siniri,
- max idle connections siniri,
- connection max lifetime,
- connection idle timeout,
- query timeout,
- transaction timeout,
- pool saturation metric,
- pool wait count metric,
- pool wait duration metric.

Karar:
- Servis bazli connection limitleri belirlenmelidir.
- Gateway, ERP, reporting ve background worker ayni DB limitlerini sinirsiz kullanmamalidir.
- Tenant sayisi arttikca connection sayisi tenant basina degil servis basina kontrol edilmelidir.

---

# 6-2.4 Index / Query Performance Tuning

DB scale icin ilk kritik nokta sorgu kalitesidir.

Kontrol edilmesi gerekenler:
- slow query log,
- eksik indexler,
- composite index ihtiyaci,
- tenant_id indexleri,
- created_at / status / type filtreleri,
- pagination stratejisi,
- offset yerine cursor kullanimi,
- explain analyze evidence,
- buyuk tablo scan kontrolu.

Minimum Pix2pi index ilkeleri:
- tenant_id bulunan kritik tablolarda tenant_id index stratejisi olmalidir.
- tenant_id + created_at sik kullaniliyorsa composite index dusunulmelidir.
- tenant_id + status sik kullaniliyorsa composite index dusunulmelidir.
- event store tarafinda event_id, tenant_id, created_at, correlation_id alanlari performans icin izlenmelidir.
- financial journal / ledger tarafinda tenant_id, document_id, journal_id, created_at alanlari izlenmelidir.

---

# 6-2.5 PITR / Restore Drill Readiness

Production DB icin sadece backup almak yeterli degildir. Restore edilebildigi kanitlanmalidir.

PITR hedefi:
- WAL arsivleme stratejisi,
- base backup stratejisi,
- restore test ortami,
- restore suresi olcumu,
- veri kaybi toleransi,
- geri donus proseduru.

Minimum drill senaryolari:
- full backup restore,
- belirli zamana geri donus,
- migration sonrasi geri donus,
- yanlis veri yazimi sonrasi geri donus,
- tenant etkili veri kontrolu,
- restore sonrasi smoke test.

---

# 6-2.6 Partition / Shard Readiness Modeli

Simdiki hedef hemen shard yapmak degildir.

Simdiki hedef:
- buyuk tablolarin hangileri olacagini ongormek,
- partition adaylarini belirlemek,
- shard gerektiren esikleri yazmak,
- erken tasarim hatalarini engellemektir.

Partition adaylari:
- event store,
- audit logs,
- ledger entries,
- stock movements,
- orders,
- notifications,
- background jobs,
- reporting projections.

Shard tetikleyicileri:
- tek DB CPU surekli yuksek,
- disk IO darboğazi,
- query latency kalici artisi,
- event store buyumesi,
- tenant bazli yuk dengesizligi,
- backup / restore suresinin kabul edilemez hale gelmesi,
- maintenance window'un yetmemesi.

Ilk shard stratejisi:
- once read/write split,
- sonra reporting store,
- sonra partition,
- sonra tenant-aware shard routing.

---

# 6-2.7 DB Observability / Performance Evidence Seti

DB-L8 kapanmadan once DB icin evidence dosyalari olmalidir.

Toplanacak evidence:
- DB container / service durumu,
- port durumu,
- DB_WRITE_DSN / DB_READ_DSN varlik kontrolu,
- Postgres version bilgisi,
- pg_isready sonucu,
- connection sayisi,
- slow query konfigurasyon durumu,
- backup / restore hazirlik notu,
- disk kullanimi,
- DB log konumu,
- read replica var/yok durumu.

Bu adimda evidence scripti non-destructive calisir.

---

# 6-2.8 DB Final Closure Gate

6-2 kapanis kriterleri:

- DB-L8 master readiness dokumani hazir olmali.
- Read/write split karari yazilmis olmali.
- Replica routing stratejisi yazilmis olmali.
- Connection pool stratejisi yazilmis olmali.
- Index/query tuning kontrol listesi yazilmis olmali.
- PITR/restore drill hedefi yazilmis olmali.
- Partition/shard readiness modeli yazilmis olmali.
- DB observability evidence scripti hazir olmali.
- Test scripti PASS olmali.
- Runtime destructive DB islemi yapilmamis olmali.

---

# 6-2 Risk Notlari

Bu adimda:
- DB silinmez.
- Migration calistirilmaz.
- Schema degistirilmez.
- Replica kurulumu zorlanmaz.
- Sadece plan, standard, evidence ve kontrol kapisi kurulur.

Gercek read replica, PITR ve restore drill islemleri sonraki alt adimlarda kontrollu yapilacaktir.

---

# 6-2 Muhur Hedefi

FAZ_6_2_DOC_STATUS=READY ✅  
FAZ_6_2_AUDIT_SCRIPT=READY ✅  
FAZ_6_2_EVIDENCE_STATUS=READY ✅  
FAZ_6_2_TEST_STATUS=PASS ✅  
FAZ_6_2_FINAL_STATUS=PASS ✅  
FAZ_6_3_READY=YES ✅  

