# FAZ 6-11 Ops Console Probe Evidence

Generated At: 2026-05-01T16:13:32+03:00  
Repo: /root/pix2pi/pix2pi-SaaS  

Bu script servisleri restart etmez, config degistirmez, incident acmaz.
Sadece ops console icin health/dependency evidence uretir.

FAZ_6_11_OPS_CONSOLE_PROBE=STARTED ✅

---

===== OPS PROBE: identity-api health =====
URL=http://127.0.0.1:9002/health
http_code=200 time_total=0.001894 size=33
identity-api health STATUS=OK ✅

===== OPS PROBE: api-gateway health =====
URL=http://127.0.0.1:9010/health
http_code=200 time_total=0.000926 size=21
api-gateway health STATUS=OK ✅

===== OPS PROBE: prometheus ready =====
URL=http://127.0.0.1:9090/-/ready
http_code=200 time_total=0.002112 size=28
prometheus ready STATUS=OK ✅

===== OPS PROBE: grafana health =====
URL=http://127.0.0.1:3001/api/health
http_code=200 time_total=0.001653 size=101
grafana health STATUS=OK ✅

===== OPS PROBE: node_exporter metrics =====
URL=http://127.0.0.1:9100/metrics
http_code=200 time_total=0.021695 size=73790
node_exporter metrics STATUS=OK ✅

===== OPS PROBE: cadvisor metrics =====
URL=http://127.0.0.1:8080/metrics
http_code=200 time_total=0.286096 size=7731264
cadvisor metrics STATUS=OK ✅

===== OPS PROBE: nats varz =====
URL=http://127.0.0.1:8222/varz
http_code=200 time_total=0.003251 size=1699
nats varz STATUS=OK ✅

===== OPS PROBE: public root =====
URL=https://pix2pi.com.tr/
http_code=200 time_total=0.110779 size=10
public root STATUS=OK ✅

===== OPS PROBE: public pilot page =====
URL=https://pix2pi.com.tr/faz4d/pilot-go-live/
http_code=200 time_total=0.091741 size=8452
public pilot page STATUS=OK ✅


## Docker Runtime Snapshot

~~~text
NAMES                     STATUS                PORTS
pix2pi_nats               Up 50 minutes         0.0.0.0:4222->4222/tcp, [::]:4222->4222/tcp, 0.0.0.0:8222->8222/tcp, [::]:8222->8222/tcp, 6222/tcp
pix2pi-redis              Up 9 days             0.0.0.0:6379->6379/tcp, [::]:6379->6379/tcp
pix2pi_pg_replica         Up 9 days             0.0.0.0:5434->5432/tcp, [::]:5434->5432/tcp
pix2pi-mission-control    Up 9 days             9001/tcp, 0.0.0.0:9101->5860/tcp, [::]:9101->5860/tcp
pix2pi-service-registry   Up 9 days             
pix2pi-identity-api       Up 9 days             0.0.0.0:9002->9002/tcp, [::]:9002->9002/tcp
pix2pi_grafana            Up 9 days             0.0.0.0:3001->3000/tcp, [::]:3001->3000/tcp
pix2pi_promtail           Up 9 days             
pix2pi_loki               Up 9 days             0.0.0.0:3100->3100/tcp, [::]:3100->3100/tcp
pix2pi_prometheus         Up 9 days             0.0.0.0:9090->9090/tcp, [::]:9090->9090/tcp
pix2pi_node_exporter      Up 9 days             0.0.0.0:9100->9100/tcp, [::]:9100->9100/tcp
pix2pi_tempo              Up 9 days             0.0.0.0:3200->3200/tcp, [::]:3200->3200/tcp, 0.0.0.0:4317-4318->4317-4318/tcp, [::]:4317-4318->4317-4318/tcp
pix2pi-api-gateway        Up 9 days (healthy)   
pix2pi_pg                 Up 4 days             0.0.0.0:5433->5432/tcp, [::]:5433->5432/tcp
pix2pi_cadvisor           Up 9 days (healthy)   0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp
~~~

## Systemd Runtime Snapshot

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

## Ops Console Probe Final Seal

~~~text
PASS_COUNT=9
WARN_COUNT=0
FAZ_6_11_OPS_CONSOLE_PROBE_STATUS=COMPLETE ✅
FAZ_6_11_OPS_CONSOLE_WARN_STATUS=CLEAR ✅
~~~
