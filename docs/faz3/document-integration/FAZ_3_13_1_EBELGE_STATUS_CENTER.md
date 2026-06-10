# 174 — FAZ 3-13.1 — e-Belge Durum Merkezi

## Amaç

e-Fatura, e-Arşiv ve e-Adisyon belgelerinin durumlarını tek merkezden görünür hale getirmek.

## Kapsam

- e-Fatura status visibility
- e-Arşiv status visibility
- e-Adisyon status visibility
- Provider status
- Provider document id
- Callback status
- Poll status
- Retry status
- Cancel status
- DLQ status
- Manual review status
- UBL hash
- PDF hash
- Payload hash
- Callback signature hash
- Audit timeline

## Canlı Politika

Bu ekran gerçek GİB/provider çağrısı yapmaz.

Status check, callback verify, poll, retry, cancel, resend ve manual review işlemleri dry-run/evidence görünümüdür.

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- HTML ekran dosyası var
- Config artifact var
- Documentation artifact var
- Audit script var
- e-Fatura / e-Arşiv / e-Adisyon görünür
- ACCEPTED / PENDING / RETRY_REQUIRED / DLQ / CANCELED durumları görünür
- Provider id, callback, poll, retry, cancel, DLQ, manual review izleri var
- UBL/PDF/payload/callback/audit hash izleri var
- Real GİB/provider call FALSE
- Audit PASS
