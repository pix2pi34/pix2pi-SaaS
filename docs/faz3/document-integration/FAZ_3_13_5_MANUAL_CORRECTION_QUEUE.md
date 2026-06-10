# 179 — FAZ 3-13.5 — Manuel Düzeltme Kuyruğu

## Amaç

OCR, e-Belge status, provider hata ve retry/cancel/resend kaynaklı manuel düzeltme işlerini tek güvenli kuyrukta görünür hale getirmek.

## Kapsam

- Manuel düzeltme kuyruğu
- OCR review source
- e-Belge status source
- Provider error source
- Retry/cancel/resend source
- Correction field
- Current value / proposed value
- Operator assignment
- Reviewer
- Decision
- Approval status
- Rejection reason
- Correction source hash
- Before value hash
- After value hash
- Decision hash
- Audit timeline

## Canlı Politika

Bu ekran otomatik düzeltme uygulamaz.

Auto apply kapalıdır. Human approval ve dual-control zorunludur. Before/after hash ve audit hash zorunludur. Live write kapalıdır. Raw PII gösterilmez.

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- HTML ekran dosyası var
- Config artifact var
- Documentation artifact var
- Audit script var
- OCR_REVIEW / EBELGE_STATUS / PROVIDER_ERROR / RETRY_CANCEL_RESEND kaynakları görünür
- OPEN / ASSIGNED / WAITING_APPROVAL / APPROVED_DRY_RUN / REJECTED durumları görünür
- LOW / MEDIUM / HIGH / CRITICAL priority görünür
- Before/after/decision/audit/evidence hash izleri var
- Auto apply FALSE
- Human approval TRUE
- Dual control TRUE
- Live write FALSE
- Audit PASS
