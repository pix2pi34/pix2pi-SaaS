# LVL10 Edge Security + Cert Ops

## Kapsam
Bu paket su maddeleri acar:
- 10.2.1 WAF hazirligi
- 10.2.2 CDN hazirligi
- 10.2.3 Edge rate limit entegrasyonu
- 10.5.1 sertifika uretim akisi temeli
- 10.5.2 auto-renew dogrulamasi temeli
- 10.5.3 weak TLS kapatma temeli
- 10.5.4 HSTS politikasi zaten 10.1.3 paketinde acildi, burada ops akisi tamamlanir
- 10.5.5 guvenli cert operasyon runbook temeli

## Bu pakette ne var
- edge security env example
- CDN foundation template
- WAF foundation include
- ACME challenge include
- render script (security env destekli)
- cert renew foundation script
- certbot renew script
- generated systemd unit/timer
- security smoke script

## Temel kararlar
- WAF burada foundation seviyesinde baslar
- CDN/trusted proxy burada foundation seviyesinde baslar
- rate limit standardi repo icinde sabitlenir
- certbot renew systemd ornegi repo icinde uretilir
- canli Nginx/systemd kurulumu sonraki operasyonda yapilir

## Sonraki paket
- 10.6 operasyon dogrulama
- 10.7 faz cikis kapatis
