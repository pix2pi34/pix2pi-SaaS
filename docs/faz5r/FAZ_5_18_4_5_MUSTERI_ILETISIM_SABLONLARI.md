# FAZ 5-R / 249 — FAZ 5-18.4.5 Müşteri İletişim Şablonları

## Amaç

Bu adım, Commercial / Public Launch öncesinde müşteri iletişim şablonlarını tanımlar.

Bu çalışma gerçek müşteriye otomatik gönderim açmaz. Amaç; support ticket acknowledgement, incident update, SLA breach, KVKK request, billing issue ve security report şablonlarını tenant-safe, audit edilebilir ve KVKK uyumlu hale getirmektir.

## Şablon envanteri

1. template_ticket_ack
2. template_incident_update
3. template_sla_breach_notice
4. template_kvkk_request_ack
5. template_billing_issue_ack
6. template_security_report_ack

## Zorunlu değişkenler

Her zorunlu şablon şu değişkenleri taşımalıdır:

- tenant_id
- ticket_id
- requester_email
- correlation_id
- sla_key

## Zorunlu uyum kontrolleri

- tenant context
- ticket context
- audit trail
- tone guard
- KVKK footer
- KVKK request için privacy notice link
- SLA breach için SLA context
- SLA breach için escalation hint
- tr-TR dil standardı

## Kritik kurallar

- Public template publication kapalı kalır.
- Gerçek müşteriye otomatik gönderim kapalı kalır.
- Şablonlar sadece internal readiness seviyesinde hazırdır.
- KVKK talebi şablonu privacy notice link içermelidir.
- SLA breach şablonu escalation hint içermelidir.
- Tüm şablonlar audit trail ve correlation_id ile ilişkilendirilebilir olmalıdır.

## Final policy

INTERNAL_TEMPLATES_READY=true  
PUBLIC_TEMPLATES_PUBLISHED=false  
REAL_CUSTOMER_SENDING_ENABLED=false  
ESCALATION_MATRIX_REQUIRED_NEXT=true  
NEXT_GATE=FAZ_5_18_4_4_ESCALATION_MATRISI
