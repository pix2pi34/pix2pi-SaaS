# FAZ 5-R / 250 — FAZ 5-18.4.4 Escalation Matrisi

## Amaç

Bu adım, support operasyonunda hangi olayın hangi seviye/ekibe yükseleceğini tanımlar.

Bu çalışma production auto escalation açmaz. Amaç; SLA breach, P0 incident, KVKK request, security report, billing dispute ve unresolved ticket durumları için escalation matrix, owner mapping, audit trail ve silent failure block kurallarını teknik olarak hazır hale getirmektir.

## Escalation seviyeleri

| Seviye | Açıklama |
|---|---|
| L1_SUPPORT | İlk destek / intake |
| L2_OPS | Operasyon / support ops |
| L3_ENGINEERING | Teknik ekip / on-call |
| L4_LEGAL_KVKK_SECURITY | Hukuk / KVKK / security |
| L5_EXECUTIVE | Ticari / yönetim kararı |

## Zorunlu escalation triggerları

1. SLA_BREACH
2. P0_INCIDENT
3. KVKK_REQUEST
4. SECURITY_REPORT
5. BILLING_DISPUTE
6. UNRESOLVED_TICKET

## Kritik kurallar

- Tüm required escalation rule kayıtları READY olmalıdır.
- tenant_id zorunludur.
- ticket_id zorunludur.
- correlation_id zorunludur.
- sla_key zorunludur.
- audit trail zorunludur.
- silent failure block zorunludur.
- manual review allowed zorunludur.
- Notify customer true ise customer template zorunludur.
- L4 compliance seviyesine çıkan işlerde legal/KVKK/security owner zorunludur.
- Production auto escalation bu fazda kapalı kalır.
- Gerçek müşteri notification bu fazda kapalı kalır.

## Final policy

INTERNAL_MATRIX_READY=true  
PRODUCTION_AUTO_ESCALATION_ENABLED=false  
CUSTOMER_NOTIFICATION_ENABLED=false  
INCIDENT_CLASSIFICATION_REQUIRED_NEXT=true  
NEXT_GATE=FAZ_5_18_4_3_INCIDENT_SINIFLANDIRMA
