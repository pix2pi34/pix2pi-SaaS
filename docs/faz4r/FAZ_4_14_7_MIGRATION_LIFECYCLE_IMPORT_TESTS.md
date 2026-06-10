# 181 — FAZ 4-14.7 Migration / Lifecycle / Import Testleri

## Amaç

180 — FAZ 4-14.3 Import / staging tabloları adımında oluşturulan import staging altyapısının gerçek PostgreSQL üzerinde lifecycle ve import davranış testlerinden geçmesini sağlar.

## Test Kapsamı

Bu adım aşağıdaki testleri yapar:

- En güncel 180 migration dosyasını bulur.
- Migration dosyasını temporary schema içinde uygular.
- import_batches kaydı oluşturur.
- import_source_files kaydı oluşturur.
- raw staging row kayıtları oluşturur.
- customer staging kaydı oluşturur.
- product staging kaydı oluşturur.
- stock staging kaydı oluşturur.
- finance document staging kaydı oluşturur.
- validation error kaydı oluşturur.
- audit event kaydı oluşturur.
- batch lifecycle status geçişlerini test eder.
- row count sayaçlarını test eder.
- foreign key guard davranışını test eder.
- validation status update davranışını test eder.
- commit_status update davranışını test eder.
- rollback ile temporary schema etkisini geri alır.

## Canlı Veri Güvenliği

Test temporary schema içinde çalışır.

Test sonunda ROLLBACK yapılır.

Canlı domain tablolarına veri yazmaz.

## Dış Provider Policy

Bu adım canlı dış provider, GIB, banka veya POS aktivasyonu yapmaz.

Policy:

CLOSED_POLICY_GATE_REFERENCE_ONLY

## Çıkış Kriterleri

Bu adım PASS sayılırsa:

- Test SQL dosyası vardır.
- Config artifact vardır.
- Audit script vardır.
- 180 migration dosyası bulunur.
- PostgreSQL bağlantısı vardır.
- SQL lifecycle testleri PASS döner.
- Lifecycle test çıktısı gerçek database davranışından gelir.
- Final status PASS/FAIL sayaçlarından türetilir.
