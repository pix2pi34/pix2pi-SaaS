# 177 — FAZ 3-13.2 — Retry / Cancel / Resend Aksiyon Yüzeyi

## Amaç

e-Belge süreçlerinde retry, cancel, resend ve manual review adaylarını güvenli, dry-run ve audit izli aksiyon yüzeyinde göstermek.

## Kapsam

- Retry action surface
- Cancel action surface
- Resend action surface
- Manual review action visibility
- Provider document id
- Reason code
- Provider error code
- Lifecycle status
- Retry attempt / max retry
- Next retry at
- Backoff policy
- DLQ status
- Manual review status
- Operator visibility
- Correlation / request / idempotency
- Request hash
- Payload hash
- Provider hash
- Action hash
- Audit timeline

## Canlı Politika

Bu ekran gerçek GİB/provider çağrısı yapmaz.

Retry, cancel ve resend aksiyonları dry-run/evidence görünümüdür. Live execute disabled kalır. Idempotency, reason code ve audit hash zorunludur.

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- HTML ekran dosyası var
- Config artifact var
- Documentation artifact var
- Audit script var
- RETRY / CANCEL / RESEND / MANUAL_REVIEW görünür
- READY / WAITING_BACKOFF / BLOCKED / DLQ_REVIEW görünür
- Reason code, provider error, lifecycle, retry/backoff, DLQ ve manual review izleri var
- Idempotency, request, payload, provider, action, audit hash izleri var
- Real GİB/provider call FALSE
- Retry/cancel/resend dry-run TRUE
- Audit PASS
