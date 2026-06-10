# 184 — FAZ 4-14.2 Reference Data / Seed Standardı

## Amaç

FAZ 4-R import, staging, migration ve UAT süreçleri için ortak reference data / seed standardı kurar.

## Kapsam

Bu adım aşağıdaki seed altyapısını kurar:

- reference_seed_sets
- reference_seed_items
- idempotent seed apply
- dry-run varsayılan çalışma
- APPLY=1 olmadan mutation yapmama
- schema guard
- seed scope / seed version standardı
- import type seed
- import status seed
- entity type seed
- validation status seed
- transform status seed
- commit status seed
- customer type seed
- product type seed
- stock movement type seed
- finance document type seed
- unit seed
- currency seed
- VAT seed

## Mimari Karar

Reference data doğrudan uygulama koduna gömülmez.

Seed kayıtları DB içinde izlenebilir registry yapısında saklanır.

Seed tekrar çalıştırıldığında duplicate üretmez.

## Güvenlik Kuralı

Varsayılan mod dry-run'dır.

APPLY=1 verilmeden DB mutation yapılmaz.

Canlı dış provider, GIB, banka veya POS aktivasyonu yapılmaz.

Policy:

CLOSED_POLICY_GATE_REFERENCE_ONLY

## Çıkış Kriterleri

Bu adım PASS sayılırsa:

- Seed SQL artifact vardır.
- Runtime apply script vardır ve executable durumdadır.
- Config artifact vardır.
- SQL test artifact vardır.
- Audit script vardır.
- Dry-run veri değiştirmez.
- APPLY=1 reference seed tablolarını ve kayıtlarını oluşturur.
- İkinci APPLY duplicate üretmez.
- Seed kayıtları PostgreSQL üzerinde metadata/data testiyle doğrulanır.
- Final status gerçek test/audit sayaçlarından türetilir.
