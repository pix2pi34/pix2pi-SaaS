# 178 — FAZ 3-13.3 — Provider Hata Görünümü

## Amaç

e-Belge provider hata kodlarını okunabilir, sınıflandırılmış ve audit izli şekilde görünür hale getirmek.

## Kapsam

- Provider hata tablosu
- Provider error code / message
- Normalized error code
- Error category
- Severity
- Retryability
- Route decision
- DLQ status
- Manual review status
- Payload hash
- Response hash
- Error hash
- Classification hash
- Audit timeline

## Canlı Politika

Bu ekran gerçek GİB/provider çağrısı yapmaz.

Raw secret ve raw credential görünmez. Error payload masked kalır. Retry decision dry-run/evidence amaçlıdır. Critical hatalarda manual review zorunludur.

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- HTML ekran dosyası var
- Config artifact var
- Documentation artifact var
- Audit script var
- AUTH / VALIDATION / SCHEMA / TIMEOUT / RATE_LIMIT kategori görünür
- INFO / WARN / ERROR / CRITICAL severity görünür
- RETRYABLE / NON_RETRYABLE görünür
- DLQ / manual review / route decision izleri var
- Payload / response / error / classification / audit hash izleri var
- Real provider/GİB FALSE
- Raw secret/credential FALSE
- Audit PASS
