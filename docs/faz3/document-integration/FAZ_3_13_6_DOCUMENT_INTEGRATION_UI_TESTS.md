# 176 — FAZ 3-13.6 — Belge / Entegrasyon UI Testleri

## Amaç

Belge / entegrasyon UI yüzeylerinin mevcut kapalı kapsamını tek test suite altında doğrulamak.

## Test Kapsamı

Bu adım şu an mühürlenmiş iki ekranı doğrular:

- 174 — e-Belge durum merkezi
- 175 — OCR / belge okuma review ekranı

177 / 178 / 179 ekranları bu testin zorunlu kapsamına alınmaz; bunlar sıradaki ayrı ekran adımlarıdır.

## Zorunlu Kontroller

- HTML ekran dosyası var
- Config artifact var
- Evidence artifact var
- Phase marker var
- Screen marker var
- Tenant / firm guard görünür
- Correlation veya review guard görünür
- Audit hash ve evidence trace görünür
- Real GİB / provider / external action kapalı
- OCR auto commit kapalı
- Human review açık
- Dry-run / read-only policy görünür

## Canlı Politika

Bu test suite production aktivasyonu yapmaz.

Gerçek GİB çağrısı, gerçek provider çağrısı, external delivery, auto commit, customer card write, raw image storage, audit delete ve audit mutation kapalı kalır.

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- 174 ve 175 ekranları, configleri ve evidence dosyaları var
- Her ekranda guard / audit / evidence izleri var
- Canlı risk kapıları kapalı
- Test suite PASS
- Audit PASS
