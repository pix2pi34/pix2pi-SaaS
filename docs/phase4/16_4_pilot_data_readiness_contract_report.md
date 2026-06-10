# FAZ 4B / 16.4 - Pilot Data Readiness / Sample Dataset Contract Report

Generated at: 2026-04-30 06:42:06 

## Summary
ROOT_DIR=/root/pix2pi/pix2pi-SaaS
SERVICE_RESTARTED=NO
CONTAINER_RESTARTED=NO
DOCKER_COMPOSE_EXECUTED=NO
NGINX_RELOAD_EXECUTED=NO
FIREWALL_CHANGED=NO
PORT_CHANGED=NO
CONFIG_CHANGED=NO
ENV_CHANGED=NO
SAMPLE_DATA_INSERTED=NO
REAL_CUSTOMER_DATA_CREATED=NO
REAL_PRODUCT_CREATED=NO
REAL_STOCK_MUTATED=NO
REAL_SALE_CREATED=NO
REAL_ACCOUNTING_ENTRY_CREATED=NO
DATA_IMPORT_EXECUTED=NO
FILE_EXPORT_EXECUTED=NO
UI_CODE_CHANGED=NO
API_ROUTE_CREATED=NO
API_IMPLEMENTATION_CHANGED=NO
DB_MUTATION=NO
DB_APPLY_EXECUTED=NO
MIGRATION_CREATED=NO
MIGRATION_APPLY_EXECUTED=NO
EVENT_PUBLISHED=NO
EVENT_CONSUMED=NO
NOTIFICATION_SENT=NO
CUSTOMER_PRIVATE_DATA_PRINTED=NO
RAW_DSN_PRINTED=NO
SECRET_VALUE_PRINTED=NO
TOKEN_PRINTED=NO
VALIDATION_MODE=PILOT_DATA_READINESS_CONTRACT_ONLY
PREVIOUS_16_3_FINAL_STATUS=PASS
PREVIOUS_16_3_UAT_SCENARIO_EXECUTION_CONTRACT=PASS
PREVIOUS_16_3_UAT_NO_RUNTIME_CHANGE=PASS
PREVIOUS_16_3_UAT_SECRET_SAFE=PASS
PREVIOUS_16_2_FINAL_STATUS=PASS
PREVIOUS_16_1_FINAL_STATUS=PASS
PREVIOUS_17_FINAL_STATUS=PASS
PREVIOUS_20_FINAL_STATUS=PASS
PREVIOUS_21_FINAL_STATUS=PASS
PREVIOUS_22_FINAL_STATUS=PASS
PILOT_DATA_PRODUCT_SAMPLE_COUNT=12
PILOT_DATA_STOCK_SAMPLE_COUNT=12
PILOT_DATA_PARTY_SAMPLE_COUNT=8
PILOT_DATA_SALES_ACCOUNTING_SAMPLE_COUNT=12
PILOT_DATA_QUALITY_GATE_COUNT=12
PILOT_DATA_QUALITY_BLOCKER_COUNT=11
PILOT_DATA_STOCK_BLOCKER_COUNT=7
PILOT_DATA_SALES_BLOCKER_COUNT=8
PILOT_DATA_SYNTHETIC_PARTY_COUNT=8
PILOT_DATA_TDHP_FLOW_COUNT=9
PILOT_DATA_VAT_PRODUCT_COUNT=12
PILOT_DATA_STOCK_TRACKED_PRODUCT_COUNT=11
PILOT_DATA_PREVIOUS_16_3=PASS
PILOT_PRODUCT_SAMPLE_DATASET=PASS
PILOT_STOCK_SAMPLE_DATASET=PASS
PILOT_PARTY_SAMPLE_DATASET=PASS
PILOT_SALES_ACCOUNTING_SAMPLE_DATASET=PASS
PILOT_DATA_QUALITY_GATE_MATRIX=PASS
PILOT_DATA_NO_RUNTIME_CHANGE=PASS
PILOT_DATA_NO_CONFIG_CHANGE=PASS
PILOT_DATA_SECRET_SAFE=PASS
PILOT_DATA_READINESS_CONTRACT=PASS
FAZ4B_16_4_FINAL_STATUS=PASS
FAIL_COUNT=0
WARN_COUNT=0
PILOT_DATA_READINESS_CONTRACT=PASS
FAZ4B_16_4_FINAL_STATUS=PASS

