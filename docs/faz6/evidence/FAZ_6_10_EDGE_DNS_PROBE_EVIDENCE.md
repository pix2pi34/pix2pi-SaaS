# FAZ 6-10 Edge DNS Probe Evidence

Generated At: 2026-05-01T15:52:50+03:00  
Repo: /root/pix2pi/pix2pi-SaaS  
DOMAIN=pix2pi.com.tr  
SUBDOMAINS=www api panel auth pos  

Bu script DNS degistirmez. Sadece DNS readiness evidence uretir.

FAZ_6_10_EDGE_DNS_PROBE=STARTED ✅

---

===== DNS PROBE: pix2pi.com.tr =====
--- A ---
141.98.48.42
--- AAAA ---
--- CNAME ---
--- TTL/SOA TRACE ---
pix2pi.com.tr.		295	IN	A	141.98.48.42
pix2pi.com.tr DNS_RESOLVES OK ✅

===== DNS PROBE: www.pix2pi.com.tr =====
--- A ---
141.98.48.42
--- AAAA ---
--- CNAME ---
--- TTL/SOA TRACE ---
www.pix2pi.com.tr.	296	IN	A	141.98.48.42
www.pix2pi.com.tr DNS_RESOLVES OK ✅

===== DNS PROBE: api.pix2pi.com.tr =====
--- A ---
141.98.48.42
--- AAAA ---
--- CNAME ---
--- TTL/SOA TRACE ---
api.pix2pi.com.tr.	296	IN	A	141.98.48.42
api.pix2pi.com.tr DNS_RESOLVES OK ✅

===== DNS PROBE: panel.pix2pi.com.tr =====
--- A ---
141.98.48.42
--- AAAA ---
--- CNAME ---
--- TTL/SOA TRACE ---
panel.pix2pi.com.tr.	296	IN	A	141.98.48.42
panel.pix2pi.com.tr DNS_RESOLVES OK ✅

===== DNS PROBE: auth.pix2pi.com.tr =====
--- A ---
141.98.48.42
--- AAAA ---
--- CNAME ---
--- TTL/SOA TRACE ---
auth.pix2pi.com.tr.	296	IN	A	141.98.48.42
auth.pix2pi.com.tr DNS_RESOLVES OK ✅

===== DNS PROBE: pos.pix2pi.com.tr =====
--- A ---
141.98.48.42
--- AAAA ---
--- CNAME ---
--- TTL/SOA TRACE ---
pos.pix2pi.com.tr.	296	IN	A	141.98.48.42
pos.pix2pi.com.tr DNS_RESOLVES OK ✅


## DNS Probe Final Seal

```text
PASS_COUNT=6
WARN_COUNT=0
FAZ_6_10_EDGE_DNS_PROBE_STATUS=COMPLETE ✅
FAZ_6_10_EDGE_DNS_WARN_STATUS=CLEAR ✅
```
