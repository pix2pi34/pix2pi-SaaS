# FAZ 6-11 Ops Runtime Audit Evidence

Generated At: 2026-05-01T16:06:26+03:00  
Host: vm12827.ovadns.com  
Repo: /root/pix2pi/pix2pi-SaaS  

Bu audit ops console / incident / runbook runtime izlerini toplar.
Servis restart etmez, config degistirmez, incident acmaz.

FAZ_6_11_RUNTIME_AUDIT=STARTED ✅

---


## 6-11.1 Host / Kernel

~~~text
Linux vm12827.ovadns.com 5.15.0-176-generic #186-Ubuntu SMP Fri Mar 13 11:01:42 UTC 2026 x86_64 x86_64 x86_64 GNU/Linux
~~~

## 6-11.2 Docker Services Snapshot

~~~text
NAMES                     IMAGE                             STATUS                PORTS
pix2pi_nats               nats:2.10-alpine                  Up 42 minutes         0.0.0.0:4222->4222/tcp, [::]:4222->4222/tcp, 0.0.0.0:8222->8222/tcp, [::]:8222->8222/tcp, 6222/tcp
pix2pi-redis              redis:7-alpine                    Up 9 days             0.0.0.0:6379->6379/tcp, [::]:6379->6379/tcp
pix2pi_pg_replica         postgres:16                       Up 9 days             0.0.0.0:5434->5432/tcp, [::]:5434->5432/tcp
pix2pi-mission-control    deploy-mission-control            Up 9 days             9001/tcp, 0.0.0.0:9101->5860/tcp, [::]:9101->5860/tcp
pix2pi-service-registry   deploy-service-registry           Up 9 days             
pix2pi-identity-api       deploy-identity-api               Up 9 days             0.0.0.0:9002->9002/tcp, [::]:9002->9002/tcp
pix2pi_grafana            grafana/grafana:latest            Up 9 days             0.0.0.0:3001->3000/tcp, [::]:3001->3000/tcp
pix2pi_promtail           grafana/promtail:2.9.8            Up 9 days             
pix2pi_loki               grafana/loki:2.9.8                Up 9 days             0.0.0.0:3100->3100/tcp, [::]:3100->3100/tcp
pix2pi_prometheus         prom/prometheus:latest            Up 9 days             0.0.0.0:9090->9090/tcp, [::]:9090->9090/tcp
pix2pi_node_exporter      prom/node-exporter:latest         Up 9 days             0.0.0.0:9100->9100/tcp, [::]:9100->9100/tcp
pix2pi_tempo              grafana/tempo:2.6.1               Up 9 days             0.0.0.0:3200->3200/tcp, [::]:3200->3200/tcp, 0.0.0.0:4317-4318->4317-4318/tcp, [::]:4317-4318->4317-4318/tcp
pix2pi-api-gateway        kong:3.7                          Up 9 days (healthy)   
pix2pi_pg                 postgres:16                       Up 4 days             0.0.0.0:5433->5432/tcp, [::]:5433->5432/tcp
pix2pi_cadvisor           gcr.io/cadvisor/cadvisor:latest   Up 9 days (healthy)   0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp
~~~

## 6-11.3 Systemd Services Snapshot

~~~text
  dm-event.service                                                                          loaded    inactive dead    Device-mapper event daemon
  docker.service                                                                            loaded    active   running Docker Application Container Engine
  lvm2-monitor.service                                                                      loaded    active   exited  Monitoring of LVM2 mirrors, snapshots etc. using dmeventd or progress polling
  lvm2-pvscan@8:3.service                                                                   loaded    active   exited  LVM event activation on device 8:3
  lvm2-pvscan@8:4.service                                                                   loaded    active   exited  LVM event activation on device 8:4
  nginx.service                                                                             loaded    active   running A high performance web server and a reverse proxy server
  pix2pi-accounting.service                                                                 loaded    active   running Pix2pi Accounting Service
  pix2pi-api-gateway.service                                                                loaded    active   running Pix2pi API Gateway
  pix2pi-auth.service                                                                       loaded    active   running Pix2pi Auth Service
  pix2pi-early-warning-runtime.service                                                      loaded    active   running Pix2pi Early Warning Runtime Monitor
  pix2pi-identity.service                                                                   loaded    active   running Pix2pi Identity Service
  pix2pi-incident-audit-runtime.service                                                     loaded    active   running Pix2pi Incident Audit Runtime Monitor
  pix2pi-jobs-runtime.service                                                               loaded    active   running Pix2pi Jobs Runtime Monitor
  pix2pi-mission-control.service                                                            loaded    active   running Pix2pi Mission Control
  pix2pi-notification-runtime.service                                                       loaded    active   running Pix2pi Notification Runtime Monitor
  pix2pi-panel.service                                                                      loaded    active   running Pix2pi Control Panel
  pix2pi-plugin-runtime.service                                                             loaded    active   running Pix2pi Plugin Runtime Monitor
  pix2pi-publicapi-runtime.service                                                          loaded    active   running Pix2pi Public API Runtime Monitor
  pix2pi-query-read-model.service                                                           loaded    active   running Pix2pi Query Read Model
  pix2pi-realtime-runtime.service                                                           loaded    active   running Pix2pi Realtime Channel Runtime Monitor
  pix2pi-runtime-topology.service                                                           loaded    active   running Pix2pi Runtime Health Topology Monitor
  pix2pi-service-registry.service                                                           loaded    active   running Pix2pi Service Registry
  pix2pi-user-created-consumer.service                                                      loaded    active   running Pix2pi User Created Consumer
  pix2pi-webhook-runtime.service                                                            loaded    active   running Pix2pi Webhook Runtime Monitor
  pix2pi-workflow-runtime.service                                                           loaded    active   running Pix2pi Workflow Runtime Monitor
  snapd.core-fixup.service                                                                  loaded    inactive dead    Automatically repair incorrect owner/permissions on core devices
  systemd-udevd.service                                                                     loaded    active   running Rule-based Manager for Device Events and Files
