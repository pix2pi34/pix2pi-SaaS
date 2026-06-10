# FAZ 6-12 Final Gate Probe Evidence

Generated At: 2026-05-01T16:13:30+03:00  
Repo: /root/pix2pi/pix2pi-SaaS  

Bu script FAZ 6 final gate icin onceki muhurlari, critical fixleri ve final readiness sinyallerini toplar.
Servis restart etmez, config degistirmez, DNS/Cloudflare/Nginx ayari degistirmez.

FAZ_6_12_FINAL_GATE_PROBE=STARTED ✅

---

## Master Step Final Status Search
docs/faz6/FAZ_6_MASTER_PLAN_SCOPE_FREEZE.md:368:FAZ_6_1_FINAL_STATUS=PASS ✅  
docs/faz6/FAZ_6_12_PRODUCTION_READINESS_FINAL_HARDENING_GATE.md:41:- FAZ_6_1_FINAL_STATUS=PASS
scripts/pix2pi_faz6_final_gate_probe.sh:64:search_status "6-1 final PASS izi" "FAZ_6_1_FINAL_STATUS=PASS" "required"
scripts/test_faz6_1_scope_freeze.sh:53:check_grep "6-1.5 Faz 6-1 muhur hedefi tanimli" "$DOC_FILE" "FAZ_6_1_FINAL_STATUS=PASS"
scripts/test_faz6_1_scope_freeze.sh:134:  echo "FAZ_6_1_FINAL_STATUS=PASS ✅"
6-1 final PASS izi OK ✅
docs/faz6/FAZ_6_2_DB_L8_HA_SCALE_OPS_READINESS.md:268:FAZ_6_2_FINAL_STATUS=PASS ✅  
docs/faz6/FAZ_6_12_PRODUCTION_READINESS_FINAL_HARDENING_GATE.md:42:- FAZ_6_2_FINAL_STATUS=PASS
docs/faz6/checkpoints/FAZ_6_2_DB_L8_VISIBLE_CHECKPOINTS.md:6:FAZ_6_2_FINAL_STATUS=PASS ✅  
docs/faz6/checkpoints/FAZ_6_2_DB_L8_VISIBLE_CHECKPOINTS.md:183:FAZ_6_2_FINAL_STATUS=PASS ✅  
scripts/test_faz6_2_db_l8_readiness.sh:86:check_grep "6-2 muhur final status tanimli" "$DOC_FILE" "FAZ_6_2_FINAL_STATUS=PASS"
scripts/test_faz6_2_db_l8_readiness.sh:111:  echo "FAZ_6_2_FINAL_STATUS=PASS ✅"
scripts/pix2pi_faz6_final_gate_probe.sh:65:search_status "6-2 final PASS izi" "FAZ_6_2_FINAL_STATUS=PASS" "required"
scripts/test_faz6_2_visible_checkpoints.sh:67:check_grep "6-2 final PASS var" "$CHECKPOINT_FILE" "FAZ_6_2_FINAL_STATUS=PASS"
scripts/test_faz6_2_visible_checkpoints.sh:81:  echo "FAZ_6_2_FINAL_STATUS=PASS ✅"
6-2 final PASS izi OK ✅
docs/faz6/FAZ_6_3_MULTI_NODE_FOUNDATION_SCALE_OUT_READINESS.md:298:FAZ_6_3_FINAL_STATUS=PASS_OR_NEEDS_IMPLEMENTATION_REVIEW  
docs/faz6/FAZ_6_12_PRODUCTION_READINESS_FINAL_HARDENING_GATE.md:43:- FAZ_6_3_FINAL_STATUS=PASS
scripts/test_faz6_3_multinode_readiness.sh:129:    echo "FAZ_6_3_FINAL_STATUS=PASS ✅"
scripts/test_faz6_3_multinode_readiness.sh:133:    echo "FAZ_6_3_FINAL_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
scripts/pix2pi_faz6_final_gate_probe.sh:66:search_status "6-3 final PASS izi" "FAZ_6_3_FINAL_STATUS=PASS" "required"
6-3 final PASS izi OK ✅
docs/faz6/FAZ_6_4_EVENT_BUS_QUEUE_BACKLOG_SRE_READINESS.md:244:FAZ_6_4_FINAL_STATUS=PASS_OR_NEEDS_IMPLEMENTATION_REVIEW  
docs/faz6/FAZ_6_12_PRODUCTION_READINESS_FINAL_HARDENING_GATE.md:44:- FAZ_6_4_FINAL_STATUS=PASS
scripts/pix2pi_faz6_final_gate_probe.sh:67:search_status "6-4 final PASS izi" "FAZ_6_4_FINAL_STATUS=PASS" "required"
scripts/test_faz6_4_event_bus_sre_readiness.sh:140:    echo "FAZ_6_4_FINAL_STATUS=PASS ✅"
scripts/test_faz6_4_event_bus_sre_readiness.sh:144:    echo "FAZ_6_4_FINAL_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
6-4 final PASS izi OK ✅
docs/faz6/FAZ_6_5_OBSERVABILITY_EARLY_WARNING_SRE_DASHBOARD.md:232:FAZ_6_5_FINAL_STATUS=PASS_OR_NEEDS_IMPLEMENTATION_REVIEW  
docs/faz6/FAZ_6_12_PRODUCTION_READINESS_FINAL_HARDENING_GATE.md:45:- FAZ_6_5_FINAL_STATUS=PASS
scripts/test_faz6_5_observability_sre_dashboard.sh:139:    echo "FAZ_6_5_FINAL_STATUS=PASS ✅"
scripts/test_faz6_5_observability_sre_dashboard.sh:143:    echo "FAZ_6_5_FINAL_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
scripts/pix2pi_faz6_final_gate_probe.sh:68:search_status "6-5 final PASS izi" "FAZ_6_5_FINAL_STATUS=PASS" "required"
6-5 final PASS izi OK ✅
docs/faz6/FAZ_6_6_BACKUP_RESTORE_DISASTER_RECOVERY.md:300:FAZ_6_6_FINAL_STATUS=PASS_OR_NEEDS_IMPLEMENTATION_REVIEW  
docs/faz6/FAZ_6_12_PRODUCTION_READINESS_FINAL_HARDENING_GATE.md:46:- FAZ_6_6_FINAL_STATUS=PASS
scripts/test_faz6_6_backup_restore_dr.sh:136:    echo "FAZ_6_6_FINAL_STATUS=PASS ✅"
scripts/test_faz6_6_backup_restore_dr.sh:140:    echo "FAZ_6_6_FINAL_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
scripts/pix2pi_faz6_final_gate_probe.sh:69:search_status "6-6 final PASS izi" "FAZ_6_6_FINAL_STATUS=PASS" "required"
6-6 final PASS izi OK ✅
docs/faz6/FAZ_6_7_SECURITY_HARDENING_PRODUCTION_GUARDRAILS.md:222:FAZ_6_7_FINAL_STATUS=PASS_OR_NEEDS_IMPLEMENTATION_REVIEW  
docs/faz6/FAZ_6_12_PRODUCTION_READINESS_FINAL_HARDENING_GATE.md:47:- FAZ_6_7_FINAL_STATUS=PASS
scripts/test_faz6_7_security_hardening.sh:137:    echo "FAZ_6_7_FINAL_STATUS=PASS ✅"
scripts/test_faz6_7_security_hardening.sh:141:    echo "FAZ_6_7_FINAL_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
scripts/pix2pi_faz6_final_gate_probe.sh:70:search_status "6-7 final PASS izi" "FAZ_6_7_FINAL_STATUS=PASS" "required"
6-7 final PASS izi OK ✅
docs/faz6/FAZ_6_8_PERFORMANCE_LOAD_STRESS_READINESS.md:227:FAZ_6_8_FINAL_STATUS=PASS_OR_NEEDS_IMPLEMENTATION_REVIEW  
docs/faz6/FAZ_6_12_PRODUCTION_READINESS_FINAL_HARDENING_GATE.md:48:- FAZ_6_8_FINAL_STATUS=PASS
scripts/pix2pi_faz6_final_gate_probe.sh:71:search_status "6-8 final PASS izi" "FAZ_6_8_FINAL_STATUS=PASS" "required"
scripts/test_faz6_8_performance_load_stress.sh:140:    echo "FAZ_6_8_FINAL_STATUS=PASS ✅"
scripts/test_faz6_8_performance_load_stress.sh:144:    echo "FAZ_6_8_FINAL_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
6-8 final PASS izi OK ✅
docs/faz6/FAZ_6_9_RELEASE_ROLLBACK_DEPLOY_SAFETY.md:225:FAZ_6_9_FINAL_STATUS=PASS_OR_NEEDS_IMPLEMENTATION_REVIEW  
docs/faz6/FAZ_6_12_PRODUCTION_READINESS_FINAL_HARDENING_GATE.md:49:- FAZ_6_9_FINAL_STATUS=PASS
scripts/test_faz6_9_release_rollback_deploy_safety.sh:162:    echo "FAZ_6_9_FINAL_STATUS=PASS ✅"
scripts/test_faz6_9_release_rollback_deploy_safety.sh:166:    echo "FAZ_6_9_FINAL_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
scripts/pix2pi_faz6_final_gate_probe.sh:72:search_status "6-9 final PASS izi" "FAZ_6_9_FINAL_STATUS=PASS" "required"
6-9 final PASS izi OK ✅
docs/faz6/FAZ_6_10_CDN_WAF_DNS_EDGE_READINESS.md:202:FAZ_6_10_FINAL_STATUS=PASS_OR_NEEDS_IMPLEMENTATION_REVIEW  
docs/faz6/FAZ_6_12_PRODUCTION_READINESS_FINAL_HARDENING_GATE.md:50:- FAZ_6_10_FINAL_STATUS=PASS
scripts/audit_faz6_12_real_implementation.sh:145:write_check "6-12.2" "Tum FAZ 6 step final status izi" 'FAZ_6_[0-9]+_FINAL_STATUS=PASS|FAZ_6_10_FINAL_STATUS=PASS|FAZ_6_11_FINAL_STATUS=PASS' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
scripts/pix2pi_faz6_final_gate_probe.sh:73:search_status "6-10 final PASS izi" "FAZ_6_10_FINAL_STATUS=PASS" "required"
scripts/test_faz6_10_cdn_waf_dns_edge.sh:157:    echo "FAZ_6_10_FINAL_STATUS=PASS ✅"
scripts/test_faz6_10_cdn_waf_dns_edge.sh:161:    echo "FAZ_6_10_FINAL_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
6-10 final PASS izi OK ✅
docs/faz6/evidence/FAZ_6_12_FINAL_GATE_PROBE_EVIDENCE.md:74:scripts/audit_faz6_12_real_implementation.sh:145:write_check "6-12.2" "Tum FAZ 6 step final status izi" 'FAZ_6_[0-9]+_FINAL_STATUS=PASS|FAZ_6_10_FINAL_STATUS=PASS|FAZ_6_11_FINAL_STATUS=PASS' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
docs/faz6/FAZ_6_11_OPS_CONSOLE_INCIDENT_RUNBOOK_READINESS.md:239:FAZ_6_11_FINAL_STATUS=PASS_OR_NEEDS_IMPLEMENTATION_REVIEW  
docs/faz6/FAZ_6_12_PRODUCTION_READINESS_FINAL_HARDENING_GATE.md:51:- FAZ_6_11_FINAL_STATUS=PASS
scripts/audit_faz6_12_real_implementation.sh:145:write_check "6-12.2" "Tum FAZ 6 step final status izi" 'FAZ_6_[0-9]+_FINAL_STATUS=PASS|FAZ_6_10_FINAL_STATUS=PASS|FAZ_6_11_FINAL_STATUS=PASS' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
scripts/pix2pi_faz6_final_gate_probe.sh:74:search_status "6-11 final PASS izi" "FAZ_6_11_FINAL_STATUS=PASS" "required"
scripts/test_faz6_11_ops_console_incident_runbook.sh:161:    echo "FAZ_6_11_FINAL_STATUS=PASS ✅"
scripts/test_faz6_11_ops_console_incident_runbook.sh:165:    echo "FAZ_6_11_FINAL_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
scripts/test_faz6_11_ops_console_incident_runbook.sh:343:    echo "FAZ_6_11_FINAL_STATUS=PASS ✅"
scripts/test_faz6_11_ops_console_incident_runbook.sh:347:    echo "FAZ_6_11_FINAL_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
6-11 final PASS izi OK ✅

