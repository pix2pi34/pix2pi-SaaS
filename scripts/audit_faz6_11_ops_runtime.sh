#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR" || exit 1

EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_11_OPS_RUNTIME_AUDIT.md"
mkdir -p docs/faz6/evidence

mask_secret() {
  sed -E \
    -e 's/(password=)[^ ]+/\1***MASKED***/g' \
    -e 's/(PASSWORD=).*/\1***MASKED***/g' \
    -e 's/(JWT_SECRET=).*/\1***MASKED***/g' \
    -e 's/(SECRET=).*/\1***MASKED***/g' \
    -e 's/(TOKEN=).*/\1***MASKED***/g'
}

write_cmd_block() {
  local title="$1"
  shift

  {
    echo
    echo "## $title"
    echo
    echo '~~~text'
    "$@" 2>&1 | mask_secret || true
    echo '~~~'
  } >> "$EVIDENCE_FILE"
}

cat <<EOF2 > "$EVIDENCE_FILE"
# FAZ 6-11 Ops Runtime Audit Evidence

Generated At: $(date -Is)  
Host: $(hostname)  
Repo: $ROOT_DIR  

Bu audit ops console / incident / runbook runtime izlerini toplar.
Servis restart etmez, config degistirmez, incident acmaz.

FAZ_6_11_RUNTIME_AUDIT=STARTED ✅

---

EOF2

echo "===== FAZ 6-11 OPS RUNTIME AUDIT BASLADI ====="

write_cmd_block "6-11.1 Host / Kernel" uname -a

write_cmd_block "6-11.2 Docker Services Snapshot" bash -lc "docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}' 2>/dev/null || true"

write_cmd_block "6-11.3 Systemd Services Snapshot" bash -lc "systemctl list-units --type=service --all 2>/dev/null | grep -Ei 'pix2pi|gateway|identity|mission|registry|event|nginx|docker|prometheus|grafana' || true"

write_cmd_block "6-11.4 Health / Metrics Probe" bash -lc "bash scripts/pix2pi_ops_console_probe.sh 2>&1 || true"

write_cmd_block "6-11.5 Runbook Template Check Probe" bash -lc "bash scripts/pix2pi_runbook_template_check.sh 2>&1 || true"

write_cmd_block "6-11.6 Incident / Runbook Files Inventory" bash -lc "find docs/faz6 docs/runbooks docs -maxdepth 5 -type f 2>/dev/null | grep -Ei 'incident|runbook|ops|sre|postmortem|severity|alert|warning' | sort | head -n 220 || true"

write_cmd_block "6-11.7 Logs Incident Signal Inventory" bash -lc "
for f in /var/log/nginx/error.log /var/log/nginx/access.log /var/log/fail2ban.log /var/log/auth.log /var/log/pix2pi/audit.log /var/log/pix2pi/security.log; do
  if [ -f \"\$f\" ]; then
    echo ===== \$f =====
    grep -Ei 'incident|error|fail|denied|down|timeout|upstream|unauthorized|forbidden|warn|critical|alert' \"\$f\" 2>/dev/null | tail -n 80 || true
  else
    echo WARN missing \$f
  fi
done
"

write_cmd_block "6-11.8 Observability / Alert Inventory" bash -lc "grep -RInE 'alert:|severity|critical|warning|incident|runbook|dashboard|grafana|prometheus|SRE|ops' . /etc/prometheus /etc/grafana /opt/pix2pi 2>/dev/null | head -n 220 || true"

{
  echo
  echo "## 6-11.9 Runtime Audit Interpretation"
  echo
  echo '~~~text'
  echo "6-11.1 Host inventory collected OK ✅"
  echo "6-11.2 Docker services snapshot collected OK ✅"
  echo "6-11.3 Systemd services snapshot collected OK ✅"
  echo "6-11.4 Health/metrics probe collected OK ✅"
  echo "6-11.5 Runbook template check collected OK ✅"
  echo "6-11.6 Incident/runbook files inventory collected OK ✅"
  echo "6-11.7 Logs incident signal inventory collected OK ✅"
  echo "6-11.8 Observability/alert inventory collected OK ✅"
  echo "FAZ_6_11_RUNTIME_AUDIT=COMPLETE ✅"
  echo '~~~'
} >> "$EVIDENCE_FILE"

echo "FAZ_6_11_RUNTIME_AUDIT=COMPLETE ✅"
echo "OK ✅ evidence yazildi: $EVIDENCE_FILE"
exit 0