~~~

## 6-11.4 Health / Metrics Probe

~~~text
===== PIX2PI OPS CONSOLE PROBE BASLADI =====
===== OPS PROBE: identity-api health =====
URL=http://127.0.0.1:9002/health
http_code=200 time_total=0.001315 size=33
identity-api health STATUS=OK ✅

===== OPS PROBE: api-gateway health =====
URL=http://127.0.0.1:9010/health
http_code=200 time_total=0.000747 size=21
api-gateway health STATUS=OK ✅

===== OPS PROBE: prometheus ready =====
URL=http://127.0.0.1:9090/-/ready
http_code=200 time_total=0.001315 size=28
prometheus ready STATUS=OK ✅

===== OPS PROBE: grafana health =====
URL=http://127.0.0.1:3001/api/health
http_code=200 time_total=0.001179 size=101
grafana health STATUS=OK ✅

===== OPS PROBE: node_exporter metrics =====
URL=http://127.0.0.1:9100/metrics
http_code=200 time_total=0.018896 size=73783
node_exporter metrics STATUS=OK ✅

===== OPS PROBE: cadvisor metrics =====
URL=http://127.0.0.1:8080/metrics
http_code=200 time_total=0.270443 size=7731318
cadvisor metrics STATUS=OK ✅

===== OPS PROBE: nats varz =====
URL=http://127.0.0.1:8222/varz
http_code=200 time_total=0.003225 size=1699
nats varz STATUS=OK ✅

===== OPS PROBE: public root =====
URL=https://pix2pi.com.tr/
http_code=200 time_total=0.111524 size=10
public root STATUS=OK ✅

===== OPS PROBE: public pilot page =====
URL=https://pix2pi.com.tr/faz4d/pilot-go-live/
http_code=200 time_total=0.126117 size=8452
public pilot page STATUS=OK ✅

PASS_COUNT=9
WARN_COUNT=0
FAZ_6_11_OPS_CONSOLE_PROBE_STATUS=COMPLETE ✅
FAZ_6_11_OPS_CONSOLE_WARN_STATUS=CLEAR ✅
OK ✅ evidence yazildi: docs/faz6/evidence/FAZ_6_11_OPS_CONSOLE_PROBE_EVIDENCE.md
~~~

## 6-11.5 Runbook Template Check Probe

~~~text
===== PIX2PI RUNBOOK TEMPLATE CHECK BASLADI =====
incident_id alani var OK ✅
severity alani var OK ✅
priority alani var OK ✅
status alani var OK ✅
owner alani var OK ✅
affected_service alani var OK ✅
affected_tenant alani var OK ✅
customer impact var OK ✅
technical impact var OK ✅
first safe diagnostics var OK ✅
do not do var OK ✅
mitigation steps var OK ✅
recovery smoke var OK ✅
timeline var OK ✅
closure var OK ✅
ops console purpose var OK ✅
minimum cards var OK ✅
safe probe commands var OK ✅
status meaning var OK ✅
escalation var OK ✅
PASS_COUNT=20
FAIL_COUNT=0
FAZ_6_11_RUNBOOK_TEMPLATE_CHECK_STATUS=PASS ✅
~~~

## 6-11.6 Incident / Runbook Files Inventory