## Critical Fix Closure Search
docs/faz6/evidence/FAZ_6_9_NATS_MONITORING_FIX_EVIDENCE.md:110:FAZ_6_9_NATS_MONITORING_FIX_STATUS=PASS ✅
docs/faz6/FAZ_6_12_PRODUCTION_READINESS_FINAL_HARDENING_GATE.md:87:FAZ_6_9_NATS_MONITORING_FIX_STATUS=PASS ✅
scripts/pix2pi_faz6_final_gate_probe.sh:79:search_status "NATS monitoring fix PASS izi" "FAZ_6_9_NATS_MONITORING_FIX_STATUS=PASS" "required"
NATS monitoring fix PASS izi OK ✅
docs/faz6/evidence/FAZ_6_9_REAL_IMPLEMENTATION_AUDIT.md:878:./scripts/pix2pi_postdeploy_smoke.sh:151:    echo "FAZ_6_9_POSTDEPLOY_SMOKE_WARN_STATUS=CLEAR ✅"
docs/faz6/evidence/FAZ_6_9_REAL_IMPLEMENTATION_AUDIT.md:881:./scripts/pix2pi_postdeploy_smoke.sh:164:  echo "FAZ_6_9_POSTDEPLOY_SMOKE_WARN_STATUS=CLEAR ✅"
docs/faz6/evidence/FAZ_6_12_RUNTIME_AUDIT.md:120:FAZ_6_9_POSTDEPLOY_SMOKE_WARN_STATUS=CLEAR ✅
docs/faz6/evidence/FAZ_6_9_POSTDEPLOY_SMOKE_EVIDENCE.md:60:FAZ_6_9_POSTDEPLOY_SMOKE_WARN_STATUS=CLEAR ✅
docs/faz6/evidence/FAZ_6_9_RELEASE_RUNTIME_AUDIT.md:1853:FAZ_6_9_POSTDEPLOY_SMOKE_WARN_STATUS=CLEAR ✅
docs/faz6/FAZ_6_12_PRODUCTION_READINESS_FINAL_HARDENING_GATE.md:94:FAZ_6_9_POSTDEPLOY_SMOKE_WARN_STATUS=CLEAR ✅
scripts/pix2pi_faz6_final_gate_probe.sh:80:search_status "6-9 postdeploy smoke clear izi" "FAZ_6_9_POSTDEPLOY_SMOKE_WARN_STATUS=CLEAR" "required"
scripts/pix2pi_postdeploy_smoke.sh:151:    echo "FAZ_6_9_POSTDEPLOY_SMOKE_WARN_STATUS=CLEAR ✅"
scripts/pix2pi_postdeploy_smoke.sh:164:  echo "FAZ_6_9_POSTDEPLOY_SMOKE_WARN_STATUS=CLEAR ✅"
6-9 postdeploy smoke clear izi OK ✅
docs/faz6/evidence/FAZ_6_10_EDGE_HEADER_FIX_V2_EVIDENCE.md:20:FAZ_6_10_EDGE_HEADER_FIX_V2_STATUS=PASS ✅
docs/faz6/FAZ_6_12_PRODUCTION_READINESS_FINAL_HARDENING_GATE.md:101:FAZ_6_10_EDGE_HEADER_FIX_V2_STATUS=PASS ✅  
scripts/pix2pi_faz6_final_gate_probe.sh:81:search_status "6-10 edge header fix V2 PASS izi" "FAZ_6_10_EDGE_HEADER_FIX_V2_STATUS=PASS" "required"
6-10 edge header fix V2 PASS izi OK ✅
docs/faz6/evidence/FAZ_6_10_EDGE_RUNTIME_AUDIT.md:734:FAZ_6_10_EDGE_HTTP_WARN_STATUS=CLEAR ✅
docs/faz6/evidence/FAZ_6_10_EDGE_HTTP_SMOKE_EVIDENCE.md:209:FAZ_6_10_EDGE_HTTP_WARN_STATUS=CLEAR ✅
docs/faz6/evidence/FAZ_6_12_RUNTIME_AUDIT.md:314:FAZ_6_10_EDGE_HTTP_WARN_STATUS=CLEAR ✅
docs/faz6/evidence/FAZ_6_10_EDGE_HEADER_FIX_V2_EVIDENCE.md:21:FAZ_6_10_EDGE_HTTP_WARN_STATUS=CLEAR ✅
docs/faz6/FAZ_6_12_PRODUCTION_READINESS_FINAL_HARDENING_GATE.md:102:FAZ_6_10_EDGE_HTTP_WARN_STATUS=CLEAR ✅
scripts/pix2pi_faz6_final_gate_probe.sh:82:search_status "6-10 edge HTTP warn clear izi" "FAZ_6_10_EDGE_HTTP_WARN_STATUS=CLEAR" "required"
scripts/pix2pi_edge_http_smoke.sh:119:    echo "FAZ_6_10_EDGE_HTTP_WARN_STATUS=CLEAR ✅"
scripts/pix2pi_edge_http_smoke.sh:133:  echo "FAZ_6_10_EDGE_HTTP_WARN_STATUS=CLEAR ✅"
6-10 edge HTTP warn clear izi OK ✅

