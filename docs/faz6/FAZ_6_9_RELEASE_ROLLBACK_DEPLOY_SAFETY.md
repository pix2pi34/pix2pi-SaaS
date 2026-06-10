# Pix2pi — FAZ 6-9 Release / Rollback / Deploy Safety

## Faz Bilgisi

Faz: FAZ 6  
Adim: 6-9  
Adim Adi: Release / Rollback / Deploy Safety  
Onceki Adim: 6-8 Performance / Load / Stress Readiness  
Onceki Adim Durumu: PASS  
Bu Adim Amaci: Pix2pi sisteminde release, pre-deploy, post-deploy smoke, rollback ve deploy safety standardini production seviyesine tasimak  
Risk Seviyesi: Kontrollu  
Runtime Etkisi: Bu adim deploy, restart veya rollback calistirmaz; guvenli kontrol ve evidence uretir  
Sonraki Adim: 6-10 CDN / WAF / DNS / Edge Readiness  

---

# 6-9 Ana Karar

Production sistemde deploy sadece dosya kopyalamak degildir.

Deploy guvenligi icin hedef:
- deploy oncesi riskleri yakalamak,
- deploy sonrasi smoke testleri zorunlu hale getirmek,
- rollback icin geri donus noktasini hazir tutmak,
- migration / config / nginx / systemd / docker risklerini ayirmak,
- release kararini evidence ile vermektir.

Bu adimda gercek deploy yapilmaz. Deploy safety scriptleri ve audit kapisi kurulur.

---

# 6-9.1 Release Standardi

Release standardi:
- release ID veya timestamp olmalidir,
- degisiklik notu olmalidir,
- onceki stabil duruma donus noktasi bilinmelidir,
- etkilenen servisler listelenmelidir,
- migration var/yok bilgisi ayrilmalidir,
- config degisikligi var/yok bilgisi ayrilmalidir.

Minimum release alanlari:
- release_id,
- commit hash veya artifact id,
- operator,
- tarih,
- etkilenen servisler,
- risk seviyesi,
- predeploy sonucu,
- postdeploy sonucu,
- rollback noktasi.

---

# 6-9.2 Pre-deploy Check

Pre-deploy hedefi:
- deploy baslamadan once sistemin hazir oldugunu kanitlamak.

Kontrol:
- disk yeterli mi?
- backup var mi?
- nginx -t geciyor mu?
- docker/systemd servisleri gorunuyor mu?
- env dosyalari mevcut mu?
- kritik portlar dinliyor mu?
- health endpointler cevap veriyor mu?
- git durumu okunabiliyor mu?
- rollback icin backup dizini var mi?

Pre-deploy script destructive islem yapmaz.

---

# 6-9.3 Post-deploy Smoke Test

Post-deploy smoke hedefi:
- deploy sonrasi sistemin minimum yasam belirtisini kanitlamak.

Kontrol:
- identity health,
- gateway health,
- prometheus ready,
- grafana health,
- node exporter metrics,
- cAdvisor metrics,
- NATS monitoring,
- public endpoint opsiyonel smoke,
- nginx config check.

Smoke test sonucunda:
- OK sayisi,
- WARN sayisi,
- FAIL sayisi,
- evidence dosyasi uretilmelidir.

---

# 6-9.4 Rollback Standardi

Rollback hedefi:
- sorunlu release sonrasi guvenli onceki duruma donmektir.

Rollback kaynaklari:
- kod backup,
- config backup,
- nginx backup,
- systemd backup,
- DB backup,
- static file backup,
- release artifact backup,
- git commit/tag bilgisi.

Rollback kurallari:
- backup olmadan rollback denenmez.
- DB migration rollback ayri degerlendirilir.
- rollback sonrasi smoke test zorunludur.
- rollback olayi incident kaydina yazilir.
- production rollback operator onayi gerektirir.

---

# 6-9.5 Migration Safety

Migration risklidir.

Kontrol:
- migration dosyalari var mi?
- destructive migration var mi?
- down migration var mi?
- migration oncesi DB backup var mi?
- migration sonrasi smoke test var mi?
- tenant isolation bozuluyor mu?
- index creation uzun sure kilit uretir mi?

Minimum kural:
- production migration oncesi DB backup zorunludur.
- schema degisikligi smoke test ile dogrulanir.

---

# 6-9.6 Config / Nginx / Systemd Deploy Safety

Kontrol:
- nginx -t gecmeden reload yoktur.
- systemd daemon-reload gerektiren degisiklikler kaydedilir.
- env degisikligi etkilenen servislerle eslestirilir.
- public/private route ayrimi bozulmaz.
- port conflict yoktur.
- service restart oncesi rollback noktasi bilinir.

---

# 6-9.7 Static / Public Page Deploy Safety

Kontrol:
- public static dosya yedegi alinmistir.
- hedef dizin dogrudur.
- ownership/permission uygundur.
- GET 200 content check yapilir.
- sadece HEAD degil, GET content dogrulamasi yapilir.
- browser/public erişim dogrulanir.

Not:
FAZ 4D-11 deneyiminden sonra public sayfa dogrulamasinda GET content check zorunludur.

---

# 6-9.8 Release Evidence / Audit Log

Release evidence:
- predeploy evidence,
- postdeploy smoke evidence,
- rollback readiness evidence,
- operator notu,
- tarih/saat,
- release id,
- affected services,
- final Go/No-Go karari.

---

# 6-9.9 Deploy Safety Guard Scripts

Bu adimda kurulacak scriptler:

- scripts/pix2pi_predeploy_check.sh
- scripts/pix2pi_postdeploy_smoke.sh
- scripts/pix2pi_rollback_readiness.sh

Bu scriptler destructive islem yapmaz.
Sadece evidence uretir.

---

# 6-9.10 Release Final Closure Gate

6-9 kapanis kriterleri:

- Release / rollback / deploy safety dokumani hazir olmali.
- Visible checkpoint hazir olmali.
- Pre-deploy check scripti hazir olmali.
- Post-deploy smoke scripti hazir olmali.
- Rollback readiness scripti hazir olmali.
- Runtime audit evidence uretilmeli.
- Real implementation audit uretilmeli.
- Release standardi izi kontrol edilmeli.
- Predeploy / postdeploy / rollback izi kontrol edilmeli.
- Nginx / systemd / docker safety izi kontrol edilmeli.
- Migration safety izi kontrol edilmeli.
- Public page GET content check kuralı kontrol edilmeli.
- Eksik implementasyon varsa net gorunmeli.
- PASS olmadan 6-10'a gecilmemeli.

---

# 6-9 Muhur Hedefi

FAZ_6_9_DOC_STATUS=READY ✅  
FAZ_6_9_VISIBLE_CHECKPOINTS_STATUS=READY ✅  
FAZ_6_9_GUARD_SCRIPTS_STATUS=READY ✅  
FAZ_6_9_RUNTIME_AUDIT_STATUS=COMPLETE ✅  
FAZ_6_9_REAL_IMPLEMENTATION_AUDIT_STATUS=COMPLETE ✅  
FAZ_6_9_TEST_STATUS=PASS ✅  
FAZ_6_9_FINAL_STATUS=PASS_OR_NEEDS_IMPLEMENTATION_REVIEW  
FAZ_6_10_READY=CONDITIONAL  

