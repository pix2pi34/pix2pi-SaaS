# FAZ 7-R / 349 — Kullanıcı şifre / giriş akışı gerçek password/session audit

Generated at: 20260511_073715

## Result

- PASS_COUNT=75
- FAIL_COUNT=0
- WARN_COUNT=0
- REQUIRED_FAIL=0
- OPTIONAL_WARN=0
- FAZ_7R_349_REAL_IMPLEMENTATION_STATUS=PASS
- FAZ_7R_349_FINAL_STATUS=PASS
- FAZ_7R_350_READY=YES

## Live URL

- https://panel.pix2pi.com.tr/password-login/

## Artifacts

- Documentation: docs/faz7r/FAZ_7R_349_KULLANICI_SIFRE_GIRIS_AKISI_GERCEK_PASSWORD_SESSION.md
- Config: configs/faz7r/faz_7r_349_kullanici_sifre_giris_akisi.v1.json
- Migration: db/migrations/20260511_349_auth_password_flow.sql
- Runtime: internal/auth/passwordflow/password_flow.go
- Test: internal/auth/passwordflow/password_flow_test.go
- JS: web/panel/assets/password-flow/password-flow-runtime.js
- HTML: web/panel/password-login/index.html
- Audit script: scripts/faz7r/audit_faz_7r_349_kullanici_sifre_giris_akisi.sh
- Backup: backups/faz7r/faz_7r_349_kullanici_sifre_giris_akisi_gercek_password_session_20260511_073715

## Audit check log

