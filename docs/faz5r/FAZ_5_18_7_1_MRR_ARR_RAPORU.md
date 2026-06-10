# FAZ 5-R / 268 — FAZ 5-18.7.1 MRR / ARR Raporu

## Amaç

Bu adım, satış ve faturalama hattından gelen recurring revenue verilerini MRR / ARR raporu contract seviyesinde hazırlar.

Bu çalışma production revenue report, gerçek müşteri revenue raporu, external finance export veya otomatik yatırımcı e-postası açmaz. Amaç; subscription base, MRR, ARR, new MRR, expansion MRR, contraction MRR, collection status ve audit evidence bölümlerini tenant-safe, tax-aware ve audit edilebilir hale getirmektir.

## Kapsam

1. subscription_base_snapshot
2. mrr_summary
3. arr_summary
4. new_mrr_summary
5. expansion_mrr_summary
6. contraction_mrr_summary
7. collection_status_summary
8. audit_evidence_summary
9. churn_expansion_deferred_marker

## Kritik kurallar

- Production revenue report kapalı kalır.
- Real customer revenue report kapalı kalır.
- External finance export kapalı kalır.
- Auto investor email kapalı kalır.
- tenant_id zorunludur.
- period window zorunludur.
- subscription source zorunludur.
- billing source zorunludur.
- plan snapshot zorunludur.
- currency policy zorunludur.
- MRR formula zorunludur.
- ARR formula zorunludur.
- expansion metric zorunludur.
- contraction metric zorunludur.
- collection status zorunludur.
- tax exclusion policy zorunludur.
- data freshness zorunludur.
- audit trail zorunludur.
- privacy guard zorunludur.
- export policy zorunludur.

## Formül standardı

- MRR = aktif aylık recurring gelir toplamı, KDV hariç
- ARR = MRR x 12
- New MRR = ilk dönem recurring gelir toplamı, KDV hariç
- Expansion MRR = upgrade kaynaklı pozitif recurring fark
- Contraction MRR = downgrade kaynaklı negatif recurring fark

## Final policy

INTERNAL_MRR_ARR_REPORT_READY=true  
PRODUCTION_REVENUE_REPORT_ENABLED=false  
REAL_CUSTOMER_REVENUE_ENABLED=false  
EXTERNAL_FINANCE_EXPORT_ENABLED=false  
AUTO_INVESTOR_EMAIL_ENABLED=false  
CHURN_EXPANSION_REPORT_REQUIRED_NEXT=true  
NEXT_GATE=FAZ_5_18_7_2_CHURN_EXPANSION_RAPORU
