# FAZ 1-3.8 — Org Graph Testleri

## Kapsam

- Holding graph test
- Franchise graph test
- Visibility graph test
- Cycle prevention test
- Permission test

## FIX V14

İlk denemede org.entity_relations tablosunda relation_code kolonu olmadığı için test insert'i başarısız oldu.

FIX V14:
- org.entity_relations insert schema-aware hale getirildi.
- relation_code varsa kullanılır, yoksa atlanır.
- business_code, relation_type, visibility_rule_id, effective_from, status, relation_audit_ref, metadata kolonları da mevcutsa kullanılır.
- Holding graph testi gerçek tablo kolonlarına göre çalışır.
- Cycle prevention, franchise graph, visibility graph ve permission abuse testleri tekrar çalıştırılır.

## Final Status

- FAZ_1_3_8_HOLDING_GRAPH_TEST_STATUS=PASS
- FAZ_1_3_8_FRANCHISE_GRAPH_TEST_STATUS=PASS
- FAZ_1_3_8_VISIBILITY_GRAPH_TEST_STATUS=PASS
- FAZ_1_3_8_CYCLE_PREVENTION_TEST_STATUS=PASS
- FAZ_1_3_8_PERMISSION_TEST_STATUS=PASS
- FAZ_1_3_8_ORG_GRAPH_FINAL_STATUS=PASS
- FAZ_1_3_8_ORG_GRAPH_SEAL_STATUS=SEALED
