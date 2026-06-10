# FAZ 4C — 4C-3E-FIX3A code_text Domain Discovery Report

Step: 4C-3E-FIX3A
Blok: code_text Domain Discovery
Test tarihi: 2026-05-01 07:22:10

## Test sonucu

4C_3E_FIX3A_DOMAIN_DISCOVERY_STATUS=PASS
4C_3E_FIX3A_DB_CONNECT_STATUS=PASS
4C_3E_FIX3A_BEST_BUSINESS_CODE=UZMANPARCACI
4C_3E_FIX3A_DB_WRITE_APPLIED=NO
4C_3D_FIX3_READY=YES

## Domain constraint

```text
code_text_check | CHECK ((VALUE ~ '^[A-Z0-9_\-]+$'::text))
```

## Domain cast testleri

```text
uzmanparcaci => FAIL
UZMANPARCACI => PASS
UZMAN_PARCACI => PASS
TENANT_UZMANPARCACI => PASS
UZMAN-PARCACI => PASS
uzman_parcaci => FAIL
UZMAN PARCACI => FAIL

```

## Mevcut tenant code örnekleri

```text

```

## Sonuç

core.code_text domain kuralı keşfedildi.
Kalıcı DB yazma yapılmadı.
Bir sonraki adımda business_code bu kurala göre düzeltilecek.
