# FAZ 7-R / 361.3 — Audit sayaçları PASS kuralı düzeltmesi audit

Generated at: 20260511_071338

## Result

- PASS_COUNT=33
- FAIL_COUNT=0
- WARN_COUNT=0
- REQUIRED_FAIL=0
- OPTIONAL_WARN=0
- FAZ_7R_361_3_REAL_IMPLEMENTATION_STATUS=PASS
- FAZ_7R_361_3_FINAL_STATUS=PASS
- FAZ_7R_317_3_READY=YES

## Reclassification summary

- SCANNED_EVIDENCE_FILE_COUNT=58
- SCANNED_CONFIG_FILE_COUNT=51
- OLD_PASS_FILE_COUNT=58
- PARTIAL_MARKER_FILE_COUNT=47
- INVALID_PARTIAL_PASS_COUNT=47
- PARTIAL_MARKER_NO_PASS_COUNT=0
- OLD_PASS_NO_FORBIDDEN_MARKER_COUNT=11
- FAZ_7R_PARTIAL_PASS_RECLASSIFICATION_REQUIRED=YES
- FAZ_7R_FINAL_CLOSURE_ALLOWED=NO

## Artifacts

- Documentation: docs/faz7r/FAZ_7R_361_3_AUDIT_SAYACLARI_PASS_KURALI_DUZELTMESI.md
- Config: configs/faz7r/faz_7r_361_3_audit_sayaclari_pass_kurali.v1.json
- Guard: scripts/faz7r/faz7r_real_pass_guard.sh
- Audit script: scripts/faz7r/audit_faz_7r_361_3_audit_sayaclari_pass_kurali.sh
- Report: docs/faz7r/evidence/FAZ_7R_361_3_PARTIAL_PASS_RECLASSIFICATION.tsv
- Summary: docs/faz7r/evidence/FAZ_7R_361_3_PASS_RULE_SUMMARY.env
- Backup: backups/faz7r/faz_7r_361_3_audit_sayaclari_pass_kurali_duzeltmesi_20260511_071338

## Web URL

Bu iş web sayfası üretmez. URL yok.

## Audit check log

```
361.3 backup directory IMPLEMENTED_OR_PRESENT / OK ✅
361.3 documentation directory IMPLEMENTED_OR_PRESENT / OK ✅
361.3 config directory IMPLEMENTED_OR_PRESENT / OK ✅
361.3 script directory IMPLEMENTED_OR_PRESENT / OK ✅
361.3 evidence directory IMPLEMENTED_OR_PRESENT / OK ✅
361.3 documentation file IMPLEMENTED_OR_PRESENT / OK ✅
361.3 config file IMPLEMENTED_OR_PRESENT / OK ✅
361.3 real pass guard file IMPLEMENTED_OR_PRESENT / OK ✅
361.3 standalone audit script file IMPLEMENTED_OR_PRESENT / OK ✅
361.3 config json semantic validation IMPLEMENTED_OR_PRESENT / OK ✅
361.3 doc has strict no partial PASS rule IMPLEMENTED_OR_PRESENT / OK ✅
361.3 doc has invalid partial pass classification IMPLEMENTED_OR_PRESENT / OK ✅
361.3 doc blocks final closure IMPLEMENTED_OR_PRESENT / OK ✅
361.3 config partial pass disabled IMPLEMENTED_OR_PRESENT / OK ✅
361.3 config disabled gate cannot final pass IMPLEMENTED_OR_PRESENT / OK ✅
361.3 config invalid partial count must be zero IMPLEMENTED_OR_PRESENT / OK ✅
361.3 guard has forbidden marker pattern IMPLEMENTED_OR_PRESENT / OK ✅
361.3 guard has PASS claim pattern IMPLEMENTED_OR_PRESENT / OK ✅
361.3 guard has evidence scanner IMPLEMENTED_OR_PRESENT / OK ✅
361.3 guard emits invalid partial pass IMPLEMENTED_OR_PRESENT / OK ✅
361.3 audit scans evidence files IMPLEMENTED_OR_PRESENT / OK ✅
361.3 audit counts invalid partial pass IMPLEMENTED_OR_PRESENT / OK ✅
361.3 audit emits final closure gate IMPLEMENTED_OR_PRESENT / OK ✅
361.3 audit emits next real step readiness IMPLEMENTED_OR_PRESENT / OK ✅
361.3 guard syntax validation IMPLEMENTED_OR_PRESENT / OK ✅
361.3 standalone audit script syntax validation IMPLEMENTED_OR_PRESENT / OK ✅
361.3 standalone audit script execution status is PASS IMPLEMENTED_OR_PRESENT / OK ✅
361.3 reclassification report file IMPLEMENTED_OR_PRESENT / OK ✅
361.3 summary env file IMPLEMENTED_OR_PRESENT / OK ✅
361.3 scanned existing evidence files IMPLEMENTED_OR_PRESENT / OK ✅
361.3 found old PASS evidence files IMPLEMENTED_OR_PRESENT / OK ✅
361.3 invalid partial PASS files detected and final closure blocked IMPLEMENTED_OR_PRESENT / OK ✅
361.3 FAZ 7-R final closure correctly blocked IMPLEMENTED_OR_PRESENT / OK ✅
```