## Runtime / Real Audit Closure Search
docs/faz6/evidence/FAZ_6_5_REAL_IMPLEMENTATION_AUDIT.md:1161:FAZ_6_5_REAL_IMPLEMENTATION_STATUS=PASS ✅
scripts/test_faz6_5_observability_sre_dashboard.sh:137:  if grep -Fq "FAZ_6_5_REAL_IMPLEMENTATION_STATUS=PASS ✅" "$REAL_EVIDENCE_FILE"; then
scripts/test_faz6_5_observability_sre_dashboard.sh:138:    echo "FAZ_6_5_REAL_IMPLEMENTATION_STATUS=PASS ✅"
scripts/test_faz6_5_observability_sre_dashboard.sh:141:  elif grep -Fq "FAZ_6_5_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS" "$REAL_EVIDENCE_FILE"; then
scripts/test_faz6_5_observability_sre_dashboard.sh:142:    echo "FAZ_6_5_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
scripts/pix2pi_faz6_final_gate_probe.sh:87:search_status "6-5 real implementation PASS izi" "FAZ_6_5_REAL_IMPLEMENTATION_STATUS=PASS" "required"
scripts/audit_faz6_5_real_implementation.sh:210:    echo "FAZ_6_5_REAL_IMPLEMENTATION_STATUS=PASS ✅"
scripts/audit_faz6_5_real_implementation.sh:213:    echo "FAZ_6_5_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
scripts/audit_faz6_5_real_implementation.sh:242:  echo "FAZ_6_5_REAL_IMPLEMENTATION_STATUS=PASS ✅"
scripts/audit_faz6_5_real_implementation.sh:245:  echo "FAZ_6_5_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
6-5 real implementation PASS izi OK ✅
docs/faz6/evidence/FAZ_6_6_REAL_IMPLEMENTATION_AUDIT.md:1195:./scripts/audit_faz6_6_real_implementation.sh:211:    echo "FAZ_6_6_REAL_IMPLEMENTATION_STATUS=PASS ✅"
docs/faz6/evidence/FAZ_6_6_REAL_IMPLEMENTATION_AUDIT.md:1196:./scripts/audit_faz6_6_real_implementation.sh:214:    echo "FAZ_6_6_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
docs/faz6/evidence/FAZ_6_6_REAL_IMPLEMENTATION_AUDIT.md:1203:./scripts/audit_faz6_6_real_implementation.sh:243:  echo "FAZ_6_6_REAL_IMPLEMENTATION_STATUS=PASS ✅"
docs/faz6/evidence/FAZ_6_6_REAL_IMPLEMENTATION_AUDIT.md:1204:./scripts/audit_faz6_6_real_implementation.sh:246:  echo "FAZ_6_6_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
docs/faz6/evidence/FAZ_6_6_REAL_IMPLEMENTATION_AUDIT.md:1251:FAZ_6_6_REAL_IMPLEMENTATION_STATUS=PASS ✅
scripts/test_faz6_6_backup_restore_dr.sh:134:  if grep -Fq "FAZ_6_6_REAL_IMPLEMENTATION_STATUS=PASS ✅" "$REAL_EVIDENCE_FILE"; then
scripts/test_faz6_6_backup_restore_dr.sh:135:    echo "FAZ_6_6_REAL_IMPLEMENTATION_STATUS=PASS ✅"
scripts/test_faz6_6_backup_restore_dr.sh:138:  elif grep -Fq "FAZ_6_6_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS" "$REAL_EVIDENCE_FILE"; then
scripts/test_faz6_6_backup_restore_dr.sh:139:    echo "FAZ_6_6_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
scripts/audit_faz6_6_real_implementation.sh:211:    echo "FAZ_6_6_REAL_IMPLEMENTATION_STATUS=PASS ✅"
scripts/audit_faz6_6_real_implementation.sh:214:    echo "FAZ_6_6_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
scripts/audit_faz6_6_real_implementation.sh:243:  echo "FAZ_6_6_REAL_IMPLEMENTATION_STATUS=PASS ✅"
scripts/audit_faz6_6_real_implementation.sh:246:  echo "FAZ_6_6_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
scripts/pix2pi_faz6_final_gate_probe.sh:88:search_status "6-6 real implementation PASS izi" "FAZ_6_6_REAL_IMPLEMENTATION_STATUS=PASS" "required"
6-6 real implementation PASS izi OK ✅
docs/faz6/evidence/FAZ_6_7_REAL_IMPLEMENTATION_AUDIT.md:1142:FAZ_6_7_REAL_IMPLEMENTATION_STATUS=PASS ✅
scripts/test_faz6_7_security_hardening.sh:135:  if grep -Fq "FAZ_6_7_REAL_IMPLEMENTATION_STATUS=PASS ✅" "$REAL_EVIDENCE_FILE"; then
scripts/test_faz6_7_security_hardening.sh:136:    echo "FAZ_6_7_REAL_IMPLEMENTATION_STATUS=PASS ✅"
scripts/test_faz6_7_security_hardening.sh:139:  elif grep -Fq "FAZ_6_7_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS" "$REAL_EVIDENCE_FILE"; then
scripts/test_faz6_7_security_hardening.sh:140:    echo "FAZ_6_7_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
scripts/audit_faz6_7_real_implementation.sh:212:    echo "FAZ_6_7_REAL_IMPLEMENTATION_STATUS=PASS ✅"
scripts/audit_faz6_7_real_implementation.sh:215:    echo "FAZ_6_7_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
scripts/audit_faz6_7_real_implementation.sh:244:  echo "FAZ_6_7_REAL_IMPLEMENTATION_STATUS=PASS ✅"
scripts/audit_faz6_7_real_implementation.sh:247:  echo "FAZ_6_7_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
scripts/pix2pi_faz6_final_gate_probe.sh:89:search_status "6-7 real implementation PASS izi" "FAZ_6_7_REAL_IMPLEMENTATION_STATUS=PASS" "required"
6-7 real implementation PASS izi OK ✅
docs/faz6/evidence/FAZ_6_8_REAL_IMPLEMENTATION_AUDIT.md:1063:./scripts/audit_faz6_8_real_implementation.sh:207:    echo "FAZ_6_8_REAL_IMPLEMENTATION_STATUS=PASS ✅"
docs/faz6/evidence/FAZ_6_8_REAL_IMPLEMENTATION_AUDIT.md:1064:./scripts/audit_faz6_8_real_implementation.sh:210:    echo "FAZ_6_8_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
docs/faz6/evidence/FAZ_6_8_REAL_IMPLEMENTATION_AUDIT.md:1071:./scripts/audit_faz6_8_real_implementation.sh:239:  echo "FAZ_6_8_REAL_IMPLEMENTATION_STATUS=PASS ✅"
docs/faz6/evidence/FAZ_6_8_REAL_IMPLEMENTATION_AUDIT.md:1072:./scripts/audit_faz6_8_real_implementation.sh:242:  echo "FAZ_6_8_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
docs/faz6/evidence/FAZ_6_8_REAL_IMPLEMENTATION_AUDIT.md:1123:FAZ_6_8_REAL_IMPLEMENTATION_STATUS=PASS ✅
scripts/audit_faz6_8_real_implementation.sh:207:    echo "FAZ_6_8_REAL_IMPLEMENTATION_STATUS=PASS ✅"
scripts/audit_faz6_8_real_implementation.sh:210:    echo "FAZ_6_8_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
scripts/audit_faz6_8_real_implementation.sh:239:  echo "FAZ_6_8_REAL_IMPLEMENTATION_STATUS=PASS ✅"
scripts/audit_faz6_8_real_implementation.sh:242:  echo "FAZ_6_8_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
scripts/pix2pi_faz6_final_gate_probe.sh:90:search_status "6-8 real implementation PASS izi" "FAZ_6_8_REAL_IMPLEMENTATION_STATUS=PASS" "required"
scripts/test_faz6_8_performance_load_stress.sh:138:  if grep -Fq "FAZ_6_8_REAL_IMPLEMENTATION_STATUS=PASS ✅" "$REAL_EVIDENCE_FILE"; then
scripts/test_faz6_8_performance_load_stress.sh:139:    echo "FAZ_6_8_REAL_IMPLEMENTATION_STATUS=PASS ✅"
scripts/test_faz6_8_performance_load_stress.sh:142:  elif grep -Fq "FAZ_6_8_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS" "$REAL_EVIDENCE_FILE"; then
scripts/test_faz6_8_performance_load_stress.sh:143:    echo "FAZ_6_8_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
6-8 real implementation PASS izi OK ✅
docs/faz6/evidence/FAZ_6_9_REAL_IMPLEMENTATION_AUDIT.md:853:./scripts/audit_faz6_9_real_implementation.sh:202:    echo "FAZ_6_9_REAL_IMPLEMENTATION_STATUS=PASS ✅"
docs/faz6/evidence/FAZ_6_9_REAL_IMPLEMENTATION_AUDIT.md:854:./scripts/audit_faz6_9_real_implementation.sh:205:    echo "FAZ_6_9_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
docs/faz6/evidence/FAZ_6_9_REAL_IMPLEMENTATION_AUDIT.md:861:./scripts/audit_faz6_9_real_implementation.sh:234:  echo "FAZ_6_9_REAL_IMPLEMENTATION_STATUS=PASS ✅"
docs/faz6/evidence/FAZ_6_9_REAL_IMPLEMENTATION_AUDIT.md:862:./scripts/audit_faz6_9_real_implementation.sh:237:  echo "FAZ_6_9_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
docs/faz6/evidence/FAZ_6_9_REAL_IMPLEMENTATION_AUDIT.md:917:FAZ_6_9_REAL_IMPLEMENTATION_STATUS=PASS ✅
scripts/test_faz6_9_release_rollback_deploy_safety.sh:160:  if grep -Fq "FAZ_6_9_REAL_IMPLEMENTATION_STATUS=PASS ✅" "$REAL_EVIDENCE_FILE"; then
scripts/test_faz6_9_release_rollback_deploy_safety.sh:161:    echo "FAZ_6_9_REAL_IMPLEMENTATION_STATUS=PASS ✅"
scripts/test_faz6_9_release_rollback_deploy_safety.sh:164:  elif grep -Fq "FAZ_6_9_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS" "$REAL_EVIDENCE_FILE"; then
scripts/test_faz6_9_release_rollback_deploy_safety.sh:165:    echo "FAZ_6_9_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
scripts/pix2pi_faz6_final_gate_probe.sh:91:search_status "6-9 real implementation PASS izi" "FAZ_6_9_REAL_IMPLEMENTATION_STATUS=PASS" "required"
scripts/audit_faz6_9_real_implementation.sh:202:    echo "FAZ_6_9_REAL_IMPLEMENTATION_STATUS=PASS ✅"
scripts/audit_faz6_9_real_implementation.sh:205:    echo "FAZ_6_9_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
scripts/audit_faz6_9_real_implementation.sh:234:  echo "FAZ_6_9_REAL_IMPLEMENTATION_STATUS=PASS ✅"
scripts/audit_faz6_9_real_implementation.sh:237:  echo "FAZ_6_9_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
6-9 real implementation PASS izi OK ✅
docs/faz6/evidence/FAZ_6_10_REAL_IMPLEMENTATION_AUDIT.md:965:FAZ_6_10_REAL_IMPLEMENTATION_STATUS=PASS ✅
scripts/pix2pi_faz6_final_gate_probe.sh:92:search_status "6-10 real implementation PASS izi" "FAZ_6_10_REAL_IMPLEMENTATION_STATUS=PASS" "required"
scripts/test_faz6_10_cdn_waf_dns_edge.sh:155:  if grep -Fq "FAZ_6_10_REAL_IMPLEMENTATION_STATUS=PASS ✅" "$REAL_EVIDENCE_FILE"; then
scripts/test_faz6_10_cdn_waf_dns_edge.sh:156:    echo "FAZ_6_10_REAL_IMPLEMENTATION_STATUS=PASS ✅"
scripts/test_faz6_10_cdn_waf_dns_edge.sh:159:  elif grep -Fq "FAZ_6_10_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS" "$REAL_EVIDENCE_FILE"; then
scripts/test_faz6_10_cdn_waf_dns_edge.sh:160:    echo "FAZ_6_10_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
scripts/audit_faz6_10_real_implementation.sh:193:    echo "FAZ_6_10_REAL_IMPLEMENTATION_STATUS=PASS ✅"
scripts/audit_faz6_10_real_implementation.sh:196:    echo "FAZ_6_10_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
scripts/audit_faz6_10_real_implementation.sh:225:  echo "FAZ_6_10_REAL_IMPLEMENTATION_STATUS=PASS ✅"
scripts/audit_faz6_10_real_implementation.sh:228:  echo "FAZ_6_10_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
6-10 real implementation PASS izi OK ✅
docs/faz6/evidence/FAZ_6_11_REAL_IMPLEMENTATION_AUDIT.md:915:FAZ_6_11_REAL_IMPLEMENTATION_STATUS=PASS ✅
scripts/audit_faz6_11_real_implementation.sh:194:    echo "FAZ_6_11_REAL_IMPLEMENTATION_STATUS=PASS ✅"
scripts/audit_faz6_11_real_implementation.sh:197:    echo "FAZ_6_11_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
scripts/audit_faz6_11_real_implementation.sh:226:  echo "FAZ_6_11_REAL_IMPLEMENTATION_STATUS=PASS ✅"
scripts/audit_faz6_11_real_implementation.sh:229:  echo "FAZ_6_11_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
scripts/pix2pi_faz6_final_gate_probe.sh:93:search_status "6-11 real implementation PASS izi" "FAZ_6_11_REAL_IMPLEMENTATION_STATUS=PASS" "required"
scripts/test_faz6_11_ops_console_incident_runbook.sh:159:  if grep -Fq "FAZ_6_11_REAL_IMPLEMENTATION_STATUS=PASS ✅" "$REAL_EVIDENCE_FILE"; then
scripts/test_faz6_11_ops_console_incident_runbook.sh:160:    echo "FAZ_6_11_REAL_IMPLEMENTATION_STATUS=PASS ✅"
scripts/test_faz6_11_ops_console_incident_runbook.sh:163:  elif grep -Fq "FAZ_6_11_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS" "$REAL_EVIDENCE_FILE"; then
scripts/test_faz6_11_ops_console_incident_runbook.sh:164:    echo "FAZ_6_11_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
scripts/test_faz6_11_ops_console_incident_runbook.sh:341:  if grep -Fq "FAZ_6_11_REAL_IMPLEMENTATION_STATUS=PASS ✅" "$REAL_EVIDENCE_FILE"; then
scripts/test_faz6_11_ops_console_incident_runbook.sh:342:    echo "FAZ_6_11_REAL_IMPLEMENTATION_STATUS=PASS ✅"
scripts/test_faz6_11_ops_console_incident_runbook.sh:345:  elif grep -Fq "FAZ_6_11_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS" "$REAL_EVIDENCE_FILE"; then
scripts/test_faz6_11_ops_console_incident_runbook.sh:346:    echo "FAZ_6_11_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
6-11 real implementation PASS izi OK ✅

