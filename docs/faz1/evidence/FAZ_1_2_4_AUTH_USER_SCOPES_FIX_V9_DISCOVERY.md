# FAZ 1-2.4 auth.user_scopes FIX V9 Discovery

- Tarih: 2026-05-04T19:51:59+03:00
- Repo: /root/pix2pi/pix2pi-SaaS
- Backup dir: /root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_2_4_user_scopes_fix_v9_discovery_20260504_195158

## Neden V9 Discovery?

FIX V8 suite, FK hedef tabloya geçici org.legal_entities kaydı açarken core.code_text domain check'e takıldı.
Bu discovery, V9 için gerçek domain/check/FK haritasını çıkarır.

## Evidence Files

- user_scopes_fk_map.txt
- user_scopes_columns.txt
- fk_target_columns.txt
- domain_enum_constraints.txt
- org_auth_constraints.txt
- base_counts.txt

## Counters

- PASS_COUNT=12
- FAIL_COUNT=0
- WARN_COUNT=0
