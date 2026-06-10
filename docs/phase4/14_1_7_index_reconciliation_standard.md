# FAZ 4 / 14.1.7 - Index-only Reconciliation Plan / Safe Apply Candidate List

Amac:
14.1.6B ile bulunan missing index listesinden guvenli index-only reconciliation plani uretmek.

Bu adim:
- DB mutate etmez.
- Migration apply yapmaz.
- Index create komutlarini calistirmaz.
- Sadece plan ve rapor uretir.

Guvenlik kurallari:
1. Sadece missing INDEX satirlari islenir.
2. Index SQL'i migration up dosyasindan alinir.
3. CREATE INDEX statement'i parse edilir.
4. Index'in bagli oldugu table bulunur.
5. Table DB'de yoksa index apply candidate olmaz.
6. Index DB'de zaten varsa skipped olur.
7. Table varsa ve index yoksa safe candidate olur.
8. Plan SQL dosyasi uretilir ama calistirilmaz.
9. Raw DB password rapora basilmaz.

Kapanis hedefi:
INDEX_RECONCILIATION_PLAN=PASS
INDEX_PLAN_MUTATION=NO
SAFE_INDEX_CANDIDATE_COUNT raporlanir
SKIPPED_TABLE_MISSING_COUNT raporlanir
ALREADY_EXISTS_INDEX_COUNT raporlanir
FAZ4_14_1_7_FINAL_STATUS=PASS
