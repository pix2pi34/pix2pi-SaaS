BEGIN;

DROP TABLE IF EXISTS runtime.service_registry_heartbeats;
DROP TABLE IF EXISTS runtime.service_registry_instances;
DROP TABLE IF EXISTS runtime.service_registry_services;

DROP FUNCTION IF EXISTS runtime.validate_service_registry_heartbeat_scope();
DROP FUNCTION IF EXISTS runtime.validate_service_registry_instance_scope();
DROP FUNCTION IF EXISTS runtime.touch_updated_at();

DROP FUNCTION IF EXISTS security.tenant_or_global_row_visible(uuid);
DROP FUNCTION IF EXISTS security.tenant_only_row_mutable(uuid);

DROP TYPE IF EXISTS runtime.registry_instance_status_enum;
DROP TYPE IF EXISTS runtime.registry_protocol_enum;
DROP TYPE IF EXISTS runtime.registry_visibility_scope_enum;
DROP TYPE IF EXISTS runtime.registry_service_kind_enum;

COMMIT;