## Cloudflare Decision
Cloudflare gray-by-decision notu OK ✅
Cloudflare green target public launch before go-live notu OK ✅

## Safe Runtime Smoke Snapshot

### Postdeploy Smoke
~~~text
===== PIX2PI POSTDEPLOY SMOKE BASLADI =====
===== identity health =====
TRY_1=http://127.0.0.1:9002/health
http_code=200 time_total=0.001464 size=33
identity health OK ✅

===== api gateway health =====
TRY_1=http://127.0.0.1:9010/health
http_code=200 time_total=0.001203 size=21
api gateway health OK ✅

===== prometheus ready =====
TRY_1=http://127.0.0.1:9090/-/ready
http_code=200 time_total=0.001699 size=28
prometheus ready OK ✅

===== grafana health =====
TRY_1=http://127.0.0.1:3001/api/health
http_code=200 time_total=0.001468 size=101
grafana health OK ✅

===== node exporter metrics =====
TRY_1=http://127.0.0.1:9100/metrics
http_code=200 time_total=0.021858 size=73763
node exporter metrics OK ✅

===== cadvisor metrics =====
TRY_1=http://127.0.0.1:8080/metrics
http_code=200 time_total=0.261263 size=7731262
cadvisor metrics OK ✅

===== nats monitoring varz =====
TRY_1=http://127.0.0.1:8222/varz
http_code=200 time_total=0.003691 size=1699
nats monitoring varz OK ✅

