# FAZ 1-3.4 — Store / Facility / Warehouse Lokasyon Modeli

## Kapsam

- Store
- Facility
- Warehouse
- Branch relation
- Inventory relation
- Location tests

## FIX V2

İlk testte inventory.location_inventory_links içindeki TDHP hesap kodu regex constraint'i 153.01 gibi geçerli alt hesap formatını reddetti.

FIX V2:
- ck_inventory_location_links_stock_account_format kaldırıldı.
- ck_inventory_location_links_account_format eklendi.
- 153 ve 153.01 gibi hesaplar geçerli kabul edilir.
- BAD-ACCOUNT ve BAD-COGS gibi formatlar engellenir.
- default_stock_account_code ve default_cogs_account_code birlikte korunur.

## Final Status

- FAZ_1_3_4_STORE_MODEL_STATUS=PASS
- FAZ_1_3_4_FACILITY_MODEL_STATUS=PASS
- FAZ_1_3_4_WAREHOUSE_MODEL_STATUS=PASS
- FAZ_1_3_4_BRANCH_RELATION_STATUS=PASS
- FAZ_1_3_4_INVENTORY_RELATION_STATUS=PASS
- FAZ_1_3_4_TDHP_ACCOUNT_FORMAT_STATUS=PASS
- FAZ_1_3_4_LOCATION_FINAL_STATUS=PASS
- FAZ_1_3_4_LOCATION_SEAL_STATUS=SEALED
