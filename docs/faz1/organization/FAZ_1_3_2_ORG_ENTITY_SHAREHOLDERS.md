# FAZ 1-3.2 — org.entity_shareholders

## Kapsam

- Ortaklık modeli
- Pay oranı
- Effective date
- Shareholder type
- Ownership audit

## FIX V5

FIX V5 ownership abuse test sırasını düzeltti:
- OVER_100 testi ACTIVE kaldı.
- SELF_OWNERSHIP testi INACTIVE yapıldı.
- BAD_TYPE testi INACTIVE yapıldı.
- BAD_DATE testi INACTIVE yapıldı.
- NEGATIVE percentage testi ACTIVE kaldı.

Böylece over-100 trigger sadece kendi senaryosunda çalışır, diğer abuse testlerinde ilgili check constraint'ler gerçek olarak doğrulanır.

## Final Status

- FAZ_1_3_2_ENTITY_SHAREHOLDERS_MODEL_STATUS=PASS
- FAZ_1_3_2_OWNERSHIP_PERCENTAGE_STATUS=PASS
- FAZ_1_3_2_EFFECTIVE_DATE_STATUS=PASS
- FAZ_1_3_2_SHAREHOLDER_TYPE_STATUS=PASS
- FAZ_1_3_2_OWNERSHIP_AUDIT_STATUS=PASS
- FAZ_1_3_2_ENTITY_SHAREHOLDERS_FINAL_STATUS=PASS
- FAZ_1_3_2_ENTITY_SHAREHOLDERS_SEAL_STATUS=SEALED
