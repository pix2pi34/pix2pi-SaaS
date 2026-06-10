# Pix2pi — FAZ 6-7 Security Hardening / Production Guardrails

## Faz Bilgisi

Faz: FAZ 6  
Adim: 6-7  
Adim Adi: Security Hardening / Production Guardrails  
Onceki Adim: 6-6 Backup / Restore / Disaster Recovery  
Onceki Adim Durumu: PASS  
Bu Adim Amaci: Pix2pi sistemini production acilisi oncesi guvenlik sertlestirme ve guardrail seviyesine tasimak  
Risk Seviyesi: Kontrollu  
Runtime Etkisi: Bu adimda destructive operasyon yoktur  
Sonraki Adim: 6-8 Performance / Load / Stress Readiness  

---

# 6-7 Ana Karar

Production sistemde sadece calisan servis yeterli degildir.

Guvenlik icin hedef:
- secret ve env dosyalarinin korunmasi,
- Nginx / edge sertlestirme,
- firewall ve port exposure kontrolu,
- JWT / auth / API guardrail kontrolu,
- tenant isolation guardrail kontrolu,
- input validation ve injection korumasi,
- rate limit / WAF / DDoS hazirlik kontrolu,
- dependency ve supply-chain risk kontrolu,
- security audit log izlerinin dogrulanmasidir.

Bu adimda destructive operasyon yapilmaz. Audit ve evidence uretir.

---

# 6-7.1 Secret / Env Hardening

Kontrol edilecekler:
- .env dosyalari public repo'ya sizmiyor mu?
- secret degerleri loglarda maskeleniyor mu?
- env dosyalarinin permission seviyesi uygun mu?
- JWT secret / DB password / RESTIC password gibi kritik degerler hard-code edilmemis mi?
- production secret rotasyonu icin not var mi?

Minimum guardrail:
- secret degerleri kod icine gomulmez.
- env dosyalarinin backup'i kontrollu alinir.
- audit ciktisinda secret maskelenir.
- permission kontrolu yapilir.

---

# 6-7.2 Nginx / Edge Hardening

Kontrol edilecekler:
- nginx -t geciyor mu?
- server block'lar net mi?
- public/private route ayrimi var mi?
- TLS/SSL ayarlari var mi?
- security header izleri var mi?
- proxy timeout ve body size limitleri var mi?
- X-Forwarded / X-Request-ID header forwarding var mi?

Minimum guardrail:
- public endpoint ile internal servis endpointleri karismamalidir.
- internal servisler dogrudan public'e acilmamalidir.
- reverse proxy uzerinden kontrollu gecis olmalidir.

---

# 6-7.3 Firewall / Port Policy

Kontrol edilecekler:
- sadece gerekli portlar public mi?
- 22, 80, 443 disinda public exposure kontrollu mu?
- DB, Redis, NATS gibi internal portlar public'e acik olmamali.
- ufw / firewall / fail2ban durumu kontrol edilmeli.
- listening port inventory evidence uretilmeli.

Minimum guardrail:
- DB portu public olmamalidir.
- Redis public olmamalidir.
- NATS public olmamalidir.
- observability panelleri public acilacaksa auth/edge korumasi olmalidir.

---

# 6-7.4 Auth / JWT / API Guardrails

Kontrol edilecekler:
- Authorization header kontrolu,
- Bearer token kontrolu,
- JWT validation,
- token expiry,
- middleware enforcement,
- protected route ayrimi,
- auth bypass riski.

Minimum guardrail:
- protected endpoint auth olmadan calismamalidir.
- JWT tenant bilgisiyle birlikte dogrulanmalidir.
- API Gateway auth enforcement yapmalidir.

---

# 6-7.5 Tenant Isolation Guardrails

Kontrol edilecekler:
- X-Tenant-ID kontrolu,
- tenant_id zorunlulugu,
- JWT tenant mismatch kontrolu,
- DB query tenant filtresi,
- event tenant metadata,
- Redis key namespace,
- audit/log tenant alani,
- RLS veya tenant-level policy izi.

