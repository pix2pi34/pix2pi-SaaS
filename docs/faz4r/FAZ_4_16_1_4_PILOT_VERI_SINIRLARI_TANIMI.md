# 192 — FAZ 4-16.1.4 Pilot Veri Sınırları Tanımı

## Amaç

FAZ 4-R LVL17 Pilot / UAT / Onboarding bloğuna başlamadan önce pilot tenant için veri sınırlarını netleştirir.

Bu adım pilotun kontrollü, ölçülebilir, rollback edilebilir ve UAT'a hazır şekilde ilerlemesini sağlar.

## Kapsam

Pilot veri sınırları aşağıdaki alanları kapsar:

- Tenant sınırı
- Kullanıcı / rol sınırı
- Cari veri sınırı
- Ürün / stok veri sınırı
- Fiş / hareket veri sınırı
- e-Belge / export veri sınırı
- UAT senaryo sınırı
- Destek / issue sınırı
- Import batch sınırı
- Cutover / rollback veri sınırı

## Ana Kural

Pilot canlı dış provider, GIB, banka veya POS aktivasyonu yapmaz.

Policy:

CLOSED_POLICY_GATE_REFERENCE_ONLY

## Pilot Veri Limitleri

Başlangıç pilotu için kontrollü üst sınırlar:

- max_tenant_count: 1
- max_admin_user_count: 3
- max_operator_user_count: 10
- max_customer_count: 500
- max_product_count: 5000
- max_stock_entry_count: 20000
- max_finance_document_count: 5000
- max_e_document_export_count: 1000
- max_import_batch_count: 25
- max_uat_case_count: 100
- max_open_issue_count: 50
- max_critical_issue_count: 0

## Pilot Veri Kabul Mantığı

Pilot verisi PASS sayılırsa:

- Tenant sayısı sınır içinde kalır.
- Kullanıcı sayısı sınır içinde kalır.
- Cari / ürün / stok / finans / e-Belge kayıtları sınır içinde kalır.
- Kritik issue sayısı 0 kalır.
- UAT case sayısı planlanan sınır içinde kalır.
- Import batch sayısı kontrollü kalır.
- Canlı dış entegrasyon policy kapısı kapalı kalır.

## Çıkış Kriterleri

Bu adım PASS sayılırsa:

- Pilot veri sınırı dokümanı vardır.
- Config artifact vardır.
- Runtime validation script vardır ve executable durumdadır.
- Test fixture vardır.
- Audit script vardır.
- Valid fixture PASS döner.
- Invalid fixture FAIL döner.
- Closed policy marker doğrulanır.
- Final status gerçek test/audit sayaçlarından türetilir.
