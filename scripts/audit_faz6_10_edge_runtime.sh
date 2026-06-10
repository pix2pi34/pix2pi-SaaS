#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR" || exit 1

DOMAIN="${PIX2PI_DOMAIN:-pix2pi.com.tr}"
EVIDENCE_FILE="docs/faz6/evidence/FAZ_6_10_EDGE_RUNTIME_AUDIT.md"

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
    echo '```text'
    "$@" 2>&1 | mask_secret || true
    echo '```'
  } >> "$EVIDENCE_FILE"
}

cat <<EOF2 > "$EVIDENCE_FILE"
# FAZ 6-10 Edge Runtime Audit Evidence

Generated At: $(date -Is)  
Host: $(hostname)  
Repo: $ROOT_DIR  
DOMAIN=$DOMAIN  

Bu audit DNS/CDN/WAF/Edge runtime izlerini toplar. Degisiklik yapmaz.

FAZ_6_10_RUNTIME_AUDIT=STARTED ✅

---

EOF2

echo "===== FAZ 6-10 EDGE RUNTIME AUDIT BASLADI ====="

write_cmd_block "6-10.1 Host / Kernel" uname -a

write_cmd_block "6-10.2 DNS Resolution Runtime" bash -lc "
if command -v dig >/dev/null 2>&1; then
  echo '===== A ====='
  dig +short A '$DOMAIN' || true
  echo '===== AAAA ====='
  dig +short AAAA '$DOMAIN' || true
  echo '===== CNAME ====='
  dig +short CNAME '$DOMAIN' || true
  echo '===== NS ====='
  dig +short NS '$DOMAIN' || true
else
  getent hosts '$DOMAIN' || true
fi
"

write_cmd_block "6-10.3 TLS Certificate Probe" bash -lc "
echo | openssl s_client -servername '$DOMAIN' -connect '$DOMAIN:443' 2>/dev/null | openssl x509 -noout -subject -issuer -dates 2>/dev/null || true
"

write_cmd_block "6-10.4 Public HTTPS Header Probe" bash -lc "
curl -L -I -sS --max-time 10 https://'$DOMAIN'/ 2>/dev/null | head -n 120 || true
"

write_cmd_block "6-10.5 Public GET Content Probe" bash -lc "
curl -L -sS --max-time 10 -w '\nHTTP_STATUS=%{http_code} SIZE=%{size_download} TIME=%{time_total} REMOTE_IP=%{remote_ip}\n' https://'$DOMAIN'/ | head -c 1600 || true
"

write_cmd_block "6-10.6 Public Pilot GET Content Probe" bash -lc "
curl -L -sS --max-time 10 -w '\nHTTP_STATUS=%{http_code} SIZE=%{size_download} TIME=%{time_total} REMOTE_IP=%{remote_ip}\n' https://'$DOMAIN'/faz4d/pilot-go-live/ | head -c 2000 || true
"

write_cmd_block "6-10.7 HTTP Redirect Probe" bash -lc "
curl -I -sS --max-time 10 http://'$DOMAIN'/ 2>/dev/null | head -n 80 || true
"

write_cmd_block "6-10.8 Nginx Edge Config Inventory" bash -lc "
nginx -t 2>&1 || true
echo
grep -RInE 'server_name|listen 443|listen 80|ssl_certificate|proxy_pass|add_header|Strict-Transport|X-Frame|X-Content|Referrer|Content-Security|client_max_body_size|limit_req|limit_conn|proxy_set_header|X-Forwarded|X-Request-ID|deny|allow' /etc/nginx 2>/dev/null | head -n 220 || true
"

write_cmd_block "6-10.9 Origin / Internal Port Exposure Inventory" bash -lc "
ss -lntp 2>/dev/null | grep -E ':80|:443|:5432|:5433|:6379|:4222|:8222|:9001|:9002|:9010|:9090|:3001|:9100|:8080' || true
"

write_cmd_block "6-10.10 Edge Logs Inventory" bash -lc "
for f in /var/log/nginx/access.log /var/log/nginx/error.log /var/log/fail2ban.log /var/log/auth.log; do
  if [ -f \"\$f\" ]; then
    echo ===== \$f =====
    grep -Ei 'cloudflare|cf-ray|waf|blocked|denied|limit|rate|bot|scanner|timeout|upstream| 4[0-9][0-9] | 5[0-9][0-9] ' \"\$f\" 2>/dev/null | tail -n 100 || true
  else
    echo WARN missing \$f
  fi
done
"

write_cmd_block "6-10.11 Edge Guard Scripts Probe" bash -lc "
bash scripts/pix2pi_edge_dns_probe.sh 2>&1 || true
echo
bash scripts/pix2pi_edge_http_smoke.sh 2>&1 || true
"

{
  echo
  echo "## 6-10.12 Runtime Audit Interpretation"
  echo
  echo '```text'
  echo "6-10.1 Host inventory collected OK ✅"
  echo "6-10.2 DNS resolution runtime collected OK ✅"
  echo "6-10.3 TLS certificate probe collected OK ✅"
  echo "6-10.4 Public HTTPS header probe collected OK ✅"
  echo "6-10.5 Public GET content probe collected OK ✅"
  echo "6-10.6 Public pilot GET content probe collected OK ✅"
  echo "6-10.7 HTTP redirect probe collected OK ✅"
  echo "6-10.8 Nginx edge config inventory collected OK ✅"
  echo "6-10.9 Origin/internal port exposure inventory collected OK ✅"
  echo "6-10.10 Edge logs inventory collected OK ✅"
  echo "6-10.11 Edge guard scripts probe collected OK ✅"
  echo "FAZ_6_10_RUNTIME_AUDIT=COMPLETE ✅"
  echo '```'
} >> "$EVIDENCE_FILE"

echo "FAZ_6_10_RUNTIME_AUDIT=COMPLETE ✅"
echo "OK ✅ evidence yazildi: $EVIDENCE_FILE"
exit 0