Minimum guardrail:
- cross-tenant data read/write engellenmelidir.
- tenant_id eksik request reddedilmelidir.
- tenant mismatch event islenmemelidir.

---

# 6-7.6 Input Validation / Injection Protection

Kontrol edilecekler:
- request validation,
- query param validation,
- body validation,
- SQL injection korumasi,
- prepared statement / parameterized query kullanimi,
- raw SQL string concat riskleri,
- file upload validation varsa kontrolu.

Minimum guardrail:
- dis girdiler normalize ve validate edilmelidir.
- SQL parametreli calismalidir.
- hata mesajlari hassas bilgi sizdirmamalidir.

---

# 6-7.7 Rate Limit / WAF / DDoS Guardrails

Kontrol edilecekler:
- gateway rate limit izi,
- Nginx limit_req / limit_conn izi,
- Cloudflare / WAF notlari,
- DDoS / bot koruma stratejisi,
- brute force login korumasi,
- abusive tenant trafik tespiti.

Minimum guardrail:
- public auth endpointleri rate limit altinda olmalidir.
- gateway ve edge limitleri cakismaz, birbirini tamamlar.
- fail2ban / WAF / gateway koruma zinciri net olmalidir.

---

# 6-7.8 Dependency / Supply-chain Security

Kontrol edilecekler:
- go.sum / package-lock / dependency lock dosyalari,
- govulncheck / npm audit / dependency scan izleri,
- Docker image tag standardi,
- latest tag riski,
- build artifact guvenligi,
- script permission ve owner kontrolu.

Minimum guardrail:
- dependency lock dosyalari korunur.
- kritik vulnerability kontrolu periyodik yapilir.
- build ve deploy scriptleri audit edilebilir olmalidir.

---

# 6-7.9 Audit / Security Logging

Kontrol edilecekler:
- auth failure loglari,
- tenant mismatch loglari,
- access denied loglari,
- rate limit loglari,
- security event audit izleri,
- request_id / correlation_id / tenant_id ile izleme.

Minimum guardrail:
- security olaylari sessiz kalmamalidir.
- incident analizinde tenant/request/correlation zinciri kurulabilmelidir.

---

# 6-7.10 Security Final Closure Gate

6-7 kapanis kriterleri:

- Security hardening dokumani hazir olmali.
- Visible checkpoint hazir olmali.
- Runtime audit evidence uretilmeli.
- Real implementation audit uretilmeli.
- Secret/env hardening izi kontrol edilmeli.
- Nginx hardening izi kontrol edilmeli.
- Firewall/port policy izi kontrol edilmeli.
- Auth/JWT/API guardrail izi kontrol edilmeli.
- Tenant isolation guardrail izi kontrol edilmeli.
- Input validation/injection protection izi kontrol edilmeli.
- Rate limit/WAF/DDoS izi kontrol edilmeli.
- Dependency/supply-chain security izi kontrol edilmeli.
- Audit/security logging izi kontrol edilmeli.
- Eksik implementasyon varsa net gorunmeli.
- PASS olmadan 6-8'e gecilmemeli.

---

# 6-7 Muhur Hedefi

FAZ_6_7_DOC_STATUS=READY ✅  
FAZ_6_7_VISIBLE_CHECKPOINTS_STATUS=READY ✅  
FAZ_6_7_RUNTIME_AUDIT_STATUS=COMPLETE ✅  
FAZ_6_7_REAL_IMPLEMENTATION_AUDIT_STATUS=COMPLETE ✅  
FAZ_6_7_TEST_STATUS=PASS ✅  
FAZ_6_7_FINAL_STATUS=PASS_OR_NEEDS_IMPLEMENTATION_REVIEW  
FAZ_6_8_READY=CONDITIONAL  

