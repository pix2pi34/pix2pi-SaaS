# FAZ 5-R / 269 — FAZ 5-18.7.2 Churn / Expansion Raporu

## Amaç

Bu adım, MRR / ARR raporundan sonra gelir hareketlerini churn, expansion, contraction, NRR ve GRR perspektifinde contract seviyesinde hazırlar.

Bu çalışma production motion report, gerçek müşteri revenue hareket raporu, external finance export veya otomatik yönetici e-postası açmaz.

## Kapsam

1. starting_mrr_base
2. churned_tenant_summary
3. churned_mrr_summary
4. expansion_tenant_summary
5. expansion_mrr_summary
6. contraction_mrr_summary
7. nrr_summary
8. grr_summary
9. churn_reason_breakdown
10. audit_evidence_summary
11. collection_success_deferred_marker

## Kritik kurallar

- Production motion report kapalı kalır.
- Real customer motion report kapalı kalır.
- External finance export kapalı kalır.
- Auto executive email kapalı kalır.
- tenant_id zorunludur.
- period window zorunludur.
- starting MRR base zorunludur.
- ending MRR base zorunludur.
- churn metric zorunludur.
- expansion metric zorunludur.
- contraction metric zorunludur.
- NRR formula zorunludur.
- GRR formula zorunludur.
- reason breakdown zorunludur.
- subscription source zorunludur.
- billing source zorunludur.
- plan change source zorunludur.
- cancellation source zorunludur.
- collection risk signal zorunludur.
- data freshness zorunludur.
- audit trail zorunludur.
- privacy guard zorunludur.
- export policy zorunludur.

## Formül standardı

- NRR = (starting_mrr - churned_mrr - contraction_mrr + expansion_mrr) / starting_mrr
- GRR = (starting_mrr - churned_mrr - contraction_mrr) / starting_mrr
- Logo churn rate = churned_tenant_count / starting_active_tenant_count
- Revenue churn rate = churned_mrr / starting_mrr

## Final policy

INTERNAL_CHURN_EXPANSION_REPORT_READY=true  
PRODUCTION_MOTION_REPORT_ENABLED=false  
REAL_CUSTOMER_MOTION_ENABLED=false  
EXTERNAL_FINANCE_EXPORT_ENABLED=false  
AUTO_EXECUTIVE_EMAIL_ENABLED=false  
COLLECTION_SUCCESS_REPORT_REQUIRED_NEXT=true  
NEXT_GATE=FAZ_5_18_7_3_TAHSILAT_BASARI_RAPORU
