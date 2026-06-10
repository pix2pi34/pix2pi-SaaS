# FAZ 1-5.5 — Unauthorized / Forbidden Sayfaları

## Kapsam

- 401 sayfası
- 403 sayfası
- Tenant mismatch mesajı
- Session expired mesajı
- UI/API testleri

## Üretilen Dosyalar

- Index: web/faz1/auth-tenant-experience/auth-errors/index.html
- 401 UI: web/faz1/auth-tenant-experience/auth-errors/401.html
- 403 UI: web/faz1/auth-tenant-experience/auth-errors/403.html
- Tenant mismatch UI: web/faz1/auth-tenant-experience/auth-errors/tenant-mismatch.html
- Session expired UI: web/faz1/auth-tenant-experience/auth-errors/session-expired.html
- Runtime JS: web/faz1/auth-tenant-experience/auth-errors/auth_error_pages.js
- CSS: web/faz1/auth-tenant-experience/auth-errors/auth_error_pages.css
- Contract: configs/faz1/web/auth_tenant_experience/auth_error_pages_contract.v1.json
- Strict suite: scripts/web/faz_1_5_5_unauthorized_forbidden_pages_strict_suite.sh

## Final Status

- UNAUTHORIZED_401_PAGE_STATUS=PASS
- FORBIDDEN_403_PAGE_STATUS=PASS
- TENANT_MISMATCH_MESSAGE_STATUS=PASS
- SESSION_EXPIRED_MESSAGE_STATUS=PASS
- UI_API_TEST_STATUS=PASS
- STRICT_SUITE_STATUS=PASS
- STRICT_SUITE_SEAL_STATUS=SEALED
