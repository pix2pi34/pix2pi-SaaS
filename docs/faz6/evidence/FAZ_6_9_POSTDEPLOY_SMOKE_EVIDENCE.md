# FAZ 6-9 Postdeploy Smoke Evidence

Generated At: 2026-05-01T16:13:31+03:00  
Repo: /root/pix2pi/pix2pi-SaaS  

Bu script deploy yapmaz. Deploy sonrasi kullanilacak smoke kontrol standardini uygular.

Port correction note:
- identity icin host port 9002 onceliklidir, 9001 fallback olarak denenir.
- grafana icin host port 3001 onceliklidir, 3000 fallback olarak denenir.
- NATS 4222 HTTP portu degildir; smoke sadece 8222 monitoring /varz dener.

FAZ_6_9_POSTDEPLOY_SMOKE=STARTED ✅

---

===== identity health =====
TRY_1=http://127.0.0.1:9002/health
http_code=200 time_total=0.001464 size=33
identity health OK ✅

===== api gateway health =====
TRY_1=http://127.0.0.1:9010/health
http_code=200 time_total=0.001203 size=21
api gateway health OK ✅

===== prometheus ready =====
TRY_1=http://127.0.0.1:9090/-/ready
http_code=200 time_total=0.001699 size=28
prometheus ready OK ✅

===== grafana health =====
TRY_1=http://127.0.0.1:3001/api/health
http_code=200 time_total=0.001468 size=101
grafana health OK ✅

===== node exporter metrics =====
TRY_1=http://127.0.0.1:9100/metrics
http_code=200 time_total=0.021858 size=73763
node exporter metrics OK ✅

===== cadvisor metrics =====
TRY_1=http://127.0.0.1:8080/metrics
http_code=200 time_total=0.261263 size=7731262
cadvisor metrics OK ✅

===== nats monitoring varz =====
TRY_1=http://127.0.0.1:8222/varz
http_code=200 time_total=0.003691 size=1699
nats monitoring varz OK ✅


## Postdeploy Smoke Final Seal

```text
PASS_COUNT=7
WARN_COUNT=0
FAZ_6_9_POSTDEPLOY_SMOKE_STATUS=COMPLETE ✅
POSTDEPLOY_DESTRUCTIVE_ACTION=NO ✅
FAZ_6_9_POSTDEPLOY_SMOKE_WARN_STATUS=CLEAR ✅
```
