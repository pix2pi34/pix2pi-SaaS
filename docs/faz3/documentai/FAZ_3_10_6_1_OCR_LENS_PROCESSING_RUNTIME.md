# 146 — FAZ 3-10.6.1 — OCR / Lens processing runtime

## Amaç

Cari kart, firma kartı ve belge AI süreçleri için görsel/PDF/scan kaynaklarından OCR benzeri normalize edilmiş metin, blok ve alan adayları üretir.

## Kapsam

- OCR source modeli
- OCR block modeli
- OCR field candidate modeli
- Process request/result modeli
- Kaynak türü kontrolü
- MIME type kontrolü
- Tenant scope guard
- File hash guard
- Source text guard
- OCR text normalization
- Document type detection
- Field candidate extraction
- Confidence calculation
- Review required decision
- Result hash üretimi

## Canlı Politika

Bu runtime gerçek dış OCR sağlayıcısına bağlanmaz. Provider bağımsız, deterministic OCR/Lens processing çekirdeğidir. Gerçek OCR sağlayıcı adaptörü ileride ayrı provider-live modülünde bağlanır.

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- Runtime dosyası var
- Test dosyası var
- Config artifact var
- Documentation artifact var
- Go test PASS
- Real implementation audit PASS
- Text normalization PASS
- Block generation PASS
- Field candidate extraction PASS
- Confidence/review decision PASS
- Guard negative paths PASS
