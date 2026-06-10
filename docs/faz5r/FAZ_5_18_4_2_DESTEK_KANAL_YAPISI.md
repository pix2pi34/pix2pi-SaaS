# FAZ 5-R / 248 — FAZ 5-18.4.2 Destek Kanal Yapısı

## Amaç

Bu adım, Commercial / Public Launch öncesinde destek kanal yapısını tanımlar.

Bu çalışma gerçek müşteri support operasyonunu açmaz. Amaç; destek kanallarının, tenant-safe intake zorunluluklarının, issue family kapsamının, KVKK/security özel kanallarının ve audit trail gereksinimlerinin standarda bağlanmasıdır.

## Kanal envanteri

1. support_email_intake
2. support_in_app_intake
3. support_help_center_form
4. support_kvkk_request
5. support_security_report
6. support_ops_escalation

## Zorunlu issue family kapsamı

- PILOT
- BILLING
- KVKK
- SECURITY
- TECHNICAL
- COMMERCIAL

## Zorunlu intake alanları

Her zorunlu kanal şunları taşımalıdır:

- tenant_id
- requester_email
- correlation_id
- audit_trail
- sla_key
- intake_template
- routing_rule
- ops_owner

## Kritik kurallar

- Public support bu fazda kapalı kalır.
- Gerçek müşteri support intake bu fazda kapalı kalır.
- KVKK request için ayrı kanal bulunmalıdır.
- Security report için ayrı kanal bulunmalıdır.
- Ops escalation için ayrı kanal bulunmalıdır.
- KVKK kanalında privacy notice link zorunludur.
- Tüm kanallar tenant-safe olmalıdır.
- Tüm kanallar SLA contract'a bağlanabilir olmalıdır.
- Tüm kanallar audit trail üretmeye hazır olmalıdır.

## Final policy

INTERNAL_CHANNEL_STRUCTURE_READY=true  
PUBLIC_SUPPORT_ENABLED=false  
REAL_CUSTOMER_SUPPORT_OPEN=false  
SLA_CONTRACT_REQUIRED=true  
CUSTOMER_COMMUNICATION_TEMPLATES_REQUIRED_NEXT=true  
NEXT_GATE=FAZ_5_18_4_5_MUSTERI_ILETISIM_SABLONLARI
