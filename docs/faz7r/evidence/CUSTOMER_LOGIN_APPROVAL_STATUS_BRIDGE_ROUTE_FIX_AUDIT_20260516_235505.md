# Customer Login Approval Status Bridge Route Fix Audit

## Problem

Previous run failed at PANEL NGINX API STATUS TEST with non-JSON body:
- python json.tool error: Expecting value line 1 column 1
- likely route fell through to login SPA HTML instead of API JSON.

## Fix

- Rewrote nginx snippet with exact routes:
  - /customer-login/application-status-api/health
  - /customer-login/application-status-api/status
  - /customer-login/application-status-api/
- Re-injected snippet into panel server blocks.
- Kept tenant create disabled / handoff only.

## Runtime

- API service: pix2pi-customer-login-application-status-api.service
- API port: 9038
- Data dir: /root/pix2pi/pix2pi-SaaS/web/customer-register/data/applications
- Nginx snippet: /etc/nginx/snippets/pix2pi_customer_login_application_status_locations.conf

## Route statuses

- Panel local HTTP: PASS
- Panel local HTTPS: PASS
- Panel external HTTPS: PASS

## Markers

- CUSTOMER_LOGIN_APPROVAL_STATUS_BRIDGE_MARKER
- OWNER_REGISTER_APPROVALS_ADMIN_MARKER
- REGISTER_APPROVAL_HANDOFF_MARKER

## Tests

- API syntax: PASS
- systemd active: PASS
- direct API health: PASS
- nginx -t: PASS
- nginx reload: PASS
- direct approved API: PASS
- local HTTP panel API: PASS
- local HTTPS panel API: PASS
- external HTTPS panel API: PASS
- unknown email NOT_REGISTERED: PASS
- frontend bridge marker: PASS
- tenant_create_real_create=false: PASS

## Counts

- PASS_COUNT=17
- FAIL_COUNT=0
- WARN_COUNT=0
