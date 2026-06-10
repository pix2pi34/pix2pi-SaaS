# FAZ 1-3.3 — franchise.agreements

## Kapsam

- Franchise sözleşme modeli
- Franchise owner/operator
- Start/end date
- Status lifecycle
- Agreement audit

## FIX V4

FIX V3 agreement_code legacy bridge'i kurdu. Sonraki testte mevcut legacy starts_on NOT NULL kolonu yakalandı.

FIX V4:
- start_date ve legacy starts_on arasında bridge kurar.
- end_date ve legacy ends_on arasında bridge kurar.
- terminated_at ve legacy terminated_on arasında bridge kurar.
- business_code/agreement_number/agreement_code bridge korunur.
- Yeni lifecycle standardı agreement_lifecycle_status üzerinden korunur.

## Final Status

- FAZ_1_3_3_FRANCHISE_AGREEMENT_MODEL_STATUS=PASS
- FAZ_1_3_3_FRANCHISE_OWNER_OPERATOR_STATUS=PASS
- FAZ_1_3_3_START_END_DATE_STATUS=PASS
- FAZ_1_3_3_STATUS_LIFECYCLE_STATUS=PASS
- FAZ_1_3_3_AGREEMENT_AUDIT_STATUS=PASS
- FAZ_1_3_3_FRANCHISE_AGREEMENTS_FINAL_STATUS=PASS
- FAZ_1_3_3_FRANCHISE_AGREEMENTS_SEAL_STATUS=SEALED