## Tool Status
TOOL_python3=FOUND
TOOL_grep=FOUND
TOOL_wc=FOUND

## Matrix
MATRIX_FILE=docs/phase4/16_4_pilot_data_readiness_contract_matrix.tsv
gate	status	note
previous_16_3	PASS	UAT scenario execution prerequisite
product_sample_dataset	PASS	products=12 vat=12 stock_tracked=11
stock_sample_dataset	PASS	stock_cases=12 blockers=7
party_sample_dataset	PASS	parties=8 synthetic=8
sales_accounting_sample_dataset	PASS	flows=12 tdhp=9 blockers=8
data_quality_gate_matrix	PASS	gates=12 blockers=11
no_runtime_change	PASS	no real data/import/db/api/ui/event changed
no_config_change	PASS	no config/env/nginx/firewall changed
secret_safe	PASS	no secrets/customer private data printed
service_restarted	NO	evidence only
container_restarted	NO	evidence only
docker_compose_executed	NO	evidence only
nginx_reload_executed	NO	evidence only
firewall_changed	NO	evidence only
port_changed	NO	evidence only
config_changed	NO	evidence only
env_changed	NO	evidence only
sample_data_inserted	NO	contract only
real_customer_data_created	NO	contract only
real_product_created	NO	contract only
real_stock_mutated	NO	contract only
real_sale_created	NO	contract only
real_accounting_entry_created	NO	contract only
data_import_executed	NO	contract only
file_export_executed	NO	contract only
ui_code_changed	NO	contract only
api_route_created	NO	contract only
api_implementation_changed	NO	contract only
db_mutation	NO	evidence only
db_apply_executed	NO	evidence only
migration_created	NO	evidence only
migration_apply_executed	NO	evidence only
event_published	NO	contract only
event_consumed	NO	contract only
notification_sent	NO	contract only
customer_private_data_printed	NO	secret-safe report
raw_dsn_printed	NO	secret-safe report
secret_value_printed	NO	secret-safe report
token_printed	NO	secret-safe report

## Inventories
PILOT_PRODUCT_SAMPLE_DATASET_FILE=docs/phase4/16_4_pilot_sample_product_dataset.tsv
PILOT_STOCK_SAMPLE_DATASET_FILE=docs/phase4/16_4_pilot_sample_stock_dataset.tsv
PILOT_PARTY_SAMPLE_DATASET_FILE=docs/phase4/16_4_pilot_sample_party_dataset.tsv
PILOT_SALES_ACCOUNTING_SAMPLE_DATASET_FILE=docs/phase4/16_4_pilot_sample_sales_accounting_dataset.tsv
PILOT_DATA_QUALITY_GATE_MATRIX_FILE=docs/phase4/16_4_pilot_data_quality_gate_matrix.tsv
NOTE=Contract only. No real data/import/runtime/config/db/api/ui/event/customer-private-data change executed.

## Safety Decision
SERVICE_RESTARTED=NO
CONTAINER_RESTARTED=NO
DOCKER_COMPOSE_EXECUTED=NO
NGINX_RELOAD_EXECUTED=NO
FIREWALL_CHANGED=NO
PORT_CHANGED=NO
CONFIG_CHANGED=NO
ENV_CHANGED=NO
SAMPLE_DATA_INSERTED=NO
REAL_CUSTOMER_DATA_CREATED=NO
REAL_PRODUCT_CREATED=NO
REAL_STOCK_MUTATED=NO
REAL_SALE_CREATED=NO
REAL_ACCOUNTING_ENTRY_CREATED=NO
DATA_IMPORT_EXECUTED=NO
FILE_EXPORT_EXECUTED=NO
UI_CODE_CHANGED=NO
API_ROUTE_CREATED=NO
API_IMPLEMENTATION_CHANGED=NO
DB_MUTATION=NO
DB_APPLY_EXECUTED=NO
MIGRATION_CREATED=NO
MIGRATION_APPLY_EXECUTED=NO
EVENT_PUBLISHED=NO
EVENT_CONSUMED=NO
NOTIFICATION_SENT=NO
CUSTOMER_PRIVATE_DATA_PRINTED=NO
RAW_DSN_PRINTED=NO
SECRET_VALUE_PRINTED=NO
TOKEN_PRINTED=NO

## Issues
OK ✅ issue yok
