BEGIN;

DROP TABLE IF EXISTS runtime.notification_recipients;
DROP TABLE IF EXISTS runtime.notifications;
DROP TABLE IF EXISTS runtime.notification_channels;

DROP TYPE IF EXISTS runtime.notification_recipient_status_enum;
DROP TYPE IF EXISTS runtime.notification_recipient_type_enum;
DROP TYPE IF EXISTS runtime.notification_status_enum;
DROP TYPE IF EXISTS runtime.notification_channel_type_enum;

COMMIT;
