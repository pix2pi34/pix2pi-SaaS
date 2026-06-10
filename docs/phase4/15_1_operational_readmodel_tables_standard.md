# FAZ 4 / 15.1 - Operational Readmodel Tables

Amac:
Pilot / UAT / onboarding surecinde operasyonel dashboard, durum izleme ve hizli sorgu ihtiyaci icin readmodel tablo omurgasini hazirlamak.

Bu adim:
- Canli DB'ye migration apply etmez.
- DB mutate etmez.
- Sadece migration candidate dosyalarini yazar.
- Up/down migration pair uretir.
- Tenant-safe readmodel tablo sozlesmesi uretir.
- Test ve evidence raporu uretir.

Olusturulan readmodel kapsami:
1. readmodel.projection_state
2. readmodel.tenant_operational_snapshot
3. readmodel.daily_operational_metrics
4. readmodel.inventory_status_snapshot
5. readmodel.document_work_queue
6. readmodel.reconciliation_status_snapshot

Temel kurallar:
- Her business readmodel tablosunda tenant_id zorunludur.
- Query-first tablo tasarimi kullanilir.
- Operational readmodel tablolarinda source-of-truth davranisi yoktur.
- Rebuild edilebilir projection mantigi esas alinmistir.
- Apply islemi ayri gate ile yapilacaktir.

Kapanis hedefi:
OPERATIONAL_READMODEL_TABLES=PASS
READMODEL_MIGRATION_PAIR=PASS
DB_APPLY_EXECUTED=NO
DB_MUTATION=NO
FAZ4_15_1_FINAL_STATUS=PASS
