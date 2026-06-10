BEGIN;

DROP TABLE IF EXISTS runtime.job_attempts;
DROP TABLE IF EXISTS runtime.jobs;
DROP TABLE IF EXISTS runtime.job_queues;

DROP FUNCTION IF EXISTS runtime.validate_job_attempt_scope();
DROP FUNCTION IF EXISTS runtime.validate_job_scope();

DROP TYPE IF EXISTS runtime.job_attempt_status_enum;
DROP TYPE IF EXISTS runtime.job_status_enum;
DROP TYPE IF EXISTS runtime.job_priority_enum;

COMMIT;
