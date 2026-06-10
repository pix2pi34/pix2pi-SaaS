# FAZ 7-R / 325 RECHECK AFTER 332 POS CHECKOUT PAYMENT AUDIT

- PASS_COUNT=23
- FAIL_COUNT=0
- WARN_COUNT=0
- FINAL_STATUS=PASS
- RUN_ID=sales-pos-management-325-recheck-after-332-20260513_231343

## 332 checkout recheck
```
latest_332_paid_cart=1
latest_332_paid_payment=1
latest_332_cart_items=1
latest_332_failed_payment=1
latest_332_no_role_cart=0
latest_332_rollback_item=0
```

## 325 DB surface recheck
```
sales_related_tables=40
sales_pos_audit_related_tables=7
pos_checkout_tables=4
```

## 325 route recheck
```
panel.pix2pi.com.tr/sales-pos-management/ HTTP=200
route_match=panel.pix2pi.com.tr/sales-pos-management/
```

## Compatibility SELECT
```
checkout_paid_cart_count=1
checkout_paid_payment_count=1
checkout_failed_payment_count=1
checkout_audit_allow_count=5
```

## Check log
```
dependency PASS evidence: FAZ_7R_325_SALES_POS_MANAGEMENT_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_332_POS_CHECKOUT_PAYMENT_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_331_POS_SALE_REAL_FINAL_AUDIT.md / OK ✅
optional downstream smoke already PASS: FAZ_7R_355_FIRST_REAL_USAGE_SMOKE_REAL_FINAL_AUDIT.md / OK ✅
Postgres connection detected: docker/pix2pi_pg/pix2pi / OK ✅
332_RECHECK_DB_STATUS latest_332_paid_cart=1 / OK ✅
332_RECHECK_DB_STATUS latest_332_paid_payment=1 / OK ✅
332_RECHECK_DB_STATUS latest_332_cart_items=1 / OK ✅
332_RECHECK_DB_STATUS latest_332_failed_payment=1 / OK ✅
332_RECHECK_DB_STATUS latest_332_no_role_cart=0 / OK ✅
332_RECHECK_DB_STATUS latest_332_rollback_item=0 / OK ✅
325 evidence final status PASS / OK ✅
325 evidence FAIL_COUNT=0 / OK ✅
325 legacy evidence fallback: FINAL_STATUS=PASS and FAIL_COUNT=0 / OK ✅
sales/POS related DB tables >= 4 / OK ✅
sales/POS audit related DB tables >= 1 / OK ✅
pos_checkout required tables count=4 / OK ✅
325 route recheck reached live sales/POS management surface / OK ✅
checkout_paid_cart_count >= 1 / OK ✅
checkout_paid_payment_count >= 1 / OK ✅
checkout_failed_payment_count >= 1 / OK ✅
checkout_audit_allow_count >= 5 / OK ✅
config semantic validation / OK ✅
```