~~~text
docs/faz5/5_4_subscription_billing_payment_ops.md
docs/faz5/5_5_tenant_lifecycle_commercial_ops.md
docs/faz5/5_7_support_sla_incident_escalation.md
docs/faz6/checkpoints/FAZ_6_11_OPS_VISIBLE_CHECKPOINTS.md
docs/faz6/checkpoints/FAZ_6_11_OPS_VISIBLE_CHECKPOINTS.md
docs/faz6/evidence/FAZ_6_11_OPS_CONSOLE_PROBE_EVIDENCE.md
docs/faz6/evidence/FAZ_6_11_OPS_CONSOLE_PROBE_EVIDENCE.md
docs/faz6/evidence/FAZ_6_11_OPS_RUNTIME_AUDIT.md
docs/faz6/evidence/FAZ_6_11_OPS_RUNTIME_AUDIT.md
docs/faz6/evidence/FAZ_6_11_RUNBOOK_TEMPLATE_CHECK_EVIDENCE.md
docs/faz6/evidence/FAZ_6_11_RUNBOOK_TEMPLATE_CHECK_EVIDENCE.md
docs/faz6/FAZ_6_11_OPS_CONSOLE_INCIDENT_RUNBOOK_READINESS.md
docs/faz6/FAZ_6_11_OPS_CONSOLE_INCIDENT_RUNBOOK_READINESS.md
docs/faz6/FAZ_6_2_DB_L8_HA_SCALE_OPS_READINESS.md
docs/faz6/FAZ_6_2_DB_L8_HA_SCALE_OPS_READINESS.md
docs/faz6/FAZ_6_4_EVENT_BUS_QUEUE_BACKLOG_SRE_READINESS.md
docs/faz6/FAZ_6_4_EVENT_BUS_QUEUE_BACKLOG_SRE_READINESS.md
docs/faz6/FAZ_6_5_OBSERVABILITY_EARLY_WARNING_SRE_DASHBOARD.md
docs/faz6/FAZ_6_5_OBSERVABILITY_EARLY_WARNING_SRE_DASHBOARD.md
docs/faz6/runbooks/FAZ_6_11_INCIDENT_RUNBOOK_TEMPLATE.md
docs/faz6/runbooks/FAZ_6_11_INCIDENT_RUNBOOK_TEMPLATE.md
docs/faz6/runbooks/FAZ_6_11_OPS_CONSOLE_RUNBOOK.md
docs/faz6/runbooks/FAZ_6_11_OPS_CONSOLE_RUNBOOK.md
docs/infra/lvl10_edge_security_and_cert_ops.md
docs/infra/lvl10_ops_validation_and_phase_closure.md
docs/phase4/14_5_4_db_operations_runbook.md
docs/phase4/14_5_4_db_runbook_incident_checklist_report.md
docs/phase4/14_5_4_db_runbook_incident_checklist_standard.md
docs/phase4/16_5_support_incident_gate.tsv
docs/phase4/22_1_observability_alert_readiness.tsv
docs/phase4/22_5_alert_escalation_matrix.tsv
docs/phase4/22_5_alert_rule_catalog_matrix.tsv
docs/phase4/22_5_alert_rule_catalog_policy.md
docs/phase4/22_5_alert_rule_catalog_report.md
docs/phase4/22_5_alert_rule_catalog_standard.md
docs/phase4/22_5_alert_rule_catalog.tsv
docs/phase4/22_5_alert_severity_matrix.tsv
docs/phase4/22_5_alert_signal_mapping.tsv
docs/phase4/22_6_ops_console_alert_binding.tsv
docs/phase4/22_6_ops_console_api_contract.tsv
docs/phase4/22_6_ops_console_runbook_binding.tsv
docs/phase4/22_6_ops_console_signal_contract_matrix.tsv
docs/phase4/22_6_ops_console_signal_contract_policy.md
docs/phase4/22_6_ops_console_signal_contract_report.md
docs/phase4/22_6_ops_console_signal_contract_standard.md
docs/phase4/22_6_ops_console_signal_contract.tsv
docs/phase4/22_6_ops_console_widget_contract.tsv
docs/phase4/22_7_observability_ops_console_tests_inventory.tsv
docs/phase4/22_7_observability_ops_console_tests_matrix.tsv
docs/phase4/22_7_observability_ops_console_tests_report.md
docs/phase4/22_7_observability_ops_console_tests_standard.md
docs/phase4/22_8_observability_ops_console_final_closure_inventory.tsv
docs/phase4/22_8_observability_ops_console_final_closure_matrix.tsv
docs/phase4/22_8_observability_ops_console_final_closure_report.md
docs/phase4/22_8_observability_ops_console_final_closure_standard.md
docs/phase4/22_observability_ops_console_final_closure_report.md
docs/pilot/faz4c/4c_7b_warning_burndown_classification.md
~~~

## 6-11.7 Logs Incident Signal Inventory

