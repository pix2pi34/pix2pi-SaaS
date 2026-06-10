# Phoenix Owner Approvals API Systemd Stabilize Audit

## Amaç

Phoenix kayıt onay API servisini kalıcı systemd service olarak sabitlemek.

## Service

- pix2pi-owner-register-approvals-api.service
- Port: 9037
- App dir: /root/pix2pi/pix2pi-SaaS/web/customer-register/data/applications

## Test

- Health HTTP: 200
- Applications HTTP: 200

## Backup

/root/pix2pi/pix2pi-SaaS/backups/phoenix-owner-approvals-api-systemd-stabilize/20260518_193254

## Counts

PASS_COUNT=6
FAIL_COUNT=0
WARN_COUNT=0