PASS_COUNT=7
WARN_COUNT=0
FAZ_6_9_POSTDEPLOY_SMOKE_STATUS=COMPLETE ✅
POSTDEPLOY_DESTRUCTIVE_ACTION=NO ✅
FAZ_6_9_POSTDEPLOY_SMOKE_WARN_STATUS=CLEAR ✅
OK ✅ evidence yazildi: docs/faz6/evidence/FAZ_6_9_POSTDEPLOY_SMOKE_EVIDENCE.md
~~~

### Edge HTTP Smoke
~~~text
===== PIX2PI EDGE HTTP SMOKE BASLADI =====
===== EDGE HTTP SMOKE: root https =====
URL=https://pix2pi.com.tr/
http_code=200 time_total=0.083974 size=10 remote_ip=141.98.48.42
--- headers first 100 lines ---
HTTP/2 200 
server: nginx/1.18.0 (Ubuntu)
date: Fri, 01 May 2026 13:13:31 GMT
content-type: application/octet-stream
content-length: 10
content-type: text/plain
x-content-type-options: nosniff
x-frame-options: SAMEORIGIN
referrer-policy: strict-origin-when-cross-origin
x-xss-protection: 0
permissions-policy: geolocation=(), microphone=(), camera=(), payment=(), usb=()
strict-transport-security: max-age=31536000; includeSubDomains
content-security-policy: default-src 'self'; base-uri 'self'; frame-ancestors 'self'; object-src 'none'; img-src 'self' data: https:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; connect-src 'self' https: wss:;
cache-control: public, max-age=300

