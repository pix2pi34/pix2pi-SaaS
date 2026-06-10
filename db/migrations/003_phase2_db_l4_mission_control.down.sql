BEGIN;

DROP TABLE IF EXISTS runtime.mission_control_actions;
DROP TABLE IF EXISTS runtime.mission_control_incidents;

DROP FUNCTION IF EXISTS runtime.validate_mission_control_action_scope();
DROP FUNCTION IF EXISTS runtime.validate_mission_control_incident_scope();

DROP TYPE IF EXISTS runtime.mission_control_action_status_enum;
DROP TYPE IF EXISTS runtime.mission_control_action_type_enum;
DROP TYPE IF EXISTS runtime.mission_control_incident_status_enum;
DROP TYPE IF EXISTS runtime.mission_control_severity_enum;

COMMIT;
