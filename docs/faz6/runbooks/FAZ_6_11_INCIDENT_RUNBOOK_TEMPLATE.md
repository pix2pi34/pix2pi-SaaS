# Pix2pi Incident Runbook Template

## Incident Identity

incident_id: INC-YYYYMMDD-HHMM  
severity: SEV1 | SEV2 | SEV3 | SEV4  
priority: P0 | P1 | P2 | P3  
status: DETECTED | TRIAGED | MITIGATING | MONITORING | RESOLVED | POSTMORTEM_REQUIRED | CLOSED  
owner: TBD  
detected_at: TBD  
affected_service: TBD  
affected_tenant: TBD  

---

## Summary

Kisa incident ozeti.

---

## Customer Impact

- Etkilenen kullanici / tenant:
- Etkilenen is akisi:
- Etki baslangic zamani:
- Etki devam ediyor mu:

---

## Technical Impact

- Etkilenen servisler:
- Etkilenen dependency:
- Error pattern:
- Log evidence:
- Metrics evidence:

---

## First Safe Diagnostics

~~~bash
docker ps
systemctl status nginx --no-pager
nginx -t
curl -I https://pix2pi.com.tr/
curl -fsS http://127.0.0.1:9090/-/ready
curl -fsS http://127.0.0.1:8222/varz
~~~

---

## Do Not Do

- Production DB uzerine backup almadan restore yapma.
- Nginx -t gecmeden reload yapma.
- Root cause bilinmeden kalici config degistirme.
- Tenant filtresiz data operasyonu yapma.
- Incident evidence almadan cleanup yapma.

---

## Mitigation Steps

1. Etkilenen servisi belirle.
2. Son deploy/release bilgisini kontrol et.
3. Health ve metric evidence topla.
4. Gerekirse rollback readiness evidence ac.
5. Smoke test calistir.
6. Musteri etkisi varsa not al.
7. Monitoring ile iyilesmeyi takip et.

---

## Recovery Smoke

~~~bash
bash scripts/pix2pi_postdeploy_smoke.sh
bash scripts/pix2pi_edge_http_smoke.sh
bash scripts/pix2pi_ops_console_probe.sh
~~~

---

## Timeline

| Time | Event | Owner | Evidence |
|---|---|---|---|
| TBD | Detected | TBD | TBD |
| TBD | Mitigation started | TBD | TBD |
| TBD | Resolved | TBD | TBD |

---

## Postmortem Required?

yes/no

---

## Closure

final_status: CLOSED / FOLLOW_UP_REQUIRED  
closed_at: TBD  
closed_by: TBD  
action_items: TBD  
