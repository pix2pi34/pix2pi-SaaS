BEGIN;

DROP TABLE IF EXISTS runtime.api_key_usage;
DROP TABLE IF EXISTS runtime.api_quota_policies;
DROP TABLE IF EXISTS runtime.api_keys;

DROP FUNCTION IF EXISTS runtime.validate_api_key_usage_scope();
DROP FUNCTION IF EXISTS runtime.validate_api_quota_policy_scope();

DROP TYPE IF EXISTS runtime.quota_period_enum;
DROP TYPE IF EXISTS runtime.api_key_status_enum;

COMMIT;
