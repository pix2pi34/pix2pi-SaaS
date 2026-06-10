# FAZ 1-2.8 API Live Cross-Tenant E2E FIX V8 Diagnostic

- Tarih: 2026-05-04T22:44:36+03:00
- Repo: /root/pix2pi/pix2pi-SaaS
- Probe log: /root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_2_8_api_live_cross_tenant_e2e_fix_v8_20260504_224346/api_live_e2e_v8_probe_matrix.log
- Diagnostic file: /root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_2_8_api_live_cross_tenant_e2e_fix_v8_20260504_224346/api_live_e2e_v8_auth_diagnostics.txt
- Secret env names present: /root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_2_8_api_live_cross_tenant_e2e_fix_v8_20260504_224346/jwt_secret_names_present.txt

## Result
Otomatik live API cross-tenant kombinasyonu bulunamadı. Same-tenant istek hâlâ 2xx üretmedi veya mismatch/no-token beklenen 401/403 olmadı.

## Next
Gateway/auth middleware token standardı koddan çıkarılıp V9 exact auth fix yapılmalı.

PASS_COUNT=13
FAIL_COUNT=0
WARN_COUNT=2
