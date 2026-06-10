# FAZ 5-R / 246 — FAZ 5-18.3.3 Log Retention / İmha Politikası

## Amaç

Bu adım, Commercial / Public Launch öncesinde log, consent, sözleşme ve ticari operasyon kayıtlarının saklama ve imha politikasını teknik olarak kontrol edilebilir hale getirir.

Bu çalışma production ortamda gerçek silme işlemini açmaz. Amaç; retention süreleri, tenant izolasyonu, legal hold, audit evidence, KVKK dayanağı ve restore guard kontrollerini standarda bağlamaktır.

## Kapsam

Zorunlu policy kapsamları:

1. Audit event log retention
2. Consent decision log retention
3. Contract document retention
4. Security access log retention
5. Commercial operation log retention

## Kritik kurallar

- Tüm policy kayıtları READY olmalıdır.
- Tüm zorunlu policy kayıtları tenant scoped olmalıdır.
- Tüm zorunlu policy kayıtlarında retention_days bulunmalıdır.
- Tüm zorunlu policy kayıtlarında disposal_action bulunmalıdır.
- Legal hold guard zorunludur.
- Audit evidence guard zorunludur.
- KVKK dayanak alanı zorunludur.
- Restore guard zorunludur.
- Production delete bu fazda kapalı kalır.
- Herhangi bir gerçek cleanup / deletion için ayrı approval ve evidence gerekir.

## Retention matrisi

| Kapsam | Süre | Aksiyon | Production delete |
|---|---:|---|---|
| AUDIT_LOG | 365 gün | ARCHIVE | false |
| CONSENT_LOG | 1825 gün | ARCHIVE | false |
| CONTRACT_DOCUMENT | 3650 gün | LEGAL_HOLD | false |
| SECURITY_LOG | 730 gün | ARCHIVE | false |
| COMMERCIAL_OPERATION_LOG | 1095 gün | ARCHIVE | false |

## Final policy

INTERNAL_POLICY_READY=true  
PRODUCTION_DELETION_ALLOWED=false  
LEGAL_HOLD_REQUIRED=true  
TENANT_SCOPE_REQUIRED=true  
AUDIT_EVIDENCE_REQUIRED=true  
RESTORE_GUARD_REQUIRED=true  
NEXT_GATE=FAZ_5_18_4_1_SLA_SEVIYELERI