--- body first 500 chars ---
Pix2pi OK

--- curl error if any ---
root https EDGE_HTTP_OK ✅
root https CLOUDFLARE_PROXY_HEADERS_NOT_EXPECTED_GRAY_CLOUD ℹ️
root https EDGE_SECURITY_HEADERS_PRESENT ✅
x-content-type-options: nosniff
x-frame-options: SAMEORIGIN
referrer-policy: strict-origin-when-cross-origin
permissions-policy: geolocation=(), microphone=(), camera=(), payment=(), usb=()
strict-transport-security: max-age=31536000; includeSubDomains
content-security-policy: default-src 'self'; base-uri 'self'; frame-ancestors 'self'; object-src 'none'; img-src 'self' data: https:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; connect-src 'self' https: wss:;
cache-control: public, max-age=300

===== EDGE HTTP SMOKE: https path / =====
URL=https://pix2pi.com.tr/
http_code=200 time_total=0.112095 size=10 remote_ip=141.98.48.42
--- headers first 100 lines ---
HTTP/2 200 
server: nginx/1.18.0 (Ubuntu)
date: Fri, 01 May 2026 13:13:31 GMT
content-type: application/octet-stream
content-length: 10
content-type: text/plain
x-content-type-options: nosniff
x-frame-options: SAMEORIGIN
referrer-policy: strict-origin-when-cross-origin
x-xss-protection: 0
permissions-policy: geolocation=(), microphone=(), camera=(), payment=(), usb=()
strict-transport-security: max-age=31536000; includeSubDomains
content-security-policy: default-src 'self'; base-uri 'self'; frame-ancestors 'self'; object-src 'none'; img-src 'self' data: https:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; connect-src 'self' https: wss:;
cache-control: public, max-age=300

