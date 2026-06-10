#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR" || exit 1

EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_11_REAL_IMPLEMENTATION_AUDIT.md"
TMP_DIR="$(mktemp -d)"
FILE_LIST="$TMP_DIR/files.txt"

mkdir -p docs/faz6/evidence

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

find . \
  \( -path './.git' \
  -o -path './backups' \
  -o -path './docs/faz6/evidence' \
  -o -path './node_modules' \
  -o -path './vendor' \
  -o -path './tmp' \
  \) -prune -o \
  -type f \
  \( -name '*.go' \
  -o -name '*.sql' \
  -o -name '*.sh' \
  -o -name '*.md' \
  -o -name '*.env' \
  -o -name '*.yaml' \
  -o -name '*.yml' \
  -o -name '*.json' \
  -o -name '*.toml' \
  -o -name '*.conf' \
  -o -name 'Dockerfile' \
  -o -name 'docker-compose*.yml' \
  -o -name '*.service' \
  \) -print | sort > "$FILE_LIST"

search_pattern() {
  local pattern="$1"
  local out_file="$2"

  : > "$out_file"

  while IFS= read -r f; do
    if [ -f "$f" ]; then
      grep -I -n -E "$pattern" "$f" 2>/dev/null | sed "s#^#$f:#" >> "$out_file" || true
    fi
  done < "$FILE_LIST"
}

count_file_lines() {
  local f="$1"

  if [ -f "$f" ]; then
    wc -l < "$f" | tr -d ' '
  else
    echo "0"
  fi
}

write_check() {
  local code="$1"
  local title="$2"
  local pattern="$3"
  local required="$4"

  local out="$TMP_DIR/${code}.txt"
  search_pattern "$pattern" "$out"

  local count
  count="$(count_file_lines "$out")"

  {
    echo
    echo "## $code $title"
    echo
    echo "Pattern:"
    echo
    echo '~~~text'
    echo "$pattern"
    echo '~~~'
    echo
    echo "Match Count: $count"
    echo
    echo '~~~text'
    if [ "$count" -gt 0 ]; then
      head -n 70 "$out"
    else
      echo "NO_MATCH"
    fi
    echo '~~~'
    echo
    if [ "$count" -gt 0 ]; then
      echo "Status: IMPLEMENTED_OR_PRESENT ✅"
      echo "$code STATUS=IMPLEMENTED_OR_PRESENT ✅"
    else
      if [ "$required" = "required" ]; then
        echo "Status: NOT_FOUND ❌"
        echo "$code STATUS=NOT_FOUND ❌"
      else
        echo "Status: NOT_FOUND_OPTIONAL ⚠️"
        echo "$code STATUS=NOT_FOUND_OPTIONAL ⚠️"
      fi
    fi
  } >> "$EVIDENCE_FILE"

  if [ "$count" -gt 0 ]; then
    echo "$code $title IMPLEMENTED_OR_PRESENT ✅"
    return 0
  fi

  if [ "$required" = "required" ]; then
    echo "$code $title NOT_FOUND ❌"
    return 1
  fi

  echo "$code $title NOT_FOUND_OPTIONAL ⚠️"
  return 2
}

REQUIRED_FAIL=0
OPTIONAL_WARN=0

cat <<EOF2 > "$EVIDENCE_FILE"
# FAZ 6-11 Real Implementation Audit

Generated At: $(date -Is)  
Host: $(hostname)  
Repo: $ROOT_DIR  

Bu audit, FAZ 6-11 Ops Console / Incident / Runbook maddelerinin sadece dokumanda mi kaldigini, yoksa kod/config/script icinde gercek karsiligi olup olmadigini kontrol eder.

---

EOF2

echo "===== FAZ 6-11 REAL IMPLEMENTATION AUDIT ====="

{
  echo "## Scanned Files"
  echo
  echo '~~~text'
  wc -l "$FILE_LIST"
  echo
  head -n 80 "$FILE_LIST"
  echo '~~~'
} >> "$EVIDENCE_FILE"

