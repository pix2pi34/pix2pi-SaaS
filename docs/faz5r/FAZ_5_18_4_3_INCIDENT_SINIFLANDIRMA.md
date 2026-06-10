# FAZ 5-R / 251 — FAZ 5-18.4.3 Incident Sınıflandırma

## Amaç

Bu adım, support operasyonunda gelen olayların hangi kategori, severity, SLA ve escalation kuralına bağlanacağını tanımlar.

Bu çalışma production auto classification açmaz. Amaç; incident kategorilerini, severity mapping'i, SLA binding'i, escalation binding'i ve müşteri iletişim şablonu binding'ini teknik olarak audit edilebilir hale getirmektir.

## Zorunlu kategoriler

1. AVAILABILITY
2. PERFORMANCE
3. SECURITY
4. KVKK
5. BILLING
6. DATA_INTEGRITY
7. SUPPORT_OPS

## Zorunlu severity kapsamı

- P0_CRITICAL
- P1_HIGH
- P2_NORMAL
- P3_LOW

## Kritik kurallar

- Tüm required incident classification rule kayıtları READY olmalıdır.
- tenant_id zorunludur.
- ticket_id zorunludur.
- correlation_id zorunludur.
- audit trail zorunludur.
- root cause zorunludur.
- customer impact zorunludur.
- manual review allowed zorunludur.
- auto close block zorunludur.
- Her rule SLA key ile bağlanmalıdır.
- Her rule escalation key ile bağlanmalıdır.
- Her rule customer template key ile bağlanmalıdır.
- Security incident security review ve engineering owner içermelidir.
- KVKK incident KVKK review içermelidir.
- Billing incident billing owner içermelidir.
- Production auto classification bu fazda kapalı kalır.
- Gerçek müşteri notification bu fazda kapalı kalır.

## Final policy

INTERNAL_CLASSIFICATION_READY=true  
PRODUCTION_AUTO_CLASSIFICATION_ENABLED=false  
CUSTOMER_NOTIFICATION_ENABLED=false  
SUPPORT_OPS_TESTS_REQUIRED_NEXT=true  
NEXT_GATE=FAZ_5_18_4_6_SUPPORT_OPS_TESTLERI
