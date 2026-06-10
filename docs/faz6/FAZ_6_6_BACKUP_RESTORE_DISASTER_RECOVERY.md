# Pix2pi — FAZ 6-6 Backup / Restore / Disaster Recovery

## Faz Bilgisi

Faz: FAZ 6  
Adim: 6-6  
Adim Adi: Backup / Restore / Disaster Recovery  
Onceki Adim: 6-5 Observability / Early Warning / SRE Dashboard  
Onceki Adim Durumu: PASS  
Bu Adim Amaci: Pix2pi sisteminin yedek, geri donus, disaster recovery ve is surekliligi hazirligini kanitlamak  
Risk Seviyesi: Kontrollu  
Runtime Etkisi: Bu adimda destructive restore operasyonu yoktur  
Sonraki Adim: 6-7 Security Hardening / Production Guardrails  

---

# 6-6 Ana Karar

Production sistemde backup almak tek basina yeterli degildir.

Asil hedef:
- backup alindigini kanitlamak,
- backup'in korunabildigini kanitlamak,
- restore edilebilir oldugunu kanitlamak,
- RPO / RTO hedeflerini yazmak,
- disaster senaryolarini netlestirmek,
- restore drill icin guvenli prosedur olusturmaktir.

Bu adimda destructive restore yapilmaz. Restore drill hazirlik, evidence ve runbook standardi kurulur.

---

# 6-6.1 Backup Inventory

## 6-6.1.1 Database Backup

DB backup kapsami:
- PostgreSQL data,
- schema/migration durumu,
- tenant verileri,
- event store,
- journal / ledger kayitlari,
- audit logs,
- reporting/read model verisi.

Minimum yontemler:
- pg_dump veya logical backup,
- volume/file backup,
- restic snapshot,
- opsiyonel WAL/PITR hazirligi.

## 6-6.1.2 File / Config Backup

Backup kapsami:
- repo kritik configleri,
- /etc/pix2pi,
- /opt/pix2pi,
- nginx configleri,
- systemd service dosyalari,
- env dosyalari,
- scripts,
- docs/evidence,
- public static dosyalari.

## 6-6.1.3 Backup Repository

Backup repository icin kontrol:
- repo path var mi,
- snapshot listelenebiliyor mu,
- sifre/secret guvenli mi,
- disk kapasitesi yeterli mi,
- retention calisiyor mu,
- backup loglari var mi.

---

# 6-6.2 Restore Drill Readiness

## 6-6.2.1 Restore Drill Yaklasimi

Restore drill destructive olmadan planlanir.

Asama:
- once snapshot listelenir,
- sonra restore hedef klasoru belirlenir,
- sonra test DB veya staging ortami belirlenir,
- sonra smoke test seti calistirilir,
- sonra restore sonucu evidence olarak kaydedilir.

## 6-6.2.2 Restore Smoke Test

Restore sonrasi minimum smoke test:
- PostgreSQL aciliyor mu?
- migration seviyesi uyumlu mu?
- tenant schema / tenant rows gorunuyor mu?
- identity health calisiyor mu?
- api-gateway health calisiyor mu?
- event bus baglantisi calisiyor mu?
- kritik endpoint smoke test geciyor mu?

## 6-6.2.3 Restore Safety

Restore kurallari:
- production DB uzerine direkt restore yapilmaz,
- once ayrik klasor / staging / test DB kullanilir,
- eski state yedeklenmeden yeni restore uygulanmaz,
- restore komutu operator onayi olmadan calismaz,
- restore logu kaydedilir.

---

# 6-6.3 RPO / RTO Hedefleri

## 6-6.3.1 RPO

RPO, maksimum kabul edilebilir veri kaybi suresidir.

Pix2pi ilk hedef:
- kritik DB icin dusuk RPO,
- config/repo icin snapshot bazli RPO,
- public static dosyalar icin restore edilebilir RPO,
- event store icin mumkun olan en dusuk kayip.

## 6-6.3.2 RTO

RTO, sistemin kabul edilebilir geri donus suresidir.

Pix2pi ilk hedef:
- tek VDS seviyesinde hizli geri donus,
- DB restore suresinin olculmesi,
- nginx/domain/config restore suresinin olculmesi,
- servislerin tekrar ayaga kalkma suresinin olculmesi.

## 6-6.3.3 Hedeflerin Olculmesi

RPO/RTO hedefleri sadece yazili kalmamalidir.

