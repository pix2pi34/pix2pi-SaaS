# FAZ 1-5.5 Unauthorized / Forbidden Pages Real Implementation Audit

- Tarih: 2026-05-06T16:59:18+03:00
- Repo: /root/pix2pi/pix2pi-SaaS
- INDEX_FILE=/root/pix2pi/pix2pi-SaaS/web/faz1/auth-tenant-experience/auth-errors/index.html
- PAGE_401_FILE=/root/pix2pi/pix2pi-SaaS/web/faz1/auth-tenant-experience/auth-errors/401.html
- PAGE_403_FILE=/root/pix2pi/pix2pi-SaaS/web/faz1/auth-tenant-experience/auth-errors/403.html
- PAGE_TENANT_MISMATCH_FILE=/root/pix2pi/pix2pi-SaaS/web/faz1/auth-tenant-experience/auth-errors/tenant-mismatch.html
- PAGE_SESSION_EXPIRED_FILE=/root/pix2pi/pix2pi-SaaS/web/faz1/auth-tenant-experience/auth-errors/session-expired.html
- JS_FILE=/root/pix2pi/pix2pi-SaaS/web/faz1/auth-tenant-experience/auth-errors/auth_error_pages.js
- CSS_FILE=/root/pix2pi/pix2pi-SaaS/web/faz1/auth-tenant-experience/auth-errors/auth_error_pages.css
- CONFIG_FILE=/root/pix2pi/pix2pi-SaaS/configs/faz1/web/auth_tenant_experience/auth_error_pages_contract.v1.json
- STRICT_SUITE_FILE=/root/pix2pi/pix2pi-SaaS/scripts/web/faz_1_5_5_unauthorized_forbidden_pages_strict_suite.sh
- DOC_FILE=/root/pix2pi/pix2pi-SaaS/docs/faz1/web/FAZ_1_5_5_UNAUTHORIZED_FORBIDDEN_PAGES.md
- BACKUP_DIR=/root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_5_5_unauthorized_forbidden_pages_20260506_165918

## Status
- UNAUTHORIZED_401_PAGE_STATUS=PASS
- FORBIDDEN_403_PAGE_STATUS=PASS
- TENANT_MISMATCH_MESSAGE_STATUS=PASS
- SESSION_EXPIRED_MESSAGE_STATUS=PASS
- UI_API_TEST_STATUS=PASS
- STRICT_SUITE_STATUS=PASS
- STRICT_SUITE_SEAL_STATUS=SEALED

## Counters
- APPLY_PASS_COUNT=10
- APPLY_FAIL_COUNT=0
- APPLY_WARN_COUNT=11
- STRICT_SUITE_PASS_COUNT=36
- STRICT_SUITE_FAIL_COUNT=0
- STRICT_SUITE_WARN_COUNT=0
