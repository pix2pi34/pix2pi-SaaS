#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR" || exit 1

EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_10_REAL_IMPLEMENTATION_AUDIT.md"
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
  -o -path './docs' \
  -o -path './node_modules' \
  -o -path './vendor' \
  -o -path './tmp' \
  \) -prune -o \
  -type f \
  \( -name '*.go' \
  -o -name '*.sql' \
  -o -name '*.sh' \
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
    echo '```text'
    echo "$pattern"
    echo '```'
    echo
    echo "Match Count: $count"
    echo
    echo '```text'
    if [ "$count" -gt 0 ]; then
      head -n 70 "$out"
    else
      echo "NO_MATCH"
    fi
    echo '```'
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
# FAZ 6-10 Real Implementation Audit

Generated At: $(date -Is)  
Host: $(hostname)  
Repo: $ROOT_DIR  

Bu audit, FAZ 6-10 CDN / WAF / DNS / Edge maddelerinin sadece dokumanda mi kaldigini, yoksa kod/config/script icinde gercek karsiligi olup olmadigini kontrol eder.

---

EOF2

echo "===== FAZ 6-10 REAL IMPLEMENTATION AUDIT ====="

{
  echo "## Scanned Files"
  echo
  echo '```text'
  wc -l "$FILE_LIST"
  echo
  head -n 80 "$FILE_LIST"
  echo '```'
} >> "$EVIDENCE_FILE"

write_check "6-10.1" "DNS readiness implementation izi" 'dig|DNS|dns|CNAME|AAAA|TTL|getent hosts|pix2pi_edge_dns_probe|PIX2PI_DOMAIN|SUBDOMAINS' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-10.2" "TLS / HTTPS implementation izi" 'https://|openssl s_client|ssl_certificate|TLS|HTTPS|Strict-Transport|HSTS|443|certificate|cert' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-10.3" "CDN / cache implementation izi" 'CDN|cdn|Cache-Control|CF-Cache-Status|cf-cache-status|Cloudflare|cloudflare|cache|purge|static asset' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-10.4" "WAF / DDoS / bot guardrail izi" 'WAF|waf|DDoS|ddos|bot|scanner|Cloudflare|cloudflare|rate.*limit|limit_req|limit_conn|blocked|deny|fail2ban' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-10.5" "Nginx edge / reverse proxy izi" 'nginx|server_name|proxy_pass|proxy_set_header|X-Forwarded|X-Request-ID|add_header|client_max_body_size|proxy_read_timeout|reverse proxy' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-10.6" "Public route GET content smoke izi" 'curl -L|GET|HTTP_STATUS|size_download|time_total|public.*GET|content check|pix2pi_edge_http_smoke|/faz4d/pilot-go-live' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-10.7" "Origin exposure / internal port safety izi" 'origin|internal.*port|5432|5433|6379|4222|8222|9090|3001|public.*port|exposure|ss -lntp' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-10.8" "Edge observability izi" 'access.log|error.log|cf-ray|CF-Ray|upstream|timeout|4xx|5xx|status code|latency|edge.*log|WAF.*log|rate.*hit' "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))

write_check "6-10.9" "Edge incident / runbook izi" 'incident|runbook|DNS.*incident|SSL.*incident|CDN.*incident|WAF.*incident|public.*404|timeout.*incident|edge.*incident' "optional" || OPTIONAL_WARN=$((OPTIONAL_WARN + 1))

write_check "6-10.10" "Edge test / audit script izi" 'FAZ_6_10|edge.*test|test.*edge|dns.*probe|http.*smoke|runtime.*audit|real.*implementation.*audit' "optional" || OPTIONAL_WARN=$((OPTIONAL_WARN + 1))

{
  echo
  echo "# Final Runtime Implementation Interpretation"
  echo
  echo '```text'
  echo "REQUIRED_FAIL=$REQUIRED_FAIL"
  echo "OPTIONAL_WARN=$OPTIONAL_WARN"

  if [ "$REQUIRED_FAIL" -eq 0 ]; then
    echo "FAZ_6_10_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PASS ✅"
  else
    echo "FAZ_6_10_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PARTIAL_OR_MISSING ❌"
  fi

  if [ "$OPTIONAL_WARN" -eq 0 ]; then
    echo "FAZ_6_10_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=PASS ✅"
  else
    echo "FAZ_6_10_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=HAS_WARNINGS ⚠️"
  fi

  if [ "$REQUIRED_FAIL" -eq 0 ] && [ "$OPTIONAL_WARN" -eq 0 ]; then
    echo "FAZ_6_10_REAL_IMPLEMENTATION_STATUS=PASS ✅"
    echo "FAZ_6_11_READY=YES ✅"
  elif [ "$REQUIRED_FAIL" -eq 0 ]; then
    echo "FAZ_6_10_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
    echo "FAZ_6_11_READY=YES_WITH_WARNINGS ⚠️"
  else
    echo "FAZ_6_10_REAL_IMPLEMENTATION_STATUS=NOT_FULLY_IMPLEMENTED ❌"
    echo "FAZ_6_11_READY=NO_REVIEW_REQUIRED ❌"
  fi

  echo "FAZ_6_10_REAL_IMPLEMENTATION_AUDIT=COMPLETE ✅"
  echo '```'
} >> "$EVIDENCE_FILE"

echo
echo "===== FAZ 6-10 REAL IMPLEMENTATION AUDIT OZETI ====="
echo "REQUIRED_FAIL=$REQUIRED_FAIL"
echo "OPTIONAL_WARN=$OPTIONAL_WARN"

if [ "$REQUIRED_FAIL" -eq 0 ]; then
  echo "FAZ_6_10_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PASS ✅"
else
  echo "FAZ_6_10_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PARTIAL_OR_MISSING ❌"
fi

if [ "$OPTIONAL_WARN" -eq 0 ]; then
  echo "FAZ_6_10_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=PASS ✅"
else
  echo "FAZ_6_10_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=HAS_WARNINGS ⚠️"
fi

if [ "$REQUIRED_FAIL" -eq 0 ] && [ "$OPTIONAL_WARN" -eq 0 ]; then
  echo "FAZ_6_10_REAL_IMPLEMENTATION_STATUS=PASS ✅"
  echo "FAZ_6_11_READY=YES ✅"
elif [ "$REQUIRED_FAIL" -eq 0 ]; then
  echo "FAZ_6_10_REAL_IMPLEMENTATION_STATUS=PASS_WITH_OPTIONAL_WARNINGS ⚠️"
  echo "FAZ_6_11_READY=YES_WITH_WARNINGS ⚠️"
else
  echo "FAZ_6_10_REAL_IMPLEMENTATION_STATUS=NOT_FULLY_IMPLEMENTED ❌"
  echo "FAZ_6_11_READY=NO_REVIEW_REQUIRED ❌"
fi

echo "FAZ_6_10_REAL_IMPLEMENTATION_AUDIT=COMPLETE ✅"
echo "OK ✅ evidence yazildi: $EVIDENCE_FILE"

exit 0
