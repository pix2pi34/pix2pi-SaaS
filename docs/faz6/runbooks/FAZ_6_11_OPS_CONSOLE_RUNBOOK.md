# Pix2pi Ops Console Runbook

## Purpose

Ops Console hedefi sistemin servis, dependency, incident ve warning durumunu tek ekranda gostermektir.

---

## Minimum Cards

1. Service Health
2. DB Health
3. Event Bus / Backlog
4. Edge / DNS / Public Route
5. Backup / Restore
6. Security / WAF / Rate Limit
7. Active Incidents
8. Recent Warnings
9. Tenant Impact
10. Runbook Links

---

## Safe Probe Commands

~~~bash
bash scripts/pix2pi_ops_console_probe.sh
bash scripts/pix2pi_postdeploy_smoke.sh
bash scripts/pix2pi_edge_http_smoke.sh
bash scripts/audit_faz6_11_ops_runtime.sh
~~~

---

## Status Meaning

OK:
- servis cevap veriyor,
- dependency saglikli,
- public route donuyor.

WARN:
- servis var ama endpoint/metric eksik,
- latency yuksek,
- non-blocking issue var.

DOWN:
- servis cevap vermiyor,
- dependency erisilemiyor,
- public route fail.

UNKNOWN:
- probe yapilamadi,
- config eksik,
- durum belirsiz.

---

## Escalation

SEV1:
- hemen operator/founder,
- DB/security/infra owner,
- musteri etkisi varsa business owner.

SEV2:
- ayni gun aksiyon,
- ilgili teknik owner.

SEV3:
- planli takip,
- warning backlog.

SEV4:
- dokuman / polish / non-critical.

---

## Final Rule

Ops Console sadece goruntu degil; runbook ve incident aksiyonuna baglanmalidir.
