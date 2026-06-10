# FAZ 1-1.2 Legal Entity Model

## Kapsam

- Firma modeli
- Vergi bilgileri
- Ticari unvan
- Adres bağlantısı
- Tenant relation
- Legal entity tests

## FIX V5

FIX V4 lifecycle testi sentetik tenant_id kullandığı için tenants FK tarafından doğru şekilde engellendi. FIX V5 test tenant'ını uydurmaz; org.legal_entities.tenant_id FK metadata'sından gerçek tenants referans tablosunu ve UUID kolonunu bulur, mevcut gerçek tenant_id ile lifecycle testini çalıştırır.

## Kurallar

- tax_number zorunludur.
- tax_office zorunludur.
- legal_name zorunludur.
- address_line zorunludur.
- mersis_no opsiyoneldir.
- phone ve email alanları desteklenir.
- address bağlantısı legal_entity_id + tenant_id composite relation ile tenant-safe korunur.
- legal entity tablolarında RLS enabled + forced uygulanır.

## Final Status

- FAZ_1_1_2_COMPANY_MODEL_STATUS=PASS
- FAZ_1_1_2_TAX_INFO_STATUS=PASS
- FAZ_1_1_2_TRADE_TITLE_STATUS=PASS
- FAZ_1_1_2_ADDRESS_LINK_STATUS=PASS
- FAZ_1_1_2_TENANT_RELATION_STATUS=PASS
- FAZ_1_1_2_LEGAL_ENTITY_TEST_STATUS=PASS
- FAZ_1_1_2_LEGAL_ENTITY_MODEL_SEAL_STATUS=SEALED
