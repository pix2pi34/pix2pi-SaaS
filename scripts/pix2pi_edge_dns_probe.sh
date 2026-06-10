#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR" || exit 1

DOMAIN="${PIX2PI_DOMAIN:-pix2pi.com.tr}"
SUBDOMAINS="${PIX2PI_SUBDOMAINS:-www api panel auth pos}"
EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_10_EDGE_DNS_PROBE_EVIDENCE.md"

mkdir -p docs/faz6/evidence

PASS_COUNT=0
WARN_COUNT=0

write_line() {
  echo "$1" | tee -a "$EVIDENCE_FILE"
}

probe_dns_name() {
  local name="$1"

  write_line "===== DNS PROBE: $name ====="

  if command -v dig >/dev/null 2>&1; then
    write_line "--- A ---"
    dig +short A "$name" | tee -a "$EVIDENCE_FILE" || true
    write_line "--- AAAA ---"
    dig +short AAAA "$name" | tee -a "$EVIDENCE_FILE" || true
    write_line "--- CNAME ---"
    dig +short CNAME "$name" | tee -a "$EVIDENCE_FILE" || true
    write_line "--- TTL/SOA TRACE ---"
    dig "$name" A +noall +answer | tee -a "$EVIDENCE_FILE" || true
  else
    write_line "WARN ⚠️ dig yok, getent deneniyor"
    getent hosts "$name" | tee -a "$EVIDENCE_FILE" || true
  fi

  if getent hosts "$name" >/tmp/pix2pi_dns_probe_hosts.txt 2>/dev/null; then
    write_line "$name DNS_RESOLVES OK ✅"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    write_line "$name DNS_RESOLVES WARN ⚠️"
    WARN_COUNT=$((WARN_COUNT + 1))
  fi

  write_line ""
}

cat <<EOF2 > "$EVIDENCE_FILE"
# FAZ 6-10 Edge DNS Probe Evidence

Generated At: $(date -Is)  
Repo: $ROOT_DIR  
DOMAIN=$DOMAIN  
SUBDOMAINS=$SUBDOMAINS  

Bu script DNS degistirmez. Sadece DNS readiness evidence uretir.

FAZ_6_10_EDGE_DNS_PROBE=STARTED ✅

---

EOF2

echo "===== PIX2PI EDGE DNS PROBE BASLADI ====="

probe_dns_name "$DOMAIN"

for sub in $SUBDOMAINS; do
  probe_dns_name "$sub.$DOMAIN"
done

{
  echo
  echo "## DNS Probe Final Seal"
  echo
  echo '```text'
  echo "PASS_COUNT=$PASS_COUNT"
  echo "WARN_COUNT=$WARN_COUNT"
  echo "FAZ_6_10_EDGE_DNS_PROBE_STATUS=COMPLETE ✅"

  if [ "$WARN_COUNT" -eq 0 ]; then
    echo "FAZ_6_10_EDGE_DNS_WARN_STATUS=CLEAR ✅"
  else
    echo "FAZ_6_10_EDGE_DNS_WARN_STATUS=HAS_WARNINGS ⚠️"
  fi
  echo '```'
} >> "$EVIDENCE_FILE"

echo "PASS_COUNT=$PASS_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "FAZ_6_10_EDGE_DNS_PROBE_STATUS=COMPLETE ✅"

if [ "$WARN_COUNT" -eq 0 ]; then
  echo "FAZ_6_10_EDGE_DNS_WARN_STATUS=CLEAR ✅"
else
  echo "FAZ_6_10_EDGE_DNS_WARN_STATUS=HAS_WARNINGS ⚠️"
fi

echo "OK ✅ evidence yazildi: $EVIDENCE_FILE"
exit 0
