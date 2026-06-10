BEGIN;

DROP TABLE IF EXISTS runtime.webhook_delivery_attempts;
DROP TABLE IF EXISTS runtime.webhook_deliveries;
DROP TABLE IF EXISTS runtime.webhook_endpoints;

DROP FUNCTION IF EXISTS runtime.validate_webhook_attempt_scope();
DROP FUNCTION IF EXISTS runtime.validate_webhook_delivery_scope();

DROP TYPE IF EXISTS runtime.webhook_attempt_status_enum;
DROP TYPE IF EXISTS runtime.webhook_delivery_status_enum;
DROP TYPE IF EXISTS runtime.webhook_auth_type_enum;

COMMIT;
