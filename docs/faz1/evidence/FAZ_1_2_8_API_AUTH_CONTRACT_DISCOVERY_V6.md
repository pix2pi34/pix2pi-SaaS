# FAZ 1-2.8 API Auth Contract Discovery V6

- Tarih: 2026-05-04T22:36:06+03:00
- Repo: /root/pix2pi/pix2pi-SaaS
- Backup dir: /root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_2_8_api_auth_contract_discovery_v6_20260504_223603

## Problem
FIX V5 sonucunda tüm JWT profile denemelerinde same-tenant istek 401 döndü. Bu nedenle canlı cross-tenant API testi auth/token standardı keşfi yapılmadan mühürlenemez.

## Counts
- AUTH_FILE_COUNT=2241
- JWT_FILE_COUNT=677
- ROUTE_FILE_COUNT=185
- AUTH_GUARD_HIT_COUNT=11888
- JWT_CONTRACT_HIT_COUNT=1747
- ROUTE_HIT_COUNT=2110

## Evidence Files
- Auth candidates: /root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_2_8_api_auth_contract_discovery_v6_20260504_223603/auth_file_candidates.txt
- JWT candidates: /root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_2_8_api_auth_contract_discovery_v6_20260504_223603/jwt_file_candidates.txt
- Route candidates: /root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_2_8_api_auth_contract_discovery_v6_20260504_223603/route_file_candidates.txt
- Auth guard hits: /root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_2_8_api_auth_contract_discovery_v6_20260504_223603/auth_tenant_guard_hits.txt
- JWT contract hits: /root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_2_8_api_auth_contract_discovery_v6_20260504_223603/jwt_contract_hits.txt
- Route hits: /root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_2_8_api_auth_contract_discovery_v6_20260504_223603/route_hits.txt
- Runtime snapshot: /root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_2_8_api_auth_contract_discovery_v6_20260504_223603/runtime_service_snapshot.txt
- API 401 samples: /root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_2_8_api_auth_contract_discovery_v6_20260504_223603/api_401_response_samples.txt

## Final
- PASS_COUNT=11
- FAIL_COUNT=0
- WARN_COUNT=0
