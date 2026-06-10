BEGIN;

DROP TABLE IF EXISTS runtime.workflow_approvals;
DROP TABLE IF EXISTS runtime.workflow_steps;
DROP TABLE IF EXISTS runtime.workflow_instances;
DROP TABLE IF EXISTS runtime.workflow_definitions;

DROP FUNCTION IF EXISTS runtime.validate_workflow_approval_scope();
DROP FUNCTION IF EXISTS runtime.validate_workflow_step_scope();
DROP FUNCTION IF EXISTS runtime.validate_workflow_instance_scope();

DROP TYPE IF EXISTS runtime.workflow_approval_status_enum;
DROP TYPE IF EXISTS runtime.workflow_step_status_enum;
DROP TYPE IF EXISTS runtime.workflow_instance_status_enum;
DROP TYPE IF EXISTS runtime.workflow_definition_status_enum;

COMMIT;
