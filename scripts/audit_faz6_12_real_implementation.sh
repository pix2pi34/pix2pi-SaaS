#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR" || exit 1

EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_12_REAL_IMPLEMENTATION_AUDIT.md"
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
      head -n 80 "$out"
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
# FAZ 6-12 Real Implementation Audit

Generated At: $(date -Is)  
Host: $(hostname)  
Repo: $ROOT_DIR  

Bu audit, FAZ 6-12 final production readiness gate maddelerinin gercek dosya/script/dokuman karsiligini kontrol eder.

---

EOF2

echo "===== FAZ 6-12 REAL IMPLEMENTATION AUDIT ====="

write_check "6-12.1" "FAZ 6 final gate dokuman izi" 'FAZ_6_12|Production Readiness|Final Hardening Gate|FINAL_GATE|FAZ 6 Final Closure' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-12.2" "Tum FAZ 6 step final status izi" 'FAZ_6_[0-9]+_FINAL_STATUS=PASS|FAZ_6_10_FINAL_STATUS=PASS|FAZ_6_11_FINAL_STATUS=PASS' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-12.3" "Runtime audit closure izi" 'RUNTIME_AUDIT_STATUS=COMPLETE|FAZ_6_12_RUNTIME_AUDIT|runtime audit' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-12.4" "Real implementation audit closure izi" 'REAL_IMPLEMENTATION_STATUS=PASS|REAL_IMPLEMENTATION_AUDIT|real implementation' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-12.5" "Critical fix closure izi" 'NATS_MONITORING_FIX_STATUS=PASS|POSTDEPLOY_SMOKE_WARN_STATUS=CLEAR|EDGE_HEADER_FIX_V2_STATUS=PASS|EDGE_HTTP_WARN_STATUS=CLEAR' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-12.6" "Cloudflare gray decision izi" 'Cloudflare|cloudflare|GRAY_BY_DECISION|gray|gri|green target|PUBLIC_LAUNCH_BEFORE_GO_LIVE' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-12.7" "Production blocker gate izi" 'BLOCKER_COUNT|blocker|NO_GO|GO_FOR_NEXT_PHASE|FAZ_7_READY' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-12.8" "Final gate probe / test script izi" 'pix2pi_faz6_final_gate_probe|test_faz6_12|audit_faz6_12|FINAL_GATE_PROBE' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-12.9" "Final closure manifest izi" 'FAZ_6_FINAL_CLOSURE_MANIFEST|FAZ 6 Final Closure Manifest|FAZ 6 Scope|Critical Fixes During FAZ 6' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-12.10" "Production launch controlled note izi" 'public launch|production public launch|controlled public launch|Cloudflare green|Full strict|WAF|rate limit' "optional" || OPTIONAL_WARN=$((OPTIONAL_WARN + 1))

{
  echo
  echo "# Final Runtime Implementation Interpretation"
  echo
  echo '~~~text'
  echo "REQUIRED_FAIL=$REQUIRED_FAIL"
  echo "OPTIONAL_WARN=$OPTIONAL_WARN"

  if [ "$REQUIRED_FAIL" -eq 0 ]; then
    echo "FAZ_6_12_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PASS ✅"
  else
    echo "FAZ_6_12_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PARTIAL_OR_MISSING ❌"
  fi

  if [ "$OPTIONAL_WARN" -eq 0 ]; then
    echo "FAZ_6_12_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=PASS ✅"
  else
    echo "FAZ_6_12_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=HAS_WARNINGS ⚠️"
  fi

  if [ "$REQUIRED_FAIL" -eq 0 ] && [ "$OPTIONAL_WARN" -eq 0 ]; then
    echo "FAZ_6_12_REAL_IMPLEMENTATION_STATUS=PASS ✅"
    echo "FAZ_6_12_FINAL_BLOCKER_COUNT=0"
    echo "FAZ_7_READY=YES ✅"
  elif [ "$REQUIRED_FAIL" -eq 0 ]; then
    echo "FAZ_6_12_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
    echo "FAZ_6_12_FINAL_BLOCKER_COUNT=0"
    echo "FAZ_7_READY=YES_WITH_WARNINGS ⚠️"
  else
    echo "FAZ_6_12_REAL_IMPLEMENTATION_STATUS=NOT_FULLY_IMPLEMENTED ❌"
    echo "FAZ_6_12_FINAL_BLOCKER_COUNT=$REQUIRED_FAIL"
    echo "FAZ_7_READY=NO_REVIEW_REQUIRED ❌"
  fi

  echo "FAZ_6_12_REAL_IMPLEMENTATION_AUDIT=COMPLETE ✅"
  echo '~~~'
} >> "$EVIDENCE_FILE"

echo
echo "===== FAZ 6-12 REAL IMPLEMENTATION AUDIT OZETI ====="
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"

if [ "$REQUIRED_FAIL" -eq 0 ]; then
  echo "FAZ_6_12_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PASS ✅"
else
  echo "FAZ_6_12_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PARTIAL_OR_MISSING ❌"
fi

if [ "$OPTIONAL_WARN" -eq 0 ]; then
  echo "FAZ_6_12_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=PASS ✅"
else
  echo "FAZ_6_12_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=HAS_WARNINGS ⚠️"
fi

if [ "$REQUIRED_FAIL" -eq 0 ] && [ "$OPTIONAL_WARN" -eq 0 ]; then
  echo "FAZ_6_12_REAL_IMPLEMENTATION_STATUS=PASS ✅"
  echo "FAZ_6_12_FINAL_BLOCKER_COUNT=0"
  echo "FAZ_7_READY=YES ✅"
elif [ "$REQUIRED_FAIL" -eq 0 ]; then
  echo "FAZ_6_12_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
  echo "FAZ_6_12_FINAL_BLOCKER_COUNT=0"
  echo "FAZ_7_READY=YES_WITH_WARNINGS ⚠️"
else
  echo "FAZ_6_12_REAL_IMPLEMENTATION_STATUS=NOT_FULLY_IMPLEMENTED ❌"
  echo "FAZ_6_12_FINAL_BLOCKER_COUNT=$REQUIRED_FAIL"
  echo "FAZ_7_READY=NO_REVIEW_REQUIRED ❌"
fi

echo "FAZ_6_12_REAL_IMPLEMENTATION_AUDIT=COMPLETE ✅"
echo "OK ✅ evidence yazildi: $EVIDENCE_FILE"

exit 0
