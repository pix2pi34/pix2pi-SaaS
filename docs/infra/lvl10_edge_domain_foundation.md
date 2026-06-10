# LVL10 Edge / Domain Foundation

## Kapsam
Bu paket su maddeleri acar:
- 10.1.1 Domain routing finalizasyonu icin temel iskelet
- 10.1.2 Subdomain yapisinin repo tarafinda netlestirilmesi
- 10.1.4 Reverse proxy standardinin template hale getirilmesi
- 10.3.1 api domain
- 10.3.2 panel domain
- 10.3.3 auth domain
- 10.3.4 pos domain
- 10.3.5 internal/private route ayrimi
- 10.3.6 health endpoint dis erisim politikasi

## Domain matrisi
- api.pix2pi.com.tr  -> API Gateway
- panel.pix2pi.com.tr -> Panel UI
- auth.pix2pi.com.tr -> Identity / Auth
- pos.pix2pi.com.tr -> POS UI/API

## Public / private kural
- `/internal/` publicten acilmaz
- `/health` publicte acilmaz, allowlist ile sinirlanir
- once template uretilir
- sonra canlı Nginx baglantisi yapilir

## Bu pakette ne var
- env example
- nginx template
- security headers include
- render script
- smoke script

## Sonraki paket
- 10.1.3 SSL hardening
- 10.1.5 public/private route son kapatis
- 10.4 nginx hardening
- 10.5 TLS / sertifika yonetimi
