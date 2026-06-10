# 187 — FAZ 4-15.4 Payment / Reconciliation Reporting Mart

## Amaç

FAZ 4-R DB-L6 Reporting / Readmodel kapsamında payment ve reconciliation reporting mart altyapısını kurar.

## Kapsam

Bu adım aşağıdaki tabloları kurar:

- payment_report_periods
- payment_attempts_mart
- payment_reconciliation_mart
- payment_settlement_summary_mart
- payment_fee_summary_mart
- payment_reporting_projection_offsets
- payment_reporting_audit_events

## Mimari Karar

Payment reporting mart transactional payment runtime’dan ayrıdır.

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
- Required payment mart tabloları metadata üzerinden doğrulanır.
- Required FK / unique / index yapıları doğrulanır.
- Payment/reconciliation/settlement/fee behavior testleri geçer.
- Final status gerçek test/audit sayaçlarından türetilir.
