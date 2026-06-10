# FAZ 5-R / 264 — FAZ 5-18.5.6 Tenant Lifecycle Testleri

## Amaç

Bu adım, tenant lifecycle hattında 260–263 arasında kapatılan akışların test-suite ve cross-flow audit contract seviyesini hazırlar.

Bu çalışma production tenant lifecycle live, gerçek müşteri operasyonu veya otomatik lifecycle geçişi açmaz. Amaç; tenant kapatma, veri export/devir, tenant yükseltme/düşürme ve tenant dondurma akışlarının evidence, config, runtime, audit, tenant_id, audit trail, rollback ve production block kurallarını tek suite altında doğrulamaktır.

## Kapsam

1. tenant_shutdown_contract_test
2. tenant_data_export_contract_test
3. tenant_plan_change_contract_test
4. tenant_freeze_contract_test
5. cross_flow_billing_guard_test
6. cross_flow_audit_evidence_test
7. crm_stage_deferred_marker

## Kritik kurallar

- Production lifecycle live kapalı kalır.
- Real customer ops kapalı kalır.
- Her lifecycle akışında evidence bulunmalıdır.
- Her lifecycle akışında counter based audit bulunmalıdır.
- Her lifecycle akışında tenant_id coverage olmalıdır.
- Her lifecycle akışında audit trail coverage olmalıdır.
- Her lifecycle akışında rollback coverage olmalıdır.
- Her lifecycle akışında config fixture bulunmalıdır.
- Her lifecycle akışında runtime package bulunmalıdır.
- Her lifecycle akışında evidence file bulunmalıdır.
- Cross-flow billing guard bulunmalıdır.
- CRM stage yönetimi sıradaki işe defer edilir.

## Final policy

INTERNAL_LIFECYCLE_TESTS_READY=true  
PRODUCTION_LIFECYCLE_LIVE_ENABLED=false  
REAL_CUSTOMER_OPS_OPEN=false  
TENANT_LIFECYCLE_BLOCK_COMPLETE=true  
CRM_STAGE_MANAGEMENT_REQUIRED_NEXT=true  
NEXT_GATE=FAZ_5_18_6_2_CRM_STAGE_YONETIMI
