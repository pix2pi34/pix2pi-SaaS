# 188 — FAZ 4-15.3 e-Belge / Export Reporting Mart

## Amaç

FAZ 4-R DB-L6 Reporting / Readmodel kapsamında e-Belge ve export reporting mart altyapısını kurar.

## Kapsam

Bu adım aşağıdaki tabloları kurar:

- e_document_report_periods
- e_document_documents_mart
- e_document_export_batches_mart
- e_document_export_files_mart
- e_document_status_summary_mart
- e_document_reporting_projection_offsets
- e_document_reporting_audit_events

## Mimari Karar

e-Belge / export reporting mart transactional e-Belge runtime’dan ayrıdır.

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
- Required e-Belge/export mart tabloları metadata üzerinden doğrulanır.
- Required FK / unique / index yapıları doğrulanır.
- e-Belge, export batch, export file, status summary behavior testleri geçer.
- Final status gerçek test/audit sayaçlarından türetilir.