```
349 backup directory IMPLEMENTED_OR_PRESENT / OK ✅
349 documentation directory IMPLEMENTED_OR_PRESENT / OK ✅
349 config directory IMPLEMENTED_OR_PRESENT / OK ✅
349 migration directory IMPLEMENTED_OR_PRESENT / OK ✅
349 runtime directory IMPLEMENTED_OR_PRESENT / OK ✅
349 password login web directory IMPLEMENTED_OR_PRESENT / OK ✅
349 password flow asset directory IMPLEMENTED_OR_PRESENT / OK ✅
349 script directory IMPLEMENTED_OR_PRESENT / OK ✅
349 evidence directory IMPLEMENTED_OR_PRESENT / OK ✅
349 documentation file IMPLEMENTED_OR_PRESENT / OK ✅
349 config file IMPLEMENTED_OR_PRESENT / OK ✅
349 DB migration file IMPLEMENTED_OR_PRESENT / OK ✅
349 runtime file IMPLEMENTED_OR_PRESENT / OK ✅
349 test file IMPLEMENTED_OR_PRESENT / OK ✅
349 panel JS runtime file IMPLEMENTED_OR_PRESENT / OK ✅
349 panel HTML file IMPLEMENTED_OR_PRESENT / OK ✅
349 standalone audit script file IMPLEMENTED_OR_PRESENT / OK ✅
349 live password login html file IMPLEMENTED_OR_PRESENT / OK ✅
349 live password flow runtime file IMPLEMENTED_OR_PRESENT / OK ✅
349 config json semantic validation IMPLEMENTED_OR_PRESENT / OK ✅
349 doc initial password scope IMPLEMENTED_OR_PRESENT / OK ✅
349 doc reset token scope IMPLEMENTED_OR_PRESENT / OK ✅
349 doc session validation scope IMPLEMENTED_OR_PRESENT / OK ✅
349 config initial password IMPLEMENTED_OR_PRESENT / OK ✅
349 config reset token flow IMPLEMENTED_OR_PRESENT / OK ✅
349 config session created IMPLEMENTED_OR_PRESENT / OK ✅
349 config tenant selection handoff IMPLEMENTED_OR_PRESENT / OK ✅
349 migration user password credentials IMPLEMENTED_OR_PRESENT / OK ✅
349 migration password reset tokens IMPLEMENTED_OR_PRESENT / OK ✅
349 migration password flow events IMPLEMENTED_OR_PRESENT / OK ✅
349 migration login sessions IMPLEMENTED_OR_PRESENT / OK ✅
349 runtime initial password function IMPLEMENTED_OR_PRESENT / OK ✅
349 runtime reset request function IMPLEMENTED_OR_PRESENT / OK ✅
349 runtime reset complete function IMPLEMENTED_OR_PRESENT / OK ✅
349 runtime login function IMPLEMENTED_OR_PRESENT / OK ✅
349 runtime session validation IMPLEMENTED_OR_PRESENT / OK ✅
349 runtime initial password HTTP IMPLEMENTED_OR_PRESENT / OK ✅
349 runtime login HTTP IMPLEMENTED_OR_PRESENT / OK ✅
349 runtime tenant required IMPLEMENTED_OR_PRESENT / OK ✅
349 test initial password setup IMPLEMENTED_OR_PRESENT / OK ✅
349 test password policy IMPLEMENTED_OR_PRESENT / OK ✅
349 test password reset flow IMPLEMENTED_OR_PRESENT / OK ✅
349 test login creates session IMPLEMENTED_OR_PRESENT / OK ✅
349 test login rejection and tenant required IMPLEMENTED_OR_PRESENT / OK ✅
349 test session validation IMPLEMENTED_OR_PRESENT / OK ✅
349 test HTTP handlers IMPLEMENTED_OR_PRESENT / OK ✅
349 panel JS runtime marker IMPLEMENTED_OR_PRESENT / OK ✅
349 panel JS initial password function IMPLEMENTED_OR_PRESENT / OK ✅
349 panel JS login function IMPLEMENTED_OR_PRESENT / OK ✅
349 panel JS reset request function IMPLEMENTED_OR_PRESENT / OK ✅
349 panel JS reset complete function IMPLEMENTED_OR_PRESENT / OK ✅
349 panel HTML screen marker IMPLEMENTED_OR_PRESENT / OK ✅
349 panel HTML initial password marker IMPLEMENTED_OR_PRESENT / OK ✅
349 panel HTML login marker IMPLEMENTED_OR_PRESENT / OK ✅
349 panel HTML reset marker IMPLEMENTED_OR_PRESENT / OK ✅
349 panel HTML session validation marker IMPLEMENTED_OR_PRESENT / OK ✅
349 doc has no forbidden marker IMPLEMENTED_OR_PRESENT / OK ✅
349 config has no forbidden marker IMPLEMENTED_OR_PRESENT / OK ✅
349 migration has no forbidden marker IMPLEMENTED_OR_PRESENT / OK ✅
349 runtime has no forbidden marker IMPLEMENTED_OR_PRESENT / OK ✅
349 test has no forbidden marker IMPLEMENTED_OR_PRESENT / OK ✅
349 JS has no forbidden marker IMPLEMENTED_OR_PRESENT / OK ✅
349 HTML has no forbidden marker IMPLEMENTED_OR_PRESENT / OK ✅
349 gofmt completed IMPLEMENTED_OR_PRESENT / OK ✅
349 go test passwordflow status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
349 live password login html matches repo artifact IMPLEMENTED_OR_PRESENT / OK ✅
349 live password flow runtime matches repo artifact IMPLEMENTED_OR_PRESENT / OK ✅
349 nginx config test status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
349 nginx loaded panel route exists IMPLEMENTED_OR_PRESENT / OK ✅
349 password login screen smoke returned exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
349 password login screen smoke body has marker IMPLEMENTED_OR_PRESENT / OK ✅
349 password flow runtime smoke returned exact HTTP 200 IMPLEMENTED_OR_PRESENT / OK ✅
349 password flow runtime smoke body has marker IMPLEMENTED_OR_PRESENT / OK ✅
349 standalone audit script syntax validation IMPLEMENTED_OR_PRESENT / OK ✅
349 standalone audit script execution status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
```