Olcum:
- backup suresi,
- snapshot listelenme suresi,
- restore hazirlik suresi,
- DB acilis suresi,
- smoke test suresi,
- toplam recovery suresi.

---

# 6-6.4 Disaster Scenario Seti

## 6-6.4.1 DB Kaybi

Senaryo:
- DB container bozuldu,
- volume bozuldu,
- migration hatali calisti,
- veri yanlis yazildi.

Aksiyon:
- backup snapshot sec,
- restore hedefi belirle,
- DB restore et,
- smoke test calistir,
- incident kaydi kapat.

## 6-6.4.2 Disk Dolumu

Senaryo:
- loglar disk doldurdu,
- backup repo buyudu,
- docker volume buyudu,
- event store buyudu.

Aksiyon:
- disk alarmi,
- retention calistir,
- buyuk dosya analizi,
- gereksiz artifact temizligi,
- backup guvenligi kontrolu.

## 6-6.4.3 Config Bozulmasi

Senaryo:
- env bozuldu,
- nginx config bozuldu,
- systemd service bozuldu,
- compose dosyasi bozuldu.

Aksiyon:
- config backup sec,
- onceki versiyona don,
- nginx -t calistir,
- systemctl daemon-reload,
- smoke test calistir.

## 6-6.4.4 Node Kaybi

Senaryo:
- VDS erisilemez oldu,
- network kesildi,
- makine boot etmiyor,
- provider kaynak sorunu var.

Aksiyon:
- yeni node hazirla,
- repo/config restore et,
- DB/volume restore et,
- DNS/edge yonlendir,
- smoke test calistir.

## 6-6.4.5 Event Bus Kaybi

Senaryo:
- NATS/JetStream store bozuldu,
- stream/consumer kaybi oldu,
- backlog patladi.

Aksiyon:
- event store ve backup durumunu kontrol et,
- consumer state kontrol et,
- replay runbook calistir,
- DLQ / failed events kontrol et.

---

# 6-6.5 Retention / Cron / Backup Logs

Backup sistemi icin gozlem zorunludur.

Kontrol:
- cron aktif mi,
- retention script var mi,
- backup script var mi,
- ops_retention_cleanup.log var mi,
- backup loglari var mi,
- son backup/snapshot tarihi izleniyor mu,
- retention guard korunan klasorleri siliyor mu,
- backup repo kapasitesi yeterli mi.

---

# 6-6.6 PITR / WAL Readiness

PITR hedefi:
- WAL arsivleme stratejisi,
- archive_mode,
- archive_command,
- base backup,
- recovery target time,
- pg_basebackup,
- restore command standardi.

Bu adimda PITR tam uygulanmak zorunda degildir; fakat izleri ve hazirlik karari audit ile gorunmelidir.

---

# 6-6.7 DR Runbook / Incident Flow

Disaster durumunda operator ne yapacagini bilmelidir.

Runbook alanlari:
- olay tipi,
- etkilenen servis,
- etkilenen tenant,
- baslangic zamani,
- son saglam backup,
- restore hedefi,
- uygulanan komutlar,
- smoke test sonucu,
- kapanis notu.

---

# 6-6.8 Backup / Restore Final Closure Gate

6-6 kapanis kriterleri:

- Backup / Restore / DR dokumani hazir olmali.
- Visible checkpoint hazir olmali.
- Runtime audit evidence uretilmeli.
- Real implementation audit uretilmeli.
- Backup script izi kontrol edilmeli.
- Restore script/prosedur izi kontrol edilmeli.
- Restic / pg_dump / pg_restore izi kontrol edilmeli.
- Cron / retention izi kontrol edilmeli.
- Backup loglari kontrol edilmeli.
- RPO / RTO hedefleri yazilmali.
- Disaster scenario seti yazilmali.
- Eksik implementasyon varsa net gorunmeli.
- PASS olmadan 6-7'ye gecilmemeli.

---

# 6-6 Muhur Hedefi

FAZ_6_6_DOC_STATUS=READY ✅  
FAZ_6_6_VISIBLE_CHECKPOINTS_STATUS=READY ✅  
FAZ_6_6_RUNTIME_AUDIT_STATUS=COMPLETE ✅  
FAZ_6_6_REAL_IMPLEMENTATION_AUDIT_STATUS=COMPLETE ✅  
FAZ_6_6_TEST_STATUS=PASS ✅  
FAZ_6_6_FINAL_STATUS=PASS_OR_NEEDS_IMPLEMENTATION_REVIEW  
FAZ_6_7_READY=CONDITIONAL  

