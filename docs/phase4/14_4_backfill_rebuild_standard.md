# FAZ 4B / 14.4 - Backfill / Rebuild Script Standardı

Amac:
Pilot oncesi readmodel, reporting mart, inventory balance, search projection ve cache/materialized projection yapilarinin guvenli backfill/rebuild standardini tanimlamak.

Bu adim:
- DB mutate etmez.
- Backfill calistirmaz.
- Rebuild calistirmaz.
- SQL apply calistirmaz.
- Migration olusturmaz.
- PostgreSQL config degistirmez.
- Container restart etmez.
- Sadece manifest, dry-run/apply gate standardi ve candidate execution plan uretir.
- Raw DSN, password, token veya query text rapora basmaz.

Backfill / rebuild zorunlu standartlari:
1. Her backfill/rebuild job manifestte kayitli olmali.
2. Her job icin dry-run zorunlu olmali.
3. Her job icin apply gate zorunlu olmali.
4. Tenant-scoped joblar tenant_id olmadan calisamaz.
5. Her job idempotent olmali.
6. Her job cursor/batch standardina sahip olmali.
7. Her job resume/retry/fail-safe kuralina sahip olmali.
8. Her job mutation scope beyan etmeli.
9. Candidate execution plan default olarak blocked olmali.
10. Gercek backfill apply, ayrica controlled apply gate olmadan calistirilmamali.

Kapanis hedefi:
BACKFILL_REBUILD_STANDARD=PASS
BACKFILL_REBUILD_MANIFEST_STATUS=PASS
BACKFILL_REBUILD_DRY_RUN_STATUS=PASS
BACKFILL_REBUILD_APPLY_GATE_STATUS=PASS
BACKFILL_REBUILD_IDEMPOTENCY_STATUS=PASS
BACKFILL_REBUILD_RESUME_STATUS=PASS
BACKFILL_REBUILD_TENANT_SAFETY_STATUS=PASS
BACKFILL_REBUILD_CANDIDATE_PLAN_STATUS=PASS
DB_MUTATION=NO
BACKFILL_APPLY_EXECUTED=NO
REBUILD_APPLY_EXECUTED=NO
QUERY_TEXT_PRINTED=NO
FAZ4B_14_4_FINAL_STATUS=PASS
