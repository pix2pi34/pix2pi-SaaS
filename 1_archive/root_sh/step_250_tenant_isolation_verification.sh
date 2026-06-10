#!/bin/bash
set -e

echo "=== TEST 1: tenant-001 sadece kendini gorebilir ==="
cikti_1=$(PGPASSWORD='pix2pi_app_pass' psql -h localhost -p 5433 -U pix2pi_app -d pix2pi -t -A <<'SQLEOF'
BEGIN;
SET LOCAL app.current_tenant = 'tenant-001';
SELECT string_agg(tenant_id || ':' || aggregate_id, ',')
FROM snapshots;
COMMIT;
SQLEOF
)

echo "$cikti_1"

if echo "$cikti_1" | grep -q "tenant-test"; then
  echo "HATA ❌ tenant-001, tenant-test verisini gordu"
  exit 1
fi

if ! echo "$cikti_1" | grep -q "tenant-001"; then
  echo "HATA ❌ tenant-001 kendi verisini goremedi"
  exit 1
fi

echo "OK ✅ tenant-001 izolasyonu dogru"

echo
echo "=== TEST 2: tenant-test sadece kendini gorebilir ==="
cikti_2=$(PGPASSWORD='pix2pi_app_pass' psql -h localhost -p 5433 -U pix2pi_app -d pix2pi -t -A <<'SQLEOF'
BEGIN;
SET LOCAL app.current_tenant = 'tenant-test';
SELECT string_agg(tenant_id || ':' || aggregate_id, ',')
FROM snapshots;
COMMIT;
SQLEOF
)

echo "$cikti_2"

if echo "$cikti_2" | grep -q "tenant-001"; then
  echo "HATA ❌ tenant-test, tenant-001 verisini gordu"
  exit 1
fi

if ! echo "$cikti_2" | grep -q "tenant-test"; then
  echo "HATA ❌ tenant-test kendi verisini goremedi"
  exit 1
fi

echo "OK ✅ tenant-test izolasyonu dogru"

echo
echo "=== TEST 3: cross-tenant insert bloklanmali ==="
set +e
cikti_3=$(PGPASSWORD='pix2pi_app_pass' psql -h localhost -p 5433 -U pix2pi_app -d pix2pi 2>&1 <<'SQLEOF'
BEGIN;
SET LOCAL app.current_tenant = 'tenant-001';
INSERT INTO snapshots (tenant_id, aggregate_type, aggregate_id, version, state, updated_at)
VALUES ('tenant-hack','stock','HACK-VERIFY',1,'{}',NOW());
COMMIT;
SQLEOF
)
kod_3=$?
set -e

echo "$cikti_3"

if [ $kod_3 -eq 0 ]; then
  echo "HATA ❌ cross-tenant insert basarili olmamaliydi"
  exit 1
fi

if ! echo "$cikti_3" | grep -qi "row-level security"; then
  echo "HATA ❌ beklenen RLS hatasi gelmedi"
  exit 1
fi

echo "OK ✅ cross-tenant insert engellendi"

echo
echo "=== TEST 4: tenant kendi verisini yazabilmeli ==="
PGPASSWORD='pix2pi_app_pass' psql -h localhost -p 5433 -U pix2pi_app -d pix2pi <<'SQLEOF'
BEGIN;
SET LOCAL app.current_tenant = 'tenant-001';
INSERT INTO snapshots (tenant_id, aggregate_type, aggregate_id, version, state, updated_at)
VALUES ('tenant-001','stock','VERIFY-OK-1',1,'{"event":"verify.ok"}',NOW())
ON CONFLICT (tenant_id, aggregate_type, aggregate_id)
DO UPDATE SET
  version = snapshots.version + 1,
  state = EXCLUDED.state,
  updated_at = NOW();
COMMIT;
SQLEOF

echo "OK ✅ tenant kendi verisini yazabildi"

echo
echo "=== TEST 5: tenant-001 yazdigi kaydi gorebilmeli ==="
cikti_5=$(PGPASSWORD='pix2pi_app_pass' psql -h localhost -p 5433 -U pix2pi_app -d pix2pi -t -A <<'SQLEOF'
BEGIN;
SET LOCAL app.current_tenant = 'tenant-001';
SELECT aggregate_id
FROM snapshots
WHERE aggregate_id = 'VERIFY-OK-1';
COMMIT;
SQLEOF
)

echo "$cikti_5"

if ! echo "$cikti_5" | grep -q "VERIFY-OK-1"; then
  echo "HATA ❌ tenant-001 kendi yeni kaydini goremedi"
  exit 1
fi

echo "OK ✅ tenant kendi kaydini gorebildi"

echo
echo "OK ✅ tenant isolation verification suite bitti"
