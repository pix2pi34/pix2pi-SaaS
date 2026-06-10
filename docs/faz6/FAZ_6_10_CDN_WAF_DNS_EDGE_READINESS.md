# Pix2pi — FAZ 6-10 CDN / WAF / DNS / Edge Readiness

## Faz Bilgisi

Faz: FAZ 6  
Adim: 6-10  
Adim Adi: CDN / WAF / DNS / Edge Readiness  
Onceki Adim: 6-9 Release / Rollback / Deploy Safety  
Onceki Adim Durumu: PASS  
Bu Adim Amaci: Pix2pi public edge, DNS, CDN, WAF, TLS, public route ve edge security hazirligini kanitlamak  
Risk Seviyesi: Kontrollu  
Runtime Etkisi: Bu adim DNS degistirmez, Cloudflare ayari degistirmez, Nginx reload yapmaz  
Sonraki Adim: 6-11 Ops Console / Incident / Runbook Readiness  

---

# 6-10 Ana Karar

Production public sistemde sadece backend servislerinin calismasi yeterli degildir.

Edge hazirligi icin hedef:
- domain ve subdomain DNS durumunu gormek,
- public HTTP/HTTPS cevaplarini evidence olarak almak,
- TLS / certificate durumunu kontrol etmek,
- Cloudflare / CDN / WAF izlerini kontrol etmek,
- Nginx public route ve security header izlerini kontrol etmek,
- public/private endpoint ayrimini dogrulamak,
- edge kaynakli fail durumlari icin runbook standardi olusturmaktir.

Bu adimda DNS veya Cloudflare configuration degistirilmez.

---

# 6-10.1 DNS Readiness

Kontrol edilecekler:
- ana domain A/AAAA/CNAME durumu,
- www/panel/api/auth/pos subdomain planlari,
- TTL bilgisi,
- public IP dogrulugu,
- DNS propagation kontrolu,
- domain failover hazirligi.

Minimum DNS hedefleri:
- pix2pi.com.tr public cevap vermeli,
- panel.pix2pi.com.tr planli olmali,
- api.pix2pi.com.tr planli olmali,
- auth.pix2pi.com.tr planli olmali,
- pos.pix2pi.com.tr planli olmali.

---

# 6-10.2 TLS / HTTPS Readiness

Kontrol edilecekler:
- HTTPS cevap veriyor mu?
- certificate chain gecerli mi?
- sertifika suresi dolmamis mi?
- HTTP -> HTTPS yonlendirme var mi?
- TLS protokol ayarlari guvenli mi?
- HSTS header var mi?

Minimum TLS hedefi:
- production public endpoint HTTPS ile acilir.
- sertifika bitis tarihi izlenir.
- sertifika yenileme veya Cloudflare edge sertifika durumu takip edilir.

---

# 6-10.3 CDN / Cache Readiness

Kontrol edilecekler:
- static asset cache stratejisi,
- Cache-Control header,
- CDN cache hit/miss header izleri,
- Cloudflare CF-Cache-Status izi,
- public static dosya GET content check,
- cache purge runbook.

Minimum CDN hedefi:
- statik varliklar edge/CDN tarafindan hizlandirilabilir.
- dinamik API response'lari yanlis cache edilmez.
- tenant/user hassas response cache edilmez.

---

# 6-10.4 WAF / DDoS / Bot Guardrails

Kontrol edilecekler:
- Cloudflare veya edge WAF kullanimi,
- bot / scanner trafiği sinyalleri,
- rate limit kural seti,
- brute force login korumasi,
- API endpoint koruma stratejisi,
- DDoS mitigation notlari,
- fail2ban / edge / gateway zinciri.

Minimum WAF hedefi:
- public auth ve API endpointleri rate limit altinda olmali.
- edge WAF loglari incident akisi ile iliskilendirilmeli.
- direkt origin exposure minimuma indirilmeli.

---

# 6-10.5 Nginx Edge / Reverse Proxy Readiness

Kontrol edilecekler:
- nginx -t geciyor mu?
- server_name dogru mu?
- proxy_pass route'lari dogru mu?
- X-Forwarded-* header forwarding var mi?
- X-Request-ID / request correlation var mi?
- security header izleri var mi?
- client_max_body_size var mi?
- proxy timeout ayarlari var mi?
- public/private route ayrimi var mi?

---

# 6-10.6 Public Route Smoke

Public smoke hedefleri:
- ana domain GET 200/3xx donuyor mu?
- public landing content var mi?
- faz4d pilot go-live sayfasi GET content check geciyor mu?
- HEAD yerine GET content kontrolu yapiliyor mu?
- public endpoint time_total olculuyor mu?

---

# 6-10.7 Origin Exposure / Internal Port Safety

Kontrol edilecekler:
- DB public olmamali,
- Redis public olmamali,
- NATS client public exposure kontrollu olmali,
- Grafana/Prometheus public aciksa auth/edge korumasi olmali,
- API Gateway disinda internal servisler direkt public olmamali.

---

# 6-10.8 Edge Observability

Edge gozlemlenebilirlik:
- access logs,
- error logs,
- status code dagilimi,
- 4xx / 5xx,
- latency,
- upstream timeout,
- Cloudflare ray id veya edge trace,
- WAF blocked request,
- rate limit hits.

---

# 6-10.9 Edge Incident / Runbook

Runbook alanlari:
- DNS bozuldu,
- SSL sertifika sorunu,
- CDN cache yanlis calisti,
- WAF yanlis pozitif engelledi,
- origin down,
- Nginx route bozuldu,
- public sayfa 404 dondu,
- API public endpoint timeout verdi.

---

# 6-10.10 Edge Final Closure Gate

6-10 kapanis kriterleri:

- CDN / WAF / DNS / Edge dokumani hazir olmali.
- Visible checkpoint hazir olmali.
- DNS probe scripti hazir olmali.
- HTTP edge smoke scripti hazir olmali.
- Runtime audit evidence uretilmeli.
- Real implementation audit uretilmeli.
- DNS readiness izi kontrol edilmeli.
- TLS / HTTPS izi kontrol edilmeli.
- CDN / cache izi kontrol edilmeli.
- WAF / DDoS / rate limit izi kontrol edilmeli.
- Nginx edge / reverse proxy izi kontrol edilmeli.
- Public GET content check izi kontrol edilmeli.
- Origin exposure / internal port safety izi kontrol edilmeli.
- Edge observability izi kontrol edilmeli.
- Eksik implementasyon varsa net gorunmeli.
- PASS olmadan 6-11'e gecilmemeli.

---

# 6-10 Muhur Hedefi

FAZ_6_10_DOC_STATUS=READY ✅  
FAZ_6_10_VISIBLE_CHECKPOINTS_STATUS=READY ✅  
FAZ_6_10_EDGE_GUARD_SCRIPTS_STATUS=READY ✅  
FAZ_6_10_RUNTIME_AUDIT_STATUS=COMPLETE ✅  
FAZ_6_10_REAL_IMPLEMENTATION_AUDIT_STATUS=COMPLETE ✅  
FAZ_6_10_TEST_STATUS=PASS ✅  
FAZ_6_10_FINAL_STATUS=PASS_OR_NEEDS_IMPLEMENTATION_REVIEW  
FAZ_6_11_READY=CONDITIONAL  

