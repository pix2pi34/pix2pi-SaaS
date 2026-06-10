# FAZ 1-5.7 — Auth / Tenant UI Testleri

## Kapsam

- Login test
- Logout test
- Tenant switch test
- Forbidden test
- Role menu test

## Bağlı Modüller

- FAZ 1-5.1 Login / session akışı
- FAZ 1-5.2 Logout / session expiry akışı
- FAZ 1-5.3 Tenant switcher UX
- FAZ 1-5.4 Role-aware menu yapısı
- FAZ 1-5.5 Unauthorized / forbidden sayfaları
- FAZ 1-5.6 Auth + tenant state persistence

## Üretilen Dosyalar

- UI: web/faz1/auth-tenant-experience/ui-tests/index.html
- Runtime JS: web/faz1/auth-tenant-experience/ui-tests/auth_tenant_ui_tests.js
- CSS: web/faz1/auth-tenant-experience/ui-tests/auth_tenant_ui_tests.css
- Contract: configs/faz1/web/auth_tenant_experience/auth_tenant_ui_tests_contract.v1.json
- Strict suite: scripts/web/faz_1_5_7_auth_tenant_ui_tests_strict_suite.sh

## Final Status

- LOGIN_TEST_STATUS=PASS
- LOGOUT_TEST_STATUS=PASS
- TENANT_SWITCH_TEST_STATUS=PASS
- FORBIDDEN_TEST_STATUS=PASS
- ROLE_MENU_TEST_STATUS=PASS
- STRICT_SUITE_STATUS=PASS
- STRICT_SUITE_SEAL_STATUS=SEALED
