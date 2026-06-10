# LVL11 Correlation + Scale Trigger Foundation

## Kapsam
Bu paket su maddeleri acar:
- 11.3.1 service-to-service correlation
- 11.3.2 request / correlation id zinciri
- 11.3.3 incident grouping
- 11.3.4 noisy alert suppression
- 11.3.5 root-cause hint uretimi
- 11.4.1 DB bottleneck alarmi
- 11.4.2 event backlog alarmi
- 11.4.3 reporting impact alarmi
- 11.4.4 single-node risk alarmi
- 11.4.5 deploy risk growth alarmi
- 11.4.6 cluster transition trigger matrisi

## Bu pakette ne var
- correlation catalog
- scale trigger env example
- scale trigger matrix template
- render script
- smoke script
- generated scale trigger matrix
- generated correlation summary

## Mantik
Ilk asamada:
- korelasyon mantigini katalogluyoruz
- incident grouping / noisy alert suppression / root-cause hint alanlarini standarda bagliyoruz
- scale trigger thresholdlarini env tabanli matrix olarak uretiyoruz
- generated cikti alip smoke ile dogruluyoruz

## Sonraki paket
- 11.5 delivery / escalation
- 11.6 validation
- 11.7 phase closure
