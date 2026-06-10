# FAZ 6 — ERP Event → Journal → Ledger Final Closure

## Amaç

Bu adım Pix2pi ERP finans çekirdeğinin event-driven muhasebe hattını final audit ile kapatır.

## Kontrol kapsamı

- ERP event intake
- Event → accounting rule mapping
- Accounting rule versioning
- Journal builder
- TDHP mapping
- Ledger posting pipeline
- Double posting guard
- Failed posting isolation
- Replay-safe accounting
- Financial audit trace
- ERP financial flow Go test
- PostgreSQL journal / ledger / accounting table izi

## Güvenlik kararı

Bu adım gerçek canlı finansal posting başlatmaz. Sadece mevcut gerçek implementasyon, test ve DB izlerini denetler.

## Final gate

Bu adım ancak gerçek audit ve Go test sonucu PASS olduğunda kapanır.

## Dosyalar

- Audit script: `scripts/audit/faz6/faz_6_erp_event_journal_ledger_final_closure_audit.sh`
- Evidence: `docs/faz6/evidence/FAZ_6_ERP_EVENT_JOURNAL_LEDGER_FINAL_CLOSURE_REAL_IMPLEMENTATION_AUDIT_20260506_193613.md`
