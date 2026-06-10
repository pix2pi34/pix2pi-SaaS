#!/usr/bin/env bash
set -euo pipefail

cd ~/pix2pi/pix2pi-SaaS

echo "===== STEP 57B / PROD OPS SUITE ====="

echo
echo "===== 1) SERVICE CHECK ====="
systemctl is-active --quiet pix2pi-api-gateway.service
echo "OK ✅ api-gateway active"

systemctl is-active --quiet pix2pi-user-created-consumer.service
echo "OK ✅ user-created-consumer active"

systemctl is-active --quiet pix2pi-accounting.service
echo "OK ✅ accounting active"

echo
echo "===== 2) QUERY SUITE ====="
if [ ! -x ~/pix2pi/pix2pi-SaaS/scripts/query_smoke_prod.sh ]; then
  echo "ERROR ❌ query_smoke_prod.sh yok veya executable degil"
  exit 1
fi
~/pix2pi/pix2pi-SaaS/scripts/query_smoke_prod.sh
echo "OK ✅ query suite gecti"

echo
echo "===== 3) USER-CREATED E2E ====="
if [ ! -x ~/pix2pi/pix2pi-SaaS/scripts/prod_e2e_user_created_check.sh ]; then
  echo "ERROR ❌ prod_e2e_user_created_check.sh yok veya executable degil"
  exit 1
fi
~/pix2pi/pix2pi-SaaS/scripts/prod_e2e_user_created_check.sh
echo "OK ✅ user-created e2e gecti"

echo
echo "===== 4) FINANCE POST RESTART ====="
if [ ! -x ~/pix2pi/pix2pi-SaaS/scripts/prod_finance_post_restart_check.sh ]; then
  echo "ERROR ❌ prod_finance_post_restart_check.sh yok veya executable degil"
  exit 1
fi
~/pix2pi/pix2pi-SaaS/scripts/prod_finance_post_restart_check.sh
echo "OK ✅ finance post restart gecti"

echo
echo "OK ✅ step_57b_prod_ops_suite gecti"
