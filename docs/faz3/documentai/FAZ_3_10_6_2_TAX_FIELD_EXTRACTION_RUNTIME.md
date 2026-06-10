# 147 — FAZ 3-10.6.2 — Vergi alanı extraction runtime

## Amaç

146 OCR / Lens processing çıktısından vergi alanlarını deterministic ve audit edilebilir şekilde çıkarır.

## Kapsam

- Tax field extraction request modeli
- Extracted tax field modeli
- Tax field extraction result modeli
- OCR result bridge
- Company name extraction
- VKN/TCKN extraction
- Vergi dairesi extraction
- MERSİS extraction
- VKN/TCKN digit normalization
- Vergi no 10/11 hane kontrolü
- Missing required fields review signal
- Low confidence review signal
- Tenant scope guard
- OCR result hash guard
- OCR status guard
- Document type guard
- Result hash üretimi

## Canlı Politika

Bu runtime gerçek OCR provider değildir. 146 OCR/Lens runtime çıktısından vergi alanı çıkaran ERP Document AI alt modülüdür.

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- Runtime dosyası var
- Test dosyası var
- Config artifact var
- Documentation artifact var
- Go test PASS
- Real implementation audit PASS
- Tax no extraction PASS
- Tax office extraction PASS
- Company name extraction PASS
- MERSİS extraction PASS
- Missing field review PASS
- Low confidence review PASS
- Validation guards PASS