~~~text
===== /var/log/nginx/error.log =====
===== /var/log/nginx/access.log =====
===== /var/log/fail2ban.log =====
2026-05-01 10:22:04,870 fail2ban.filter         [1700080]: INFO    [sshd] Found 203.145.143.163 - 2026-05-01 10:22:04
2026-05-01 10:24:10,104 fail2ban.filter         [1700080]: INFO    [sshd] Found 203.145.143.163 - 2026-05-01 10:24:09
2026-05-01 10:26:07,620 fail2ban.filter         [1700080]: INFO    [sshd] Found 45.148.10.121 - 2026-05-01 10:26:07
2026-05-01 10:26:11,370 fail2ban.filter         [1700080]: INFO    [sshd] Found 203.145.143.163 - 2026-05-01 10:26:10
2026-05-01 10:28:07,370 fail2ban.filter         [1700080]: INFO    [sshd] Found 203.145.143.163 - 2026-05-01 10:28:07
2026-05-01 10:28:07,409 fail2ban.actions        [1700080]: NOTICE  [sshd] Ban 203.145.143.163
2026-05-01 10:29:06,120 fail2ban.filter         [1700080]: INFO    [sshd] Found 45.148.10.183 - 2026-05-01 10:29:05
2026-05-01 10:30:12,870 fail2ban.filter         [1700080]: INFO    [sshd] Found 203.145.143.163 - 2026-05-01 10:30:12
2026-05-01 10:31:18,370 fail2ban.filter         [1700080]: INFO    [sshd] Found 45.148.10.183 - 2026-05-01 10:31:18
2026-05-01 10:32:18,870 fail2ban.filter         [1700080]: INFO    [sshd] Found 203.145.143.163 - 2026-05-01 10:32:18
2026-05-01 10:33:24,120 fail2ban.filter         [1700080]: INFO    [sshd] Found 45.148.10.183 - 2026-05-01 10:33:23
2026-05-01 10:34:22,290 fail2ban.filter         [1700080]: INFO    [sshd] Found 203.145.143.163 - 2026-05-01 10:34:22
2026-05-01 10:35:28,870 fail2ban.filter         [1700080]: INFO    [sshd] Found 45.148.10.183 - 2026-05-01 10:35:28
2026-05-01 10:37:32,620 fail2ban.filter         [1700080]: INFO    [sshd] Found 45.148.10.183 - 2026-05-01 10:37:32
2026-05-01 10:37:32,732 fail2ban.actions        [1700080]: NOTICE  [sshd] Ban 45.148.10.183
2026-05-01 10:38:33,870 fail2ban.filter         [1700080]: INFO    [sshd] Found 203.145.143.163 - 2026-05-01 10:38:33
2026-05-01 10:40:31,620 fail2ban.filter         [1700080]: INFO    [sshd] Found 203.145.143.163 - 2026-05-01 10:40:31
2026-05-01 10:40:32,181 fail2ban.actions        [1700080]: WARNING [sshd] 203.145.143.163 already banned
2026-05-01 10:41:29,620 fail2ban.filter         [1700080]: INFO    [sshd] Found 45.148.10.183 - 2026-05-01 10:41:29
2026-05-01 10:42:31,620 fail2ban.filter         [1700080]: INFO    [sshd] Found 203.145.143.163 - 2026-05-01 10:42:31
2026-05-01 10:44:32,620 fail2ban.filter         [1700080]: INFO    [sshd] Found 203.145.143.163 - 2026-05-01 10:44:32
2026-05-01 10:46:34,870 fail2ban.filter         [1700080]: INFO    [sshd] Found 203.145.143.163 - 2026-05-01 10:46:34
2026-05-01 10:48:40,870 fail2ban.filter         [1700080]: INFO    [sshd] Found 203.145.143.163 - 2026-05-01 10:48:40
2026-05-01 10:50:47,370 fail2ban.filter         [1700080]: INFO    [sshd] Found 203.145.143.163 - 2026-05-01 10:50:46
2026-05-01 10:50:47,564 fail2ban.actions        [1700080]: WARNING [sshd] 203.145.143.163 already banned
2026-05-01 10:52:44,370 fail2ban.filter         [1700080]: INFO    [sshd] Found 203.145.143.163 - 2026-05-01 10:52:44
2026-05-01 10:54:45,870 fail2ban.filter         [1700080]: INFO    [sshd] Found 203.145.143.163 - 2026-05-01 10:54:45
2026-05-01 10:57:09,236 fail2ban.filter         [1700080]: INFO    [sshd] Found 45.148.10.121 - 2026-05-01 10:57:09
2026-05-01 10:58:52,370 fail2ban.filter         [1700080]: INFO    [sshd] Found 203.145.143.163 - 2026-05-01 10:58:52
2026-05-01 11:00:55,870 fail2ban.filter         [1700080]: INFO    [sshd] Found 203.145.143.163 - 2026-05-01 11:00:55
2026-05-01 11:03:03,120 fail2ban.filter         [1700080]: INFO    [sshd] Found 203.145.143.163 - 2026-05-01 11:03:02
2026-05-01 11:03:03,123 fail2ban.actions        [1700080]: WARNING [sshd] 203.145.143.163 already banned
2026-05-01 11:05:07,371 fail2ban.filter         [1700080]: INFO    [sshd] Found 203.145.143.163 - 2026-05-01 11:05:07
2026-05-01 11:07:07,035 fail2ban.filter         [1700080]: INFO    [sshd] Found 141.11.21.145 - 2026-05-01 11:07:07
2026-05-01 11:09:14,870 fail2ban.filter         [1700080]: INFO    [sshd] Found 203.145.143.163 - 2026-05-01 11:09:14
2026-05-01 11:11:18,120 fail2ban.filter         [1700080]: INFO    [sshd] Found 203.145.143.163 - 2026-05-01 11:11:17
2026-05-01 11:13:17,280 fail2ban.filter         [1700080]: INFO    [sshd] Found 203.145.143.163 - 2026-05-01 11:13:17
2026-05-01 11:15:23,620 fail2ban.filter         [1700080]: INFO    [sshd] Found 203.145.143.163 - 2026-05-01 11:15:23
2026-05-01 11:15:24,075 fail2ban.actions        [1700080]: WARNING [sshd] 203.145.143.163 already banned
2026-05-01 11:17:27,870 fail2ban.filter         [1700080]: INFO    [sshd] Found 203.145.143.163 - 2026-05-01 11:17:27
2026-05-01 11:35:54,656 fail2ban.filter         [1700080]: INFO    [sshd] Found 89.185.81.112 - 2026-05-01 11:35:53
2026-05-01 11:37:32,548 fail2ban.actions        [1700080]: NOTICE  [sshd] Unban 45.148.10.183
2026-05-01 11:42:52,878 fail2ban.filter         [1700080]: INFO    [sshd] Found 89.185.81.112 - 2026-05-01 11:42:51
2026-05-01 11:51:04,741 fail2ban.filter         [1700080]: INFO    [sshd] Found 194.87.216.198 - 2026-05-01 11:51:03
2026-05-01 11:58:53,112 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 11:58:52
2026-05-01 12:05:52,151 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:05:51
2026-05-01 12:07:47,530 fail2ban.filter         [1700080]: INFO    [sshd] Found 194.87.216.198 - 2026-05-01 12:07:47
2026-05-01 12:07:54,290 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:07:53
2026-05-01 12:09:50,774 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:09:50
2026-05-01 12:11:43,215 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:11:42
2026-05-01 12:13:36,530 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:13:36
2026-05-01 12:15:23,370 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:15:23
2026-05-01 12:15:23,461 fail2ban.actions        [1700080]: NOTICE  [sshd] Unban 203.145.143.163
2026-05-01 12:17:10,870 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:17:10
2026-05-01 12:19:06,120 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:19:05
2026-05-01 12:21:02,620 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:21:02
2026-05-01 12:21:17,370 fail2ban.filter         [1700080]: INFO    [sshd] Found 45.156.87.253 - 2026-05-01 12:21:17
2026-05-01 12:22:56,244 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:22:55
2026-05-01 12:25:02,791 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:25:02
2026-05-01 12:26:56,870 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:26:56
2026-05-01 12:30:40,620 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:30:40
2026-05-01 12:30:42,120 fail2ban.filter         [1700080]: INFO    [sshd] Found 89.185.81.112 - 2026-05-01 12:30:41
2026-05-01 12:32:37,846 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:32:37
2026-05-01 12:34:27,504 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:34:27
2026-05-01 12:36:22,870 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:36:22
2026-05-01 12:37:36,620 fail2ban.filter         [1700080]: INFO    [sshd] Found 89.185.81.112 - 2026-05-01 12:37:36
2026-05-01 12:38:23,825 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:38:23
2026-05-01 12:40:18,870 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:40:18
2026-05-01 12:42:08,620 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:42:08
2026-05-01 12:44:06,120 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:44:05
2026-05-01 12:45:59,870 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:45:59
2026-05-01 12:47:50,941 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:47:50
2026-05-01 12:49:47,620 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:49:47
2026-05-01 12:51:47,120 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:51:46
2026-05-01 12:53:42,249 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:53:41
2026-05-01 12:55:38,855 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:55:38
2026-05-01 12:57:35,370 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:57:35
2026-05-01 12:59:29,870 fail2ban.filter         [1700080]: INFO    [sshd] Found 101.47.159.50 - 2026-05-01 12:59:29
2026-05-01 14:29:48,201 fail2ban.filter         [1700080]: INFO    [sshd] Found 141.11.21.145 - 2026-05-01 14:29:47
2026-05-01 14:47:00,151 fail2ban.filter         [1700080]: INFO    [sshd] Found 193.24.211.95 - 2026-05-01 14:46:59
===== /var/log/auth.log =====
Apr 26 15:37:50 vm12827 sshd[3740825]: error: kex_exchange_identification: Connection closed by remote host
Apr 26 16:47:14 vm12827 sshd[3780550]: error: kex_exchange_identification: Connection closed by remote host
Apr 26 16:53:43 vm12827 sshd[3784234]: error: kex_exchange_identification: banner line contains invalid characters
Apr 26 17:57:26 vm12827 sshd[3820385]: error: kex_exchange_identification: read: Connection reset by peer
Apr 26 23:24:43 vm12827 sshd[4024655]: error: kex_exchange_identification: read: Connection reset by peer
Apr 27 00:22:59 vm12827 sshd[4101113]: error: kex_exchange_identification: read: Connection reset by peer
Apr 27 01:16:47 vm12827 sshd[4133299]: error: kex_exchange_identification: Connection closed by remote host
Apr 27 07:17:02 vm12827 sshd[146341]: error: kex_exchange_identification: Connection closed by remote host
Apr 27 07:17:19 vm12827 sshd[146620]: error: Protocol major versions differ: 2 vs. 1
Apr 27 07:37:02 vm12827 sshd[158768]: error: kex_exchange_identification: banner line contains invalid characters
Apr 27 07:50:00 vm12827 sshd[168714]: error: kex_exchange_identification: read: Connection reset by peer
Apr 27 08:19:29 vm12827 sshd[246793]: error: kex_exchange_identification: Connection closed by remote host
Apr 27 08:43:41 vm12827 sshd[363827]: error: kex_exchange_identification: banner line contains invalid characters
Apr 27 09:47:32 vm12827 sshd[400082]: Invalid user shutdown from 87.251.64.149 port 2810
Apr 27 09:47:32 vm12827 sshd[400082]: Connection reset by invalid user shutdown 87.251.64.149 port 2810 [preauth]
Apr 27 16:30:04 vm12827 sshd[1290412]: error: kex_exchange_identification: Connection closed by remote host
Apr 27 18:12:11 vm12827 sshd[1358418]: error: kex_exchange_identification: Connection closed by remote host
Apr 27 18:12:32 vm12827 sshd[1358594]: error: kex_exchange_identification: Connection closed by remote host
Apr 27 21:12:47 vm12827 sshd[1469719]: error: kex_exchange_identification: Connection closed by remote host
Apr 27 22:54:00 vm12827 sshd[1527094]: error: kex_exchange_identification: banner line contains invalid characters
Apr 27 23:01:08 vm12827 sshd[1531196]: error: kex_exchange_identification: Connection closed by remote host
Apr 28 02:53:59 vm12827 sshd[1665346]: error: kex_exchange_identification: Connection closed by remote host
Apr 28 04:23:26 vm12827 sshd[1716275]: error: kex_exchange_identification: Connection closed by remote host
Apr 28 07:08:32 vm12827 sshd[1810097]: error: kex_exchange_identification: Connection closed by remote host
Apr 28 07:57:30 vm12827 sshd[1838385]: error: kex_exchange_identification: banner line contains invalid characters
Apr 28 08:06:02 vm12827 sshd[1843438]: error: kex_exchange_identification: client sent invalid protocol identifier "GET /..%2F..%2F..%2F..%2F..%2F..%2Fetc%2Fpasswd HTTP/1.1"
Apr 28 10:09:27 vm12827 sshd[1914707]: error: kex_exchange_identification: Connection closed by remote host
Apr 28 11:11:31 vm12827 sshd[1950846]: error: kex_exchange_identification: Connection closed by remote host
Apr 28 11:36:36 vm12827 sshd[1965050]: error: kex_exchange_identification: Connection closed by remote host
Apr 28 11:41:12 vm12827 sshd[1967719]: error: kex_exchange_identification: Connection closed by remote host
Apr 28 13:18:47 vm12827 sshd[2022985]: error: kex_exchange_identification: read: Connection reset by peer
Apr 28 18:00:58 vm12827 sshd[2182898]: error: kex_exchange_identification: read: Connection reset by peer
Apr 28 18:59:11 vm12827 sshd[2216931]: error: kex_exchange_identification: banner line contains invalid characters
Apr 28 22:42:25 vm12827 sshd[2343609]: error: kex_exchange_identification: Connection closed by remote host
Apr 28 23:12:49 vm12827 sshd[2360809]: error: kex_exchange_identification: read: Connection reset by peer
Apr 29 02:25:47 vm12827 sshd[2471110]: error: kex_exchange_identification: Connection closed by remote host
Apr 29 05:19:53 vm12827 sshd[2569830]: error: kex_exchange_identification: Connection closed by remote host
Apr 29 05:27:59 vm12827 sshd[2574380]: error: kex_exchange_identification: Connection closed by remote host
Apr 29 07:35:19 vm12827 sshd[2648251]: error: kex_exchange_identification: Connection closed by remote host
Apr 29 07:35:52 vm12827 sshd[2648613]: error: Protocol major versions differ: 2 vs. 1
Apr 29 08:58:06 vm12827 sshd[2696218]: error: kex_exchange_identification: banner line contains invalid characters
Apr 29 13:20:46 vm12827 sshd[2848600]: error: kex_exchange_identification: banner line contains invalid characters
Apr 29 13:20:46 vm12827 sshd[2848601]: error: kex_exchange_identification: banner line contains invalid characters
Apr 29 13:55:42 vm12827 sshd[2868445]: error: kex_exchange_identification: Connection closed by remote host
Apr 29 17:35:01 vm12827 sshd[2992766]: error: kex_exchange_identification: Connection closed by remote host
Apr 29 18:33:24 vm12827 sshd[3025940]: error: kex_exchange_identification: Connection closed by remote host
Apr 29 19:08:25 vm12827 sshd[3046185]: error: kex_exchange_identification: banner line contains invalid characters
Apr 29 19:08:59 vm12827 sshd[3046460]: error: kex_exchange_identification: banner line contains invalid characters
Apr 30 00:08:18 vm12827 sshd[3219053]: error: kex_exchange_identification: Connection closed by remote host
Apr 30 02:31:56 vm12827 sshd[3300982]: error: kex_exchange_identification: banner line contains invalid characters
Apr 30 03:51:05 vm12827 sshd[3346105]: error: kex_exchange_identification: Connection closed by remote host
Apr 30 04:11:13 vm12827 sshd[3357486]: error: kex_exchange_identification: Connection closed by remote host
Apr 30 06:20:31 vm12827 sshd[3431728]: error: kex_exchange_identification: banner line contains invalid characters
Apr 30 06:49:30 vm12827 sshd[3448642]: error: kex_exchange_identification: Connection closed by remote host
Apr 30 09:43:20 vm12827 sshd[3547845]: error: kex_exchange_identification: read: Connection reset by peer
Apr 30 10:06:38 vm12827 sshd[3561087]: error: kex_exchange_identification: Connection closed by remote host
Apr 30 11:16:51 vm12827 sshd[3600862]: error: kex_exchange_identification: Connection closed by remote host
Apr 30 11:17:01 vm12827 sshd[3600866]: error: kex_exchange_identification: Connection closed by remote host
Apr 30 11:17:15 vm12827 sshd[3601146]: error: kex_exchange_identification: banner line contains invalid characters
Apr 30 11:17:18 vm12827 sshd[3601147]: error: kex_exchange_identification: Connection closed by remote host
Apr 30 11:41:45 vm12827 sshd[3615005]: error: kex_exchange_identification: Connection closed by remote host
Apr 30 15:33:14 vm12827 sshd[3746031]: error: kex_exchange_identification: read: Connection reset by peer
Apr 30 16:01:03 vm12827 sshd[3761852]: error: kex_exchange_identification: Connection closed by remote host
Apr 30 16:37:48 vm12827 sshd[3782477]: error: kex_exchange_identification: read: Connection reset by peer
Apr 30 16:37:53 vm12827 sshd[3782510]: error: kex_exchange_identification: read: Connection reset by peer
Apr 30 22:36:56 vm12827 sshd[3986902]: error: kex_exchange_identification: banner line contains invalid characters
Apr 30 22:55:57 vm12827 sshd[3997659]: error: kex_exchange_identification: read: Connection reset by peer
May  1 00:24:00 vm12827 sshd[4047661]: error: kex_exchange_identification: Connection closed by remote host
May  1 01:35:38 vm12827 sshd[4088205]: error: kex_exchange_identification: Connection closed by remote host
May  1 04:28:36 vm12827 sshd[4186636]: error: kex_exchange_identification: Connection closed by remote host
May  1 05:47:12 vm12827 sshd[37917]: error: kex_exchange_identification: Connection closed by remote host
May  1 05:47:29 vm12827 sshd[38048]: error: Protocol major versions differ: 2 vs. 1
May  1 06:32:35 vm12827 sshd[74954]: error: kex_exchange_identification: Connection closed by remote host
May  1 07:51:25 vm12827 sshd[124968]: error: kex_exchange_identification: Connection closed by remote host
May  1 09:13:11 vm12827 sshd[175051]: error: kex_exchange_identification: Connection closed by remote host
May  1 10:26:36 vm12827 sshd[217673]: error: kex_exchange_identification: Connection closed by remote host
May  1 11:07:06 vm12827 sshd[241318]: error: kex_exchange_identification: Connection closed by remote host
May  1 14:29:47 vm12827 sshd[450512]: error: kex_exchange_identification: Connection closed by remote host
May  1 14:39:09 vm12827 sshd[542966]: error: kex_exchange_identification: Connection closed by remote host
May  1 14:48:36 vm12827 sshd[717649]: error: kex_exchange_identification: read: Connection reset by peer
WARN missing /var/log/pix2pi/audit.log
WARN missing /var/log/pix2pi/security.log
~~~

