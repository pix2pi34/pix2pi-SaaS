# LVL13 Odeme + Turkiye Uyum Closure

## Kapsam
Bu paket su maddeleri acar:
- 13.7.1 POS entegrasyon omurgasi
- 13.7.2 banka / tahsilat akisi
- 13.7.3 mutabakat koprusu
- 13.7.4 iade / iptal akislari
- 13.7.5 entegrasyon audit izi
- 13.7.6 odeme entegrasyon testleri
- 13.8.1 Turkiye muhasebe smoke
- 13.8.2 e-Belge smoke
- 13.8.3 export smoke
- 13.8.4 muhasebeci portali smoke
- 13.8.5 odeme entegrasyon smoke
- 13.8.6 Turkiye uyum kapanisi

## Bu pakette ne var
- odeme env example
- odeme catalog
- turkiye compliance matrix template
- render script
- smoke script
- phase closure script
- generated odeme rules
- generated odeme summary
- generated turkiye compliance matrix
- generated phase closure summary
- generated phase closure report

## Mantik
Bu paket ile:
- POS / banka / mutabakat / iade / iptal / audit mantigini katalogluyoruz
- generated payment rules ve compliance matrix uretiyoruz
- onceki 13.1-13.6 smoke scriptlerini tekrar kosup tam closure yapiyoruz
- sonuc READY degilse script fail verir

## Beklenen final durum
- LVL13 tamamen kapanmis olur