--- body first 500 chars ---
Pix2pi OK

--- curl error if any ---
https path / EDGE_HTTP_OK ✅
https path / CLOUDFLARE_PROXY_HEADERS_NOT_EXPECTED_GRAY_CLOUD ℹ️
https path / EDGE_SECURITY_HEADERS_PRESENT ✅
x-content-type-options: nosniff
x-frame-options: SAMEORIGIN
referrer-policy: strict-origin-when-cross-origin
permissions-policy: geolocation=(), microphone=(), camera=(), payment=(), usb=()
strict-transport-security: max-age=31536000; includeSubDomains
content-security-policy: default-src 'self'; base-uri 'self'; frame-ancestors 'self'; object-src 'none'; img-src 'self' data: https:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; connect-src 'self' https: wss:;
cache-control: public, max-age=300

===== EDGE HTTP SMOKE: https path /faz4d/pilot-go-live/ =====
URL=https://pix2pi.com.tr/faz4d/pilot-go-live/
http_code=200 time_total=0.103225 size=8452 remote_ip=141.98.48.42
--- headers first 100 lines ---
HTTP/2 200 
server: nginx/1.18.0 (Ubuntu)
date: Fri, 01 May 2026 13:13:31 GMT
content-type: text/html
content-length: 8452
last-modified: Fri, 01 May 2026 07:31:54 GMT
etag: "69f456ea-2104"
x-content-type-options: nosniff
x-frame-options: SAMEORIGIN
referrer-policy: strict-origin-when-cross-origin
x-xss-protection: 0
permissions-policy: geolocation=(), microphone=(), camera=(), payment=(), usb=()
strict-transport-security: max-age=31536000; includeSubDomains
content-security-policy: default-src 'self'; base-uri 'self'; frame-ancestors 'self'; object-src 'none'; img-src 'self' data: https:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; connect-src 'self' https: wss:;
cache-control: public, max-age=300
accept-ranges: bytes

