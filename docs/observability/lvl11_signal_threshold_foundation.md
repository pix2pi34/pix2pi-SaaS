# LVL11 Signal + Threshold Foundation

## Kapsam
Bu paket su maddeleri acar:
- 11.1.1 infra sinyalleri
- 11.1.2 app sinyalleri
- 11.1.3 db sinyalleri
- 11.1.4 event bus sinyalleri
- 11.1.5 cache sinyalleri
- 11.1.6 tenant / security sinyalleri
- 11.2.1 CPU / RAM / IO esikleri
- 11.2.2 latency esikleri
- 11.2.3 error rate esikleri
- 11.2.4 queue / backlog esikleri
- 11.2.5 storage growth esikleri
- 11.2.6 connection saturation esikleri

## Bu pakette ne var
- signal catalog
- threshold env example
- threshold rules template
- render script
- smoke script
- generated threshold rules
- generated threshold summary

## Mantik
Ilk asamada sadece:
- sinyalleri standartlastiriyoruz
- esik motoru icin env tabanli threshold kaynagi olusturuyoruz
- generated output uretip smoke ile dogruluyoruz

## Sonraki paket
- 11.3 korelasyon katmani
- 11.4 scale trigger matrisi
