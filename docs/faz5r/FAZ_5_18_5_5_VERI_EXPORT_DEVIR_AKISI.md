# FAZ 5-R / 261 — FAZ 5-18.5.5 Veri Export / Devir Akışı

## Amaç

Bu adım, tenant kapatma veya tenant devir senaryosunda veri export/devir akışının contract seviyesini hazırlar.

Bu çalışma production export, gerçek müşteri export/devir, veri silme veya otomatik transfer açmaz. Amaç; export talebi, owner verification, legal hold check, data scope selection, KVKK masking, bundle hazırlama, checksum manifest, secure download, handover acceptance ve data deletion deferred marker akışlarını tenant-safe ve audit edilebilir hale getirmektir.

## Kapsam

1. export_request_intake
2. owner_verification
3. legal_hold_check
4. data_scope_selection
5. kvkk_masking_policy
6. export_bundle_prepare
7. checksum_manifest_create
8. secure_download_package
9. handover_acceptance_record
10. data_deletion_deferred_marker

## Kritik kurallar

- Production export kapalı kalır.
- Gerçek müşteri export/devir kapalı kalır.
- Data deletion kapalı kalır.
- Auto transfer kapalı kalır.
- tenant_id zorunludur.
- export_request_id zorunludur.
- owner approval zorunludur.
- legal hold check zorunludur.
- data scope zorunludur.
- KVKK masking zorunludur.
- data classification zorunludur.
- format policy zorunludur.
- checksum manifest zorunludur.
- encryption zorunludur.
- secure download zorunludur.
- audit trail zorunludur.
- retention policy zorunludur.
- handover acceptance zorunludur.
- support handoff zorunludur.
- Gerçek veri silme/devir kapanışı production approval ve tenant kapatma final gate sonrası açılır.

## Final policy

INTERNAL_DATA_EXPORT_FLOW_READY=true  
PRODUCTION_EXPORT_ENABLED=false  
REAL_CUSTOMER_EXPORT_ENABLED=false  
DATA_DELETION_ENABLED=false  
AUTO_TRANSFER_ENABLED=false  
TENANT_UPGRADE_DOWNGRADE_REQUIRED_NEXT=true  
NEXT_GATE=FAZ_5_18_5_2_TENANT_YUKSELTME_DUSURME
