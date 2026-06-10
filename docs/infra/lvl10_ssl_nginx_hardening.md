# LVL10 SSL / Nginx Hardening

## Kapsam
Bu paket su maddeleri acar:
- 10.1.3 SSL hardening
- 10.1.5 public/private route final mantigi
- 10.4.1 guvenli header seti
- 10.4.2 body size / upload limit politikasi
- 10.4.3 timeout / buffer standardi
- 10.4.4 upstream failover davranisi temeli
- 10.4.5 error leakage azaltma
- 10.4.6 access / error log standardi

## Include seti
- pix2pi_tls_policy.conf
- pix2pi_proxy_common.conf
- pix2pi_request_limits.conf
- pix2pi_error_handling.conf
- pix2pi_logging.conf

## Hedef
Canli Nginx'e gecmeden once:
- TLS policy repo icinde standart olsun
- request / body limit standardi sabitlensin
- proxy timeout ve failover ayarlari sabitlensin
- public / private route mantigi net olsun
- error leakage azaltma hazir olsun
- log format standardi hazir olsun

## Public / private kural
- /internal => deny all
- /health => allowlist ile sinirli
- public trafik sadece standart route'lara gider
- server_tokens kapali
- error page minimum bilgi verir

## Sonraki paket
- 10.2 edge security
- 10.5 sertifika operasyon akisi
- 10.6 operasyon dogrulama
