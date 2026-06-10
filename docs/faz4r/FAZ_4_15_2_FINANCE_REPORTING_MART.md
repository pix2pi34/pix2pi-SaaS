# 186 — FAZ 4-15.2 Finance Reporting Mart

## Amaç

FAZ 4-R DB-L6 Reporting / Readmodel kapsamında finansal raporlama mart altyapısını kurar.

## Kapsam

Bu adım aşağıdaki tabloları kurar:

- finance_report_periods
- finance_account_balances_mart
- finance_income_expense_mart
- finance_tax_summary_mart
- finance_ar_ap_aging_mart
- finance_reporting_projection_offsets
- finance_reporting_audit_events

## Mimari Karar

Finance reporting mart transactional ledger / journal hattından ayrıdır.

Bu tablolar readmodel/reporting amacıyla kullanılır.

## Tenant Güvenliği

Tüm tablolarda tenant_id zorunludur.

Primary key ve index tasarımları tenant_id ile başlar.

## Dış Provider Policy

Bu adım canlı dış provider, GIB, banka veya POS aktivasyonu yapmaz.

Policy:

CLOSED_POLICY_GATE_REFERENCE_ONLY

## Çıkış Kriterleri

Bu adım PASS sayılırsa:

- Migration dosyası vardır.
- Rollback dosyası vardır.
- Config artifact vardır.
- SQL test artifact vardır.
- Audit script vardır.
- PostgreSQL temporary schema içinde migration uygulanır.
- Required finance mart tabloları metadata üzerinden doğrulanır.
- Required FK / unique / index yapıları doğrulanır.
- Finance reporting insert/update/query davranış testleri geçer.
- Final status gerçek test/audit sayaçlarından türetilir.
