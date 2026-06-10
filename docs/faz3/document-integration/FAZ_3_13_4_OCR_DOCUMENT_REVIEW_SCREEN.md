# 175 — FAZ 3-13.4 — OCR / Belge Okuma Review Ekranı

## Amaç

Google Lens benzeri belge okuma çıktılarının insan onayıyla kontrol edildiği review ekranını kurmak.

## Kapsam

- OCR review queue
- Lens-like document reading visibility
- Vergi no extraction
- Vergi dairesi extraction
- Adres extraction
- Telefon extraction
- E-posta extraction
- Confidence score / bucket
- Missing field visibility
- Manual correction visibility
- Review decision visibility
- Target entity dry-run görünümü
- Source image hash
- OCR payload hash
- Extracted fields hash
- Correction hash
- PII mask hash
- Audit timeline

## Canlı Politika

Bu ekran otomatik cari kart yazımı yapmaz.

Auto commit kapalıdır. Human review zorunludur. Raw image storage kapalıdır. PII masking, confidence gate ve correction audit zorunludur.

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- HTML ekran dosyası var
- Config artifact var
- Documentation artifact var
- Audit script var
- Vergi no / vergi dairesi / adres / telefon / e-posta extraction alanları görünür
- HIGH / MEDIUM / LOW confidence kapsamı görünür
- READY_FOR_REVIEW / LOW_CONFIDENCE / CORRECTION_REQUIRED / APPROVED_DRY_RUN görünür
- Source image / OCR payload / extracted fields / correction / PII / audit hash izleri görünür
- Auto commit FALSE
- Customer card write FALSE
- Human review TRUE
- Audit PASS
