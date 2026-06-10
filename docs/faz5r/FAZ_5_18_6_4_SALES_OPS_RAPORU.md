# FAZ 5-R / 267 — FAZ 5-18.6.4 Sales Ops Raporu

## Amaç

Bu adım, CRM stage yönetimi ve teklif/satış akışından gelen commercial ops kanıtlarını tek sales ops raporu contract seviyesinde toplar.

Bu çalışma production rapor yayını, gerçek müşteri raporu, external BI export veya otomatik yönetici e-postası açmaz. Amaç; pipeline, teklif, conversion, aktivite, forecast, lost reason, owner performance ve audit evidence bölümlerini tenant-safe, privacy-safe ve audit edilebilir hale getirmektir.

## Kapsam

1. crm_pipeline_summary
2. quote_sales_summary
3. conversion_funnel_summary
4. activity_sla_summary
5. forecast_pipeline_summary
6. lost_reason_summary
7. owner_performance_summary
8. audit_evidence_summary
9. mrr_arr_report_deferred_marker

## Kritik kurallar

- Production report kapalı kalır.
- Real customer report kapalı kalır.
- External BI export kapalı kalır.
- Auto executive email kapalı kalır.
- tenant_id zorunludur.
- date window zorunludur.
- CRM stage source zorunludur.
- quote sales source zorunludur.
- pipeline metrics zorunludur.
- conversion metrics zorunludur.
- activity metrics zorunludur.
- forecast metrics zorunludur.
- lost reason breakdown zorunludur.
- owner breakdown zorunludur.
- audit trail zorunludur.
- data freshness zorunludur.
- export policy zorunludur.
- privacy guard zorunludur.

## Final policy

INTERNAL_SALES_OPS_REPORT_READY=true  
PRODUCTION_REPORT_ENABLED=false  
REAL_CUSTOMER_REPORT_ENABLED=false  
EXTERNAL_BI_EXPORT_ENABLED=false  
AUTO_EXECUTIVE_EMAIL_ENABLED=false  
MRR_ARR_REPORT_REQUIRED_NEXT=true  
NEXT_GATE=FAZ_5_18_7_1_MRR_ARR_RAPORU
