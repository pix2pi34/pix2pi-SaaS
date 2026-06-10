# FAZ 1-2.6 Super-admin / Break-glass Suite Result FIX V4

- Tarih: 2026-05-04T23:05:02+03:00
- Repo: /root/pix2pi/pix2pi-SaaS
- Backup dir: /root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_2_6_super_admin_break_glass_suite_fix_v4_20260504_230502

## Model Counters

- CANONICAL_TABLE_COUNT=4
- CANONICAL_RLS_ENABLED_COUNT=4
- CANONICAL_RLS_FORCED_COUNT=4
- CANONICAL_ALLOW_POLICY_COUNT=4
- CANONICAL_ENFORCE_POLICY_COUNT=4
- BREAK_GLASS_FUNCTION_COUNT=5
- SUPER_ADMIN_SEED_COUNT=1

## Test Coverage

- Super-admin role model: tested
- Break-glass reason required: tested
- Time-bound access: tested
- Expired session rejection: tested without violating schema constraint
- Closed session rejection: tested
- Admin action audit: tested
- Security alert production: tested
- Tenant-safe RLS boundary: tested
- Transaction rollback cleanup: tested

## Final Counters

- PASS_COUNT=14
- FAIL_COUNT=0
- WARN_COUNT=0
