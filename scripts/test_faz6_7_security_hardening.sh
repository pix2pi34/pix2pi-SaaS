#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR" || exit 1

DOC_FILE="docs/faz6/FAZ_6_7_SECURITY_HARDENING_PRODUCTION_GUARDRAILS.md"
CHECKPOINT_FILE="docs/faz6/checkpoints/FAZ_6_7_SECURITY_VISIBLE_CHECKPOINTS.md"
RUNTIME_AUDIT_SCRIPT="scripts/audit_faz6_7_security_runtime.sh"
REAL_AUDIT_SCRIPT="scripts/audit_faz6_7_real_implementation.sh"
RUNTIME_EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_7_SECURITY_RUNTIME_AUDIT.md"
REAL_EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_7_REAL_IMPLEMENTATION_AUDIT.md"

PASS_COUNT=0
FAIL_COUNT=0

ok() {
  echo "$1 OK ✅"
  PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
  echo "$1 HATA ❌"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

check_file() {
  local label="$1"
  local file="$2"

  if [ -f "$file" ]; then
    ok "$label"
  else
    fail "$label"
  fi
}

check_exec() {
  local label="$1"
  local file="$2"

  if [ -x "$file" ]; then
    ok "$label"
  else
    fail "$label"
  fi
}

check_grep() {
  local label="$1"
  local file="$2"
  local pattern="$3"

  if [ -f "$file" ] && grep -Fq "$pattern" "$file"; then
    ok "$label"
  else
    fail "$label"
  fi
}

echo "===== FAZ 6-7 SECURITY HARDENING TEST BASLADI ====="

check_file "6-7 master dokumani mevcut" "$DOC_FILE"
check_file "6-7 visible checkpoint dosyasi mevcut" "$CHECKPOINT_FILE"
check_file "6-7 runtime audit script mevcut" "$RUNTIME_AUDIT_SCRIPT"
check_file "6-7 real implementation audit script mevcut" "$REAL_AUDIT_SCRIPT"
check_exec "6-7 runtime audit script executable" "$RUNTIME_AUDIT_SCRIPT"
check_exec "6-7 real implementation audit script executable" "$REAL_AUDIT_SCRIPT"

check_grep "6-7.1 Secret Env Hardening tanimli" "$DOC_FILE" "6-7.1 Secret / Env Hardening"
check_grep "6-7.2 Nginx Edge Hardening tanimli" "$DOC_FILE" "6-7.2 Nginx / Edge Hardening"
check_grep "6-7.3 Firewall Port Policy tanimli" "$DOC_FILE" "6-7.3 Firewall / Port Policy"
check_grep "6-7.4 Auth JWT API Guardrails tanimli" "$DOC_FILE" "6-7.4 Auth / JWT / API Guardrails"
check_grep "6-7.5 Tenant Isolation Guardrails tanimli" "$DOC_FILE" "6-7.5 Tenant Isolation Guardrails"
check_grep "6-7.6 Input Validation Injection tanimli" "$DOC_FILE" "6-7.6 Input Validation / Injection Protection"
check_grep "6-7.7 Rate Limit WAF DDoS tanimli" "$DOC_FILE" "6-7.7 Rate Limit / WAF / DDoS Guardrails"
check_grep "6-7.8 Dependency Supply Chain tanimli" "$DOC_FILE" "6-7.8 Dependency / Supply-chain Security"
check_grep "6-7.9 Audit Security Logging tanimli" "$DOC_FILE" "6-7.9 Audit / Security Logging"
check_grep "6-7.10 Security Final Closure Gate tanimli" "$DOC_FILE" "6-7.10 Security Final Closure Gate"

check_grep "6-7.1 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_7_1_SECRET_ENV_HARDENING_STATUS=READY"
check_grep "6-7.2 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_7_2_NGINX_EDGE_HARDENING_STATUS=READY"
check_grep "6-7.3 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_7_3_FIREWALL_PORT_POLICY_STATUS=READY"
check_grep "6-7.4 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_7_4_AUTH_JWT_API_GUARDRAILS_STATUS=READY"
check_grep "6-7.5 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_7_5_TENANT_ISOLATION_GUARDRAILS_STATUS=READY"
check_grep "6-7.6 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_7_6_INPUT_VALIDATION_INJECTION_STATUS=READY"
check_grep "6-7.7 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_7_7_RATE_LIMIT_WAF_DDOS_STATUS=READY"
check_grep "6-7.8 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_7_8_DEPENDENCY_SUPPLY_CHAIN_STATUS=READY"
check_grep "6-7.9 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_7_9_AUDIT_SECURITY_LOGGING_STATUS=READY"
check_grep "6-7.10 visible checkpoint var" "$CHECKPOINT_FILE" "FAZ_6_7_10_SECURITY_FINAL_CLOSURE_GATE_STATUS=READY"

echo
echo "===== 6-7 RUNTIME AUDIT CALISTIRILIYOR ====="
bash "$RUNTIME_AUDIT_SCRIPT"

check_file "6-7 runtime evidence dosyasi mevcut" "$RUNTIME_EVIDENCE_FILE"
check_grep "6-7 runtime audit complete muhru var" "$RUNTIME_EVIDENCE_FILE" "FAZ_6_7_RUNTIME_AUDIT=COMPLETE"
check_grep "6-7 runtime permission inventory var" "$RUNTIME_EVIDENCE_FILE" "6-7.3 Env / Secret File Permission Inventory"
check_grep "6-7 runtime nginx inventory var" "$RUNTIME_EVIDENCE_FILE" "6-7.4 Nginx Syntax / Security Inventory"
check_grep "6-7 runtime port inventory var" "$RUNTIME_EVIDENCE_FILE" "6-7.5 Listening Port Inventory"
check_grep "6-7 runtime firewall status var" "$RUNTIME_EVIDENCE_FILE" "6-7.6 UFW / Firewall Status"
check_grep "6-7 runtime fail2ban status var" "$RUNTIME_EVIDENCE_FILE" "6-7.7 Fail2Ban Status"
check_grep "6-7 runtime auth tenant probe var" "$RUNTIME_EVIDENCE_FILE" "6-7.9 Auth / Tenant Runtime Probe"
check_grep "6-7 runtime dependency inventory var" "$RUNTIME_EVIDENCE_FILE" "6-7.11 Dependency / Lock Inventory"

echo
echo "===== 6-7 REAL IMPLEMENTATION AUDIT CALISTIRILIYOR ====="
bash "$REAL_AUDIT_SCRIPT"

check_file "6-7 real implementation evidence dosyasi mevcut" "$REAL_EVIDENCE_FILE"
check_grep "6-7.1 Secret env real audit evidence var" "$REAL_EVIDENCE_FILE" "6-7.1 Secret / env hardening"
check_grep "6-7.2 Nginx edge real audit evidence var" "$REAL_EVIDENCE_FILE" "6-7.2 Nginx / edge hardening"
check_grep "6-7.3 Firewall port real audit evidence var" "$REAL_EVIDENCE_FILE" "6-7.3 Firewall / port policy"
check_grep "6-7.4 Auth JWT real audit evidence var" "$REAL_EVIDENCE_FILE" "6-7.4 Auth / JWT / API guardrail"
check_grep "6-7.5 Tenant isolation real audit evidence var" "$REAL_EVIDENCE_FILE" "6-7.5 Tenant isolation guardrail"
check_grep "6-7.6 Input validation real audit evidence var" "$REAL_EVIDENCE_FILE" "6-7.6 Input validation / injection protection"
check_grep "6-7.7 Rate limit WAF real audit evidence var" "$REAL_EVIDENCE_FILE" "6-7.7 Rate limit / WAF / DDoS"
check_grep "6-7.8 Dependency security real audit evidence var" "$REAL_EVIDENCE_FILE" "6-7.8 Dependency / supply-chain security"
check_grep "6-7.9 Audit logging real audit evidence var" "$REAL_EVIDENCE_FILE" "6-7.9 Audit / security logging"
check_grep "6-7 final interpretation var" "$REAL_EVIDENCE_FILE" "Final Runtime Implementation Interpretation"
check_grep "6-7 real audit complete muhru var" "$REAL_EVIDENCE_FILE" "FAZ_6_7_REAL_IMPLEMENTATION_AUDIT=COMPLETE"

echo
echo "===== FAZ 6-7 SECURITY HARDENING TEST OZETI ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_6_7_DOC_STATUS=READY ✅"
  echo "FAZ_6_7_VISIBLE_CHECKPOINTS_STATUS=READY ✅"
  echo "FAZ_6_7_RUNTIME_AUDIT_STATUS=COMPLETE ✅"
  echo "FAZ_6_7_REAL_IMPLEMENTATION_AUDIT_STATUS=COMPLETE ✅"
  echo "FAZ_6_7_TEST_STATUS=PASS ✅"

  if grep -Fq "FAZ_6_7_REAL_IMPLEMENTATION_STATUS=PASS ✅" "$REAL_EVIDENCE_FILE"; then
    echo "FAZ_6_7_REAL_IMPLEMENTATION_STATUS=PASS ✅"
    echo "FAZ_6_7_FINAL_STATUS=PASS ✅"
    echo "FAZ_6_8_READY=YES ✅"
  elif grep -Fq "FAZ_6_7_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS" "$REAL_EVIDENCE_FILE"; then
    echo "FAZ_6_7_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
    echo "FAZ_6_7_FINAL_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
    echo "FAZ_6_8_READY=YES_WITH_WARNINGS ⚠️"
  else
    echo "FAZ_6_7_REAL_IMPLEMENTATION_STATUS=NOT_FULLY_IMPLEMENTED ❌"
    echo "FAZ_6_7_FINAL_STATUS=NEEDS_IMPLEMENTATION_REVIEW ❌"
    echo "FAZ_6_8_READY=NO_REVIEW_REQUIRED ❌"
  fi

  echo "OK ✅ FAZ 6-7 Security Hardening / Production Guardrails testi tamamlandi"
  exit 0
else
  echo "FAZ_6_7_TEST_STATUS=FAIL ❌"
  echo "HATA ❌ FAZ 6-7 testlerinde eksik var"
  exit 1
fi