--- body first 500 chars ---
<!doctype html>
<html lang="tr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Pix2pi Controlled Pilot Go-Live</title>
  <style>
    :root {
      --bg: #07111f;
      --card: #101d31;
      --card-2: #152640;
      --text: #eef6ff;
      --muted: #a8b8cc;
      --line: rgba(255, 255, 255, 0.12);
      --accent: #41b8ff;
      --ok: #38d996;
      --warn: #ffcf5a;
      --danger: #ff7d7d;
    }

    * {
      box-sizing: border-bo
--- curl error if any ---
https path /faz4d/pilot-go-live/ EDGE_HTTP_OK ✅
https path /faz4d/pilot-go-live/ CLOUDFLARE_PROXY_HEADERS_NOT_EXPECTED_GRAY_CLOUD ℹ️
https path /faz4d/pilot-go-live/ EDGE_SECURITY_HEADERS_PRESENT ✅
x-content-type-options: nosniff
x-frame-options: SAMEORIGIN
referrer-policy: strict-origin-when-cross-origin
permissions-policy: geolocation=(), microphone=(), camera=(), payment=(), usb=()
strict-transport-security: max-age=31536000; includeSubDomains
content-security-policy: default-src 'self'; base-uri 'self'; frame-ancestors 'self'; object-src 'none'; img-src 'self' data: https:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; connect-src 'self' https: wss:;
cache-control: public, max-age=300

===== EDGE HTTP SMOKE: http redirect/root =====
URL=http://pix2pi.com.tr/
http_code=200 time_total=0.150080 size=10 remote_ip=141.98.48.42
--- headers first 100 lines ---
HTTP/1.1 301 Moved Permanently
Server: nginx/1.18.0 (Ubuntu)
Date: Fri, 01 May 2026 13:13:32 GMT
Content-Type: text/html
Content-Length: 178
Connection: keep-alive
Location: https://pix2pi.com.tr/
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
Referrer-Policy: strict-origin-when-cross-origin
X-XSS-Protection: 0
Permissions-Policy: geolocation=(), microphone=(), camera=(), payment=(), usb=()
Strict-Transport-Security: max-age=31536000; includeSubDomains
Content-Security-Policy: default-src 'self'; base-uri 'self'; frame-ancestors 'self'; object-src 'none'; img-src 'self' data: https:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; connect-src 'self' https: wss:;
Cache-Control: public, max-age=300

HTTP/2 200 
server: nginx/1.18.0 (Ubuntu)
date: Fri, 01 May 2026 13:13:32 GMT
content-type: application/octet-stream
content-length: 10
content-type: text/plain
x-content-type-options: nosniff
x-frame-options: SAMEORIGIN
referrer-policy: strict-origin-when-cross-origin
x-xss-protection: 0
permissions-policy: geolocation=(), microphone=(), camera=(), payment=(), usb=()
strict-transport-security: max-age=31536000; includeSubDomains
content-security-policy: default-src 'self'; base-uri 'self'; frame-ancestors 'self'; object-src 'none'; img-src 'self' data: https:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; connect-src 'self' https: wss:;
cache-control: public, max-age=300

--- body first 500 chars ---
Pix2pi OK

--- curl error if any ---
http redirect/root EDGE_HTTP_OK ✅
http redirect/root CLOUDFLARE_PROXY_HEADERS_NOT_EXPECTED_GRAY_CLOUD ℹ️
http redirect/root EDGE_SECURITY_HEADERS_PRESENT ✅
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: geolocation=(), microphone=(), camera=(), payment=(), usb=()
Strict-Transport-Security: max-age=31536000; includeSubDomains
Content-Security-Policy: default-src 'self'; base-uri 'self'; frame-ancestors 'self'; object-src 'none'; img-src 'self' data: https:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; connect-src 'self' https: wss:;
Cache-Control: public, max-age=300
x-content-type-options: nosniff
x-frame-options: SAMEORIGIN
referrer-policy: strict-origin-when-cross-origin
permissions-policy: geolocation=(), microphone=(), camera=(), payment=(), usb=()
strict-transport-security: max-age=31536000; includeSubDomains
content-security-policy: default-src 'self'; base-uri 'self'; frame-ancestors 'self'; object-src 'none'; img-src 'self' data: https:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; connect-src 'self' https: wss:;
cache-control: public, max-age=300

PASS_COUNT=8
WARN_COUNT=0
INFO_COUNT=4
FAZ_6_10_EDGE_HTTP_SMOKE_STATUS=COMPLETE ✅
FAZ_6_10_CLOUDFLARE_PROXY_STATUS=DISABLED_OR_NOT_DETECTED_INFO ✅
FAZ_6_10_EDGE_HTTP_WARN_STATUS=CLEAR ✅
OK ✅ evidence yazildi: docs/faz6/evidence/FAZ_6_10_EDGE_HTTP_SMOKE_EVIDENCE.md
~~~

### Ops Console Probe
~~~text
===== PIX2PI OPS CONSOLE PROBE BASLADI =====
===== OPS PROBE: identity-api health =====
URL=http://127.0.0.1:9002/health
http_code=200 time_total=0.001894 size=33
identity-api health STATUS=OK ✅

===== OPS PROBE: api-gateway health =====
URL=http://127.0.0.1:9010/health
http_code=200 time_total=0.000926 size=21
api-gateway health STATUS=OK ✅

===== OPS PROBE: prometheus ready =====
URL=http://127.0.0.1:9090/-/ready
http_code=200 time_total=0.002112 size=28
prometheus ready STATUS=OK ✅

===== OPS PROBE: grafana health =====
URL=http://127.0.0.1:3001/api/health
http_code=200 time_total=0.001653 size=101
grafana health STATUS=OK ✅

===== OPS PROBE: node_exporter metrics =====
URL=http://127.0.0.1:9100/metrics
http_code=200 time_total=0.021695 size=73790
node_exporter metrics STATUS=OK ✅

===== OPS PROBE: cadvisor metrics =====
URL=http://127.0.0.1:8080/metrics
http_code=200 time_total=0.286096 size=7731264
cadvisor metrics STATUS=OK ✅

===== OPS PROBE: nats varz =====
URL=http://127.0.0.1:8222/varz
http_code=200 time_total=0.003251 size=1699
nats varz STATUS=OK ✅

===== OPS PROBE: public root =====
URL=https://pix2pi.com.tr/
http_code=200 time_total=0.110779 size=10
public root STATUS=OK ✅

===== OPS PROBE: public pilot page =====
URL=https://pix2pi.com.tr/faz4d/pilot-go-live/
http_code=200 time_total=0.091741 size=8452
public pilot page STATUS=OK ✅

PASS_COUNT=9
WARN_COUNT=0
FAZ_6_11_OPS_CONSOLE_PROBE_STATUS=COMPLETE ✅
FAZ_6_11_OPS_CONSOLE_WARN_STATUS=CLEAR ✅
OK ✅ evidence yazildi: docs/faz6/evidence/FAZ_6_11_OPS_CONSOLE_PROBE_EVIDENCE.md
~~~

## Final Gate Probe Seal
~~~text
PASS_COUNT=24
WARN_COUNT=0
FAIL_COUNT=0
FAZ_6_12_FINAL_GATE_PROBE_STATUS=COMPLETE ✅
FAZ_6_12_FINAL_GATE_REQUIRED_STATUS=PASS ✅
~~~
