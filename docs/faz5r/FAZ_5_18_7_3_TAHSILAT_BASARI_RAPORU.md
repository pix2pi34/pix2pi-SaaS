# FAZ 5-R / 270 — FAZ 5-18.7.3 Tahsilat Başarı Raporu

## Amaç

Bu adım, billing ve ödeme attempt hattından gelen tahsilat başarısını rapor contract seviyesinde hazırlar.

Bu çalışma production collection report, gerçek müşteri tahsilat raporu, external finance export veya otomatik dunning/takip aksiyonu açmaz.

## Kapsam

1. billing_base_snapshot
2. invoice_collection_summary
3. collection_success_summary
4. failed_payment_summary
5. recovery_summary
6. aging_bucket_summary
7. collection_risk_summary
8. audit_evidence_summary
9. internal_finance_dashboard_deferred_marker

## Kritik kurallar

- Production collection report kapalı kalır.
- Real customer collection report kapalı kalır.
- External finance export kapalı kalır.
- Auto dunning kapalı kalır.
- tenant_id zorunludur.
- period window zorunludur.
- invoice source zorunludur.
- billing source zorunludur.
- payment attempt source zorunludur.
- success rate formula zorunludur.
- failed payment metric zorunludur.
- recovery metric zorunludur.
- aging bucket zorunludur.
- collection risk signal zorunludur.
- tax policy zorunludur.
- data freshness zorunludur.
- audit trail zorunludur.
- privacy guard zorunludur.
- export policy zorunludur.

## Formül standardı

- Collection success rate = paid_invoice_count / due_invoice_count
- Collection amount success rate = collected_amount_excluding_tax / due_amount_excluding_tax
- Failed payment rate = failed_payment_attempt_count / total_payment_attempt_count
- Recovery rate = recovered_invoice_count / failed_invoice_count

## Final policy

INTERNAL_COLLECTION_SUCCESS_REPORT_READY=true  
PRODUCTION_COLLECTION_REPORT_ENABLED=false  
REAL_CUSTOMER_COLLECTION_ENABLED=false  
EXTERNAL_FINANCE_EXPORT_ENABLED=false  
AUTO_DUNNING_ENABLED=false  
INTERNAL_FINANCE_DASHBOARD_REQUIRED_NEXT=true  
NEXT_GATE=FAZ_5_18_7_4_IC_FINANS_DASHBOARD
