# FAZ 1-2.8 API Auth Contract Extract V7B Safe Continue

- Tarih: 2026-05-04T22:40:47+03:00
- Repo: /root/pix2pi/pix2pi-SaaS
- Backup dir: /root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_2_8_api_auth_contract_extract_v7_20260504_223846

## Amaç
V7 journal/log adımında final evidence'a ulaşmadan kesildi. V7B mevcut context dosyalarını kullanır, log/journal snapshotlarını timeout-safe alır ve auth contract özetini üretir.

## Counts
- ROUTE_CONTEXT_COUNT=202
- AUTH_CONTEXT_COUNT=31947
- JWT_CONTEXT_COUNT=924
- TENANT_CONTEXT_COUNT=24121
- UNAUTHORIZED_CONTEXT_COUNT=6985
- CANDIDATE_FILE_COUNT=102
- API_RESPONSE_SAMPLE_COUNT=374
- PROCESS_ENV_COUNT=1517
- JOURNAL_COUNT=782
- FILE_LOG_COUNT=428
- AUTO_SUMMARY_COUNT=1304

## Evidence Files
- Auto summary: /root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_2_8_api_auth_contract_extract_v7_20260504_223846/auto_auth_contract_summary_v7b.txt
- JWT context: /root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_2_8_api_auth_contract_extract_v7_20260504_223846/jwt_contract_context.txt
- Auth context: /root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_2_8_api_auth_contract_extract_v7_20260504_223846/auth_middleware_context.txt
- Route context: /root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_2_8_api_auth_contract_extract_v7_20260504_223846/route_context_api_query_users.txt
- Tenant context: /root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_2_8_api_auth_contract_extract_v7_20260504_223846/tenant_header_context.txt
- Unauthorized context: /root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_2_8_api_auth_contract_extract_v7_20260504_223846/unauthorized_context.txt
- API response samples: /root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_2_8_api_auth_contract_extract_v7_20260504_223846/api_response_samples.txt
- Process env snapshot: /root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_2_8_api_auth_contract_extract_v7_20260504_223846/process_env_redacted.txt
- Journal snapshot: /root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_2_8_api_auth_contract_extract_v7_20260504_223846/journal_snapshot_v7b_timeout.txt
- File log snapshot: /root/pix2pi/pix2pi-SaaS/backups/faz1/faz_1_2_8_api_auth_contract_extract_v7_20260504_223846/file_log_snapshot_v7b_timeout.txt

## Counters
- PASS_COUNT=11
- FAIL_COUNT=0
- WARN_COUNT=0