## 6-11.8 Observability / Alert Inventory

~~~text
./install_phase1_scaffold.sh:49:CREATE TYPE auth.break_glass_reason AS ENUM ('incident_response', 'security_investigation', 'data_recovery', 'support_exception');
./install_phase1_scaffold.sh:794:  const [route, setRoute] = useState('dashboard');
./install_phase1_scaffold.sh:820:      {route === 'dashboard' ? <DashboardPage /> : null}
./install_phase1_scaffold.sh:856:type DataTableProps<T extends Record<string, string>> = {
./install_phase1_scaffold.sh:864:export function DataTable<T extends Record<string, string>>({ title, rows, columns }: DataTableProps<T>) {
./install_phase1_scaffold.sh:1216:type AppShellProps = {
./install_phase1_scaffold.sh:1223:  { key: 'dashboard', label: 'Panel', requiredRole: null },
./install_phase1_scaffold.sh:1229:export function AppShell({ activeRoute, onNavigate, children }: AppShellProps) {
./install_phase1_scaffold.sh:1457:  --color-warning: #f5b400;
./install_phase1_scaffold.sh:1753:      <AppShell activeRoute="dashboard" onNavigate={() => undefined}>
./install_phase1_scaffold.sh:1766:      <AppShell activeRoute="dashboard" onNavigate={() => undefined}>
./grafana/dashboards/docker-monitoring.json:8:      "pluginId": "prometheus",
./grafana/dashboards/docker-monitoring.json:26:      "type": "grafana",
./grafana/dashboards/docker-monitoring.json:27:      "id": "grafana",
./grafana/dashboards/docker-monitoring.json:33:      "id": "prometheus",
./grafana/dashboards/docker-monitoring.json:649:            "{id=\"/\",instance=\"cadvisor:8080\",job=\"prometheus\"}": "#BA43A9"
./grafana/dashboards/docker-monitoring.json:838:              "colorMode": "critical",
./grafana/dashboards/docker-monitoring.json:962:              "colorMode": "critical",
./grafana/dashboards/docker-monitoring.json:1204:              "colorMode": "critical",
./grafana/dashboards/node-exporter-full.json:8:      "pluginId": "prometheus",
./grafana/dashboards/node-exporter-full.json:27:      "type": "grafana",
./grafana/dashboards/node-exporter-full.json:28:      "id": "grafana",
./grafana/dashboards/node-exporter-full.json:34:      "id": "prometheus",
./grafana/dashboards/node-exporter-full.json:58:          "uid": "grafana"
./grafana/dashboards/node-exporter-full.json:68:          "type": "dashboard"
./grafana/dashboards/node-exporter-full.json:70:        "type": "dashboard"
./grafana/dashboards/node-exporter-full.json:86:      "url": "https://github.com/rfmoz/grafana-dashboards"
./grafana/dashboards/node-exporter-full.json:94:      "url": "https://grafana.com/grafana/dashboards/1860"
./grafana/dashboards/node-exporter-full.json:102:        "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:116:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:127:        "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:189:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:205:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:222:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:243:        "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:311:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:331:        "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:399:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:419:        "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:478:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:494:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:514:        "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:582:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:600:        "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:668:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:687:        "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:751:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:768:        "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:834:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:852:        "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:921:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:941:        "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:1006:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:1024:        "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:1089:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:1108:        "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:1122:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:1133:        "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:1323:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:1340:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:1355:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:1369:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:1383:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:1397:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:1415:        "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:1867:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:1880:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:1893:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:1905:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:1917:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:1933:        "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:2373:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:2385:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:2401:        "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:2485:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:2502:        "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:2515:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:2724:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:2739:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:2753:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:2767:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:2781:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:2795:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:2809:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:2823:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:2842:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:3231:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:3244:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:3257:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:3269:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:3282:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:3295:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:3308:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:3321:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:3334:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:3351:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:3509:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:3521:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:3537:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:3624:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:3640:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:3693:              "unit": "iops"
./grafana/dashboards/node-exporter-full.json:4054:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:4065:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:4080:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:4281:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:4294:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:4311:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:4426:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:4444:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:4558:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:4570:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:4588:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:4600:        "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:4613:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:4956:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:4968:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:4984:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:5346:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:5358:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:5374:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:5717:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:5730:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:5743:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:5756:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:5773:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:6145:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:6157:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:6169:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:6185:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:6552:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:6564:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:6576:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:6589:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:6606:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:6978:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:6990:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:7006:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:7363:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:7376:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:7389:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:7406:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:7749:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:7765:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:8134:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:8146:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:8162:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:8505:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:8517:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:8534:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:8890:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:8902:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:8914:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:8930:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:9286:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:9298:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:9314:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:9670:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:9682:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:9695:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:9712:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:10055:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:10067:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:10083:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:10455:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:10473:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:10485:        "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:10498:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:10596:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:10608:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:10624:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:10722:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:10734:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:10750:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:11112:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:11124:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:11136:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:11152:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:11524:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:11543:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:11555:        "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:11568:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:11670:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:11684:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:11698:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:11716:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:11802:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:11819:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:11921:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:11934:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:11951:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:12037:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:12050:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:12069:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:12081:        "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:12094:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:12180:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:12192:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:12208:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:12295:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:12312:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:12398:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:12415:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:12514:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:12527:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:12540:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:12553:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:12570:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:12677:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:12690:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:12707:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:12805:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:12818:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:12835:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:12942:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:12955:                "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:12974:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:12986:        "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:12999:            "type": "prometheus",
./grafana/dashboards/node-exporter-full.json:13085:                "type": "prometheus",
~~~

## 6-11.9 Runtime Audit Interpretation

~~~text
6-11.1 Host inventory collected OK ✅
6-11.2 Docker services snapshot collected OK ✅
6-11.3 Systemd services snapshot collected OK ✅
6-11.4 Health/metrics probe collected OK ✅
6-11.5 Runbook template check collected OK ✅
6-11.6 Incident/runbook files inventory collected OK ✅
6-11.7 Logs incident signal inventory collected OK ✅
6-11.8 Observability/alert inventory collected OK ✅
FAZ_6_11_RUNTIME_AUDIT=COMPLETE ✅
~~~
