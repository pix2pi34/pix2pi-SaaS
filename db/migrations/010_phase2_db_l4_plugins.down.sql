BEGIN;

DROP TABLE IF EXISTS runtime.plugin_states;
DROP TABLE IF EXISTS runtime.plugins;

DROP FUNCTION IF EXISTS runtime.validate_plugin_state_scope();

DROP TYPE IF EXISTS runtime.plugin_runtime_state_enum;
DROP TYPE IF EXISTS runtime.plugin_lifecycle_status_enum;
DROP TYPE IF EXISTS runtime.plugin_source_type_enum;

COMMIT;
