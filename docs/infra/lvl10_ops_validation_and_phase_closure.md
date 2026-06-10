# LVL10 Ops Validation + Phase Closure

## Kapsam
Bu paket su maddeleri acar:
- 10.6.1 domain resolve testi
- 10.6.2 HTTPS redirect testi
- 10.6.3 sertifika / ACME operasyon hazirlik testi
- 10.6.4 reverse proxy route policy testi
- 10.6.5 public / private erisim smoke
- 10.6.6 edge smoke validation raporu
- 10.7.1 domain duzenli
- 10.7.2 subdomainler oturmus
- 10.7.3 SSL guvenli foundation hazir
- 10.7.4 reverse proxy standardi sabit
- 10.7.5 public / private sinir net
- 10.7.6 edge guvenligi hazir

## Mantik
Bu paket canli edge'e zorla baglanmaz.
Once repo icindeki foundation dosyalari, generated configler, cert renew unit/timer,
public/private policy ve ops checklist dogrulanir.

Opsiyonel olarak live checks acilabilir:
- DNS resolve
- HTTP -> HTTPS redirect
- HTTPS handshake

## Cikti
- summary env
- markdown ops validation raporu
- markdown phase closure raporu

## Faz sonucu
- FOUNDATION_READY => repo ve generated artefactlar hazir
- LIVE_READY => live kontroller de gecti
- BLOCKED => kritik eksik var