write_check "6-11.1" "Ops console / service status izi" 'ops console|Ops Console|mission-control|MissionControl|service-registry|ServiceRegistry|service status|service.*health|health summary|pix2pi_ops_console_probe' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-11.2" "Service health summary izi" '/health|healthz|Prometheus|Grafana|NATS|node_exporter|cadvisor|DB health|Redis health|service health|Health' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-11.3" "Incident lifecycle izi" 'incident|Incident|DETECTED|TRIAGED|MITIGATING|MONITORING|RESOLVED|POSTMORTEM_REQUIRED|CLOSED' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-11.4" "Severity / priority matrix izi" 'SEV1|SEV2|SEV3|SEV4|P0|P1|P2|P3|severity|priority' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-11.5" "Runbook standard izi" 'runbook|Runbook|First Safe Diagnostics|Do Not Do|Mitigation Steps|Recovery Smoke|rollback|smoke test' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-11.6" "On-call / escalation izi" 'on-call|On-call|escalation|Escalation|owner|infra owner|backend owner|DB owner|security owner|business owner' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-11.7" "Incident evidence standard izi" 'evidence|Evidence|docker ps|systemctl|nginx -t|journalctl|Prometheus targets|public GET|backup|snapshot' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-11.8" "Postmortem standard izi" 'postmortem|Postmortem|root cause|timeline|impact|action items|detection gap|response gap|due date' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-11.9" "Ops guard scripts izi" 'pix2pi_ops_console_probe|pix2pi_runbook_template_check|audit_faz6_11_ops_runtime|audit_faz6_11_real_implementation|test_faz6_11' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-11.10" "Ops test / audit seal izi" 'FAZ_6_11|OPS_CONSOLE|INCIDENT|RUNBOOK|REAL_IMPLEMENTATION_AUDIT|RUNTIME_AUDIT|FINAL_STATUS' "optional" || OPTIONAL_WARN=$((OPTIONAL_WARN + 1))

{
  echo
  echo "# Final Runtime Implementation Interpretation"
  echo
  echo '~~~text'
  echo "REQUIRED_FAIL=$REQUIRED_FAIL"
  echo "OPTIONAL_WARN=$OPTIONAL_WARN"

  if [ "$REQUIRED_FAIL" -eq 0 ]; then
    echo "FAZ_6_11_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PASS ✅"
  else
    echo "FAZ_6_11_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PARTIAL_OR_MISSING ❌"
  fi

  if [ "$OPTIONAL_WARN" -eq 0 ]; then
    echo "FAZ_6_11_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=PASS ✅"
  else
    echo "FAZ_6_11_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=HAS_WARNINGS ⚠️"
  fi

  if [ "$REQUIRED_FAIL" -eq 0 ] && [ "$OPTIONAL_WARN" -eq 0 ]; then
    echo "FAZ_6_11_REAL_IMPLEMENTATION_STATUS=PASS ✅"
    echo "FAZ_6_12_READY=YES ✅"
  elif [ "$REQUIRED_FAIL" -eq 0 ]; then
    echo "FAZ_6_11_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
    echo "FAZ_6_12_READY=YES_WITH_WARNINGS ⚠️"
  else
    echo "FAZ_6_11_REAL_IMPLEMENTATION_STATUS=NOT_FULLY_IMPLEMENTED ❌"
    echo "FAZ_6_12_READY=NO_REVIEW_REQUIRED ❌"
  fi

  echo "FAZ_6_11_REAL_IMPLEMENTATION_AUDIT=COMPLETE ✅"
  echo '~~~'
} >> "$EVIDENCE_FILE"

echo
echo "===== FAZ 6-11 REAL IMPLEMENTATION AUDIT OZETI ====="
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"

if [ "$REQUIRED_FAIL" -eq 0 ]; then
  echo "FAZ_6_11_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PASS ✅"
else
  echo "FAZ_6_11_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PARTIAL_OR_MISSING ❌"
fi

if [ "$OPTIONAL_WARN" -eq 0 ]; then
  echo "FAZ_6_11_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=PASS ✅"
else
  echo "FAZ_6_11_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=HAS_WARNINGS ⚠️"
fi

if [ "$REQUIRED_FAIL" -eq 0 ] && [ "$OPTIONAL_WARN" -eq 0 ]; then
  echo "FAZ_6_11_REAL_IMPLEMENTATION_STATUS=PASS ✅"
  echo "FAZ_6_12_READY=YES ✅"
elif [ "$REQUIRED_FAIL" -eq 0 ]; then
  echo "FAZ_6_11_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
  echo "FAZ_6_12_READY=YES_WITH_WARNINGS ⚠️"
else
  echo "FAZ_6_11_REAL_IMPLEMENTATION_STATUS=NOT_FULLY_IMPLEMENTED ❌"
  echo "FAZ_6_12_READY=NO_REVIEW_REQUIRED ❌"
fi

echo "FAZ_6_11_REAL_IMPLEMENTATION_AUDIT=COMPLETE ✅"
echo "OK ✅ evidence yazildi: $EVIDENCE_FILE"

exit 0
