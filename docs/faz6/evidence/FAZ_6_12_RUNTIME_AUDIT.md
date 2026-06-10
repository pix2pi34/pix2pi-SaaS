# FAZ 6-12 Runtime Audit Evidence

Generated At: 2026-05-01T16:13:28+03:00  
Host: vm12827.ovadns.com  
Repo: /root/pix2pi/pix2pi-SaaS  

Bu audit final production readiness gate icin runtime snapshot toplar.
Degisiklik yapmaz.

FAZ_6_12_RUNTIME_AUDIT=STARTED ✅

---


## 6-12.1 Host / Kernel

~~~text
Linux vm12827.ovadns.com 5.15.0-176-generic #186-Ubuntu SMP Fri Mar 13 11:01:42 UTC 2026 x86_64 x86_64 x86_64 GNU/Linux
~~~

## 6-12.2 Docker Services Snapshot

~~~text
NAMES                     IMAGE                             STATUS                PORTS
pix2pi_nats               nats:2.10-alpine                  Up 49 minutes         0.0.0.0:4222->4222/tcp, [::]:4222->4222/tcp, 0.0.0.0:8222->8222/tcp, [::]:8222->8222/tcp, 6222/tcp
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

## 6-12.3 Systemd / Nginx Snapshot

~~~text
active
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
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

## 6-12.4 Safe Service Smoke

~~~text
===== PIX2PI POSTDEPLOY SMOKE BASLADI =====
===== identity health =====
TRY_1=http://127.0.0.1:9002/health
http_code=200 time_total=0.001536 size=33
identity health OK ✅

===== api gateway health =====
TRY_1=http://127.0.0.1:9010/health
http_code=200 time_total=0.001251 size=21
api gateway health OK ✅

===== prometheus ready =====
TRY_1=http://127.0.0.1:9090/-/ready
http_code=200 time_total=0.002078 size=28
prometheus ready OK ✅

===== grafana health =====
TRY_1=http://127.0.0.1:3001/api/health
http_code=200 time_total=0.002243 size=101
grafana health OK ✅

===== node exporter metrics =====
TRY_1=http://127.0.0.1:9100/metrics
http_code=200 time_total=0.020868 size=73798
node exporter metrics OK ✅

===== cadvisor metrics =====
TRY_1=http://127.0.0.1:8080/metrics
http_code=200 time_total=0.268737 size=7731288
cadvisor metrics OK ✅

===== nats monitoring varz =====
TRY_1=http://127.0.0.1:8222/varz
http_code=200 time_total=0.003353 size=1700
nats monitoring varz OK ✅

PASS_COUNT=7
WARN_COUNT=0
FAZ_6_9_POSTDEPLOY_SMOKE_STATUS=COMPLETE ✅
POSTDEPLOY_DESTRUCTIVE_ACTION=NO ✅
FAZ_6_9_POSTDEPLOY_SMOKE_WARN_STATUS=CLEAR ✅
OK ✅ evidence yazildi: docs/faz6/evidence/FAZ_6_9_POSTDEPLOY_SMOKE_EVIDENCE.md
~~~

## 6-12.5 Edge Smoke

~~~text
===== PIX2PI EDGE HTTP SMOKE BASLADI =====
===== EDGE HTTP SMOKE: root https =====
URL=https://pix2pi.com.tr/
http_code=200 time_total=0.108249 size=10 remote_ip=141.98.48.42
--- headers first 100 lines ---
HTTP/2 200 
server: nginx/1.18.0 (Ubuntu)
date: Fri, 01 May 2026 13:13:29 GMT
content-type: application/octet-stream
content-length: 10
content-type: text/plain
x-content-type-options: nosniff
x-frame-options: SAMEORIGIN
referrer-policy: strict-origin-when-cross-origin
x-xss-protection: 0
permissions-policy: geolocation=(), microphone=(), camera=(), payment=(), usb=()
strict-transport-security: max-age=31536000; includeSubDomains
content-security-policy: default-src 'self'; base-uri 'self'; frame-ancestors 'self'; object-src 'none'; img-src 'self' data: https:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; connect-src 'self' https: wss:;
cache-control: public, max-age=300

--- body first 500 chars ---
Pix2pi OK

--- curl error if any ---
root https EDGE_HTTP_OK ✅
root https CLOUDFLARE_PROXY_HEADERS_NOT_EXPECTED_GRAY_CLOUD ℹ️
root https EDGE_SECURITY_HEADERS_PRESENT ✅
x-content-type-options: nosniff
x-frame-options: SAMEORIGIN
referrer-policy: strict-origin-when-cross-origin
permissions-policy: geolocation=(), microphone=(), camera=(), payment=(), usb=()
strict-transport-security: max-age=31536000; includeSubDomains
content-security-policy: default-src 'self'; base-uri 'self'; frame-ancestors 'self'; object-src 'none'; img-src 'self' data: https:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; connect-src 'self' https: wss:;
cache-control: public, max-age=300

===== EDGE HTTP SMOKE: https path / =====
URL=https://pix2pi.com.tr/
http_code=200 time_total=0.105694 size=10 remote_ip=141.98.48.42
--- headers first 100 lines ---
HTTP/2 200 
server: nginx/1.18.0 (Ubuntu)
date: Fri, 01 May 2026 13:13:29 GMT
content-type: application/octet-stream
content-length: 10
content-type: text/plain
x-content-type-options: nosniff
x-frame-options: SAMEORIGIN
referrer-policy: strict-origin-when-cross-origin
x-xss-protection: 0
permissions-policy: geolocation=(), microphone=(), camera=(), payment=(), usb=()
strict-transport-security: max-age=31536000; includeSubDomains
content-security-policy: default-src 'self'; base-uri 'self'; frame-ancestors 'self'; object-src 'none'; img-src 'self' data: https:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; connect-src 'self' https: wss:;
cache-control: public, max-age=300

--- body first 500 chars ---
Pix2pi OK

--- curl error if any ---
https path / EDGE_HTTP_OK ✅
https path / CLOUDFLARE_PROXY_HEADERS_NOT_EXPECTED_GRAY_CLOUD ℹ️
https path / EDGE_SECURITY_HEADERS_PRESENT ✅
x-content-type-options: nosniff
x-frame-options: SAMEORIGIN
referrer-policy: strict-origin-when-cross-origin
permissions-policy: geolocation=(), microphone=(), camera=(), payment=(), usb=()
strict-transport-security: max-age=31536000; includeSubDomains
content-security-policy: default-src 'self'; base-uri 'self'; frame-ancestors 'self'; object-src 'none'; img-src 'self' data: https:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; connect-src 'self' https: wss:;
cache-control: public, max-age=300

===== EDGE HTTP SMOKE: https path /faz4d/pilot-go-live/ =====
URL=https://pix2pi.com.tr/faz4d/pilot-go-live/
http_code=200 time_total=0.078470 size=8452 remote_ip=141.98.48.42
--- headers first 100 lines ---
HTTP/2 200 
server: nginx/1.18.0 (Ubuntu)
date: Fri, 01 May 2026 13:13:29 GMT
content-type: text/html
content-length: 8452
last-modified: Fri, 01 May 2026 07:31:54 GMT
etag: "69f456ea-2104"
x-content-type-options: nosniff
x-frame-options: SAMEORIGIN
referrer-policy: strict-origin-when-cross-origin
x-xss-protection: 0
permissions-policy: geolocation=(), microphone=(), camera=(), payment=(), usb=()
strict-transport-security: max-age=31536000; includeSubDomains
content-security-policy: default-src 'self'; base-uri 'self'; frame-ancestors 'self'; object-src 'none'; img-src 'self' data: https:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; connect-src 'self' https: wss:;
cache-control: public, max-age=300
accept-ranges: bytes

--- body first 500 chars ---
<!doctype html>
<html lang="tr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Pix2pi Controlled Pilot Go-Live</title>
  <style>
    :root {
      --bg: #07111f;
      --card: #101d31;
      --card-2: #152640;
      --text: #eef6ff;
      --muted: #a8b8cc;
      --line: rgba(255, 255, 255, 0.12);
      --accent: #41b8ff;
      --ok: #38d996;
      --warn: #ffcf5a;
      --danger: #ff7d7d;
    }

    * {
      box-sizing: border-bo
--- curl error if any ---
https path /faz4d/pilot-go-live/ EDGE_HTTP_OK ✅
https path /faz4d/pilot-go-live/ CLOUDFLARE_PROXY_HEADERS_NOT_EXPECTED_GRAY_CLOUD ℹ️
https path /faz4d/pilot-go-live/ EDGE_SECURITY_HEADERS_PRESENT ✅
x-content-type-options: nosniff
x-frame-options: SAMEORIGIN
referrer-policy: strict-origin-when-cross-origin
permissions-policy: geolocation=(), microphone=(), camera=(), payment=(), usb=()
strict-transport-security: max-age=31536000; includeSubDomains
content-security-policy: default-src 'self'; base-uri 'self'; frame-ancestors 'self'; object-src 'none'; img-src 'self' data: https:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; connect-src 'self' https: wss:;
cache-control: public, max-age=300

===== EDGE HTTP SMOKE: http redirect/root =====
URL=http://pix2pi.com.tr/
http_code=200 time_total=0.143099 size=10 remote_ip=141.98.48.42
--- headers first 100 lines ---
HTTP/1.1 301 Moved Permanently
Server: nginx/1.18.0 (Ubuntu)
Date: Fri, 01 May 2026 13:13:29 GMT
Content-Type: text/html
Content-Length: 178
Connection: keep-alive
Location: https://pix2pi.com.tr/
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
Referrer-Policy: strict-origin-when-cross-origin
X-XSS-Protection: 0
Permissions-Policy: geolocation=(), microphone=(), camera=(), payment=(), usb=()
Strict-Transport-Security: max-age=31536000; includeSubDomains
Content-Security-Policy: default-src 'self'; base-uri 'self'; frame-ancestors 'self'; object-src 'none'; img-src 'self' data: https:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; connect-src 'self' https: wss:;
Cache-Control: public, max-age=300

HTTP/2 200 
server: nginx/1.18.0 (Ubuntu)
date: Fri, 01 May 2026 13:13:29 GMT
content-type: application/octet-stream
content-length: 10
content-type: text/plain
x-content-type-options: nosniff
x-frame-options: SAMEORIGIN
referrer-policy: strict-origin-when-cross-origin
x-xss-protection: 0
permissions-policy: geolocation=(), microphone=(), camera=(), payment=(), usb=()
strict-transport-security: max-age=31536000; includeSubDomains
content-security-policy: default-src 'self'; base-uri 'self'; frame-ancestors 'self'; object-src 'none'; img-src 'self' data: https:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; connect-src 'self' https: wss:;
cache-control: public, max-age=300

--- body first 500 chars ---
Pix2pi OK

--- curl error if any ---
http redirect/root EDGE_HTTP_OK ✅
http redirect/root CLOUDFLARE_PROXY_HEADERS_NOT_EXPECTED_GRAY_CLOUD ℹ️
http redirect/root EDGE_SECURITY_HEADERS_PRESENT ✅
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: geolocation=(), microphone=(), camera=(), payment=(), usb=()
Strict-Transport-Security: max-age=31536000; includeSubDomains
Content-Security-Policy: default-src 'self'; base-uri 'self'; frame-ancestors 'self'; object-src 'none'; img-src 'self' data: https:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; connect-src 'self' https: wss:;
Cache-Control: public, max-age=300
x-content-type-options: nosniff
x-frame-options: SAMEORIGIN
referrer-policy: strict-origin-when-cross-origin
permissions-policy: geolocation=(), microphone=(), camera=(), payment=(), usb=()
strict-transport-security: max-age=31536000; includeSubDomains
content-security-policy: default-src 'self'; base-uri 'self'; frame-ancestors 'self'; object-src 'none'; img-src 'self' data: https:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; connect-src 'self' https: wss:;
cache-control: public, max-age=300

PASS_COUNT=8
WARN_COUNT=0
INFO_COUNT=4
FAZ_6_10_EDGE_HTTP_SMOKE_STATUS=COMPLETE ✅
FAZ_6_10_CLOUDFLARE_PROXY_STATUS=DISABLED_OR_NOT_DETECTED_INFO ✅
FAZ_6_10_EDGE_HTTP_WARN_STATUS=CLEAR ✅
OK ✅ evidence yazildi: docs/faz6/evidence/FAZ_6_10_EDGE_HTTP_SMOKE_EVIDENCE.md
~~~

## 6-12.6 Ops Console Probe

~~~text
===== PIX2PI OPS CONSOLE PROBE BASLADI =====
===== OPS PROBE: identity-api health =====
URL=http://127.0.0.1:9002/health
http_code=200 time_total=0.001553 size=33
identity-api health STATUS=OK ✅

===== OPS PROBE: api-gateway health =====
URL=http://127.0.0.1:9010/health
http_code=200 time_total=0.001177 size=21
api-gateway health STATUS=OK ✅

===== OPS PROBE: prometheus ready =====
URL=http://127.0.0.1:9090/-/ready
http_code=200 time_total=0.001960 size=28
prometheus ready STATUS=OK ✅

===== OPS PROBE: grafana health =====
URL=http://127.0.0.1:3001/api/health
http_code=200 time_total=0.001711 size=101
grafana health STATUS=OK ✅

===== OPS PROBE: node_exporter metrics =====
URL=http://127.0.0.1:9100/metrics
http_code=200 time_total=0.022047 size=73777
node_exporter metrics STATUS=OK ✅

===== OPS PROBE: cadvisor metrics =====
URL=http://127.0.0.1:8080/metrics
http_code=200 time_total=0.260035 size=7731197
cadvisor metrics STATUS=OK ✅

===== OPS PROBE: nats varz =====
URL=http://127.0.0.1:8222/varz
http_code=200 time_total=0.003412 size=1700
nats varz STATUS=OK ✅

===== OPS PROBE: public root =====
URL=https://pix2pi.com.tr/
http_code=200 time_total=0.104318 size=10
public root STATUS=OK ✅

===== OPS PROBE: public pilot page =====
URL=https://pix2pi.com.tr/faz4d/pilot-go-live/
http_code=200 time_total=0.078820 size=8452
public pilot page STATUS=OK ✅

PASS_COUNT=9
WARN_COUNT=0
FAZ_6_11_OPS_CONSOLE_PROBE_STATUS=COMPLETE ✅
FAZ_6_11_OPS_CONSOLE_WARN_STATUS=CLEAR ✅
OK ✅ evidence yazildi: docs/faz6/evidence/FAZ_6_11_OPS_CONSOLE_PROBE_EVIDENCE.md
~~~

## 6-12.7 Final Gate Probe

~~~text
===== FAZ 6-12 FINAL GATE PROBE BASLADI =====
6-1 final PASS izi OK ✅
6-2 final PASS izi OK ✅
6-3 final PASS izi OK ✅
6-4 final PASS izi OK ✅
6-5 final PASS izi OK ✅
6-6 final PASS izi OK ✅
6-7 final PASS izi OK ✅
6-8 final PASS izi OK ✅
6-9 final PASS izi OK ✅
6-10 final PASS izi OK ✅
6-11 final PASS izi OK ✅
NATS monitoring fix PASS izi OK ✅
6-9 postdeploy smoke clear izi OK ✅
6-10 edge header fix V2 PASS izi OK ✅
6-10 edge HTTP warn clear izi OK ✅
6-5 real implementation PASS izi OK ✅
6-6 real implementation PASS izi OK ✅
6-7 real implementation PASS izi OK ✅
6-8 real implementation PASS izi OK ✅
6-9 real implementation PASS izi OK ✅
6-10 real implementation PASS izi OK ✅
6-11 real implementation PASS izi OK ✅
Cloudflare gray-by-decision notu OK ✅
Cloudflare green target public launch before go-live notu OK ✅
PASS_COUNT=24
WARN_COUNT=0
FAIL_COUNT=0
FAZ_6_12_FINAL_GATE_PROBE_STATUS=COMPLETE ✅
FAZ_6_12_FINAL_GATE_REQUIRED_STATUS=PASS ✅
OK ✅ evidence yazildi: docs/faz6/evidence/FAZ_6_12_FINAL_GATE_PROBE_EVIDENCE.md
~~~

## 6-12.8 Disk / Memory / Load

~~~text
 16:13:33 up 9 days,  9:32,  2 users,  load average: 0.25, 0.36, 0.40

               total        used        free      shared  buff/cache   available
Mem:            15Gi       2.0Gi       9.6Gi        55Mi       4.0Gi        13Gi
Swap:          2.0Gi        13Mi       2.0Gi

Filesystem                         Size  Used Avail Use% Mounted on
tmpfs                              1.6G  2.6M  1.6G   1% /run
/dev/mapper/ubuntu--vg-ubuntu--lv  194G   84G  103G  45% /
tmpfs                              7.9G     0  7.9G   0% /dev/shm
tmpfs                              5.0M     0  5.0M   0% /run/lock
/dev/sda2                          2.0G  260M  1.6G  15% /boot
/dev/sda1                          1.1G  6.1M  1.1G   1% /boot/efi
overlay                            194G   84G  103G  45% /var/lib/docker/overlay2/a8c3a18b0bd7e3de5d16d40100386d3ea08be31a9810e6f7c0888575e194319a/merged
overlay                            194G   84G  103G  45% /var/lib/docker/overlay2/d2932c2de6ce9849cf1091484ac56e35a51cc13c76e2ecfc9f0337e1a48f8bdd/merged
overlay                            194G   84G  103G  45% /var/lib/docker/overlay2/8e08d680875fd05f703a251bf86f471dff08b636dcf1c9f11386c42bd2c24c2a/merged
overlay                            194G   84G  103G  45% /var/lib/docker/overlay2/5c7f998b4dfbd13c2a7746b255680a765350c04797323ec2f012f335d88f2a10/merged
overlay                            194G   84G  103G  45% /var/lib/docker/overlay2/8db4dd7c772b223317245d437f04d93b54e7dff83a28924b026aa4627dbf09c3/merged
overlay                            194G   84G  103G  45% /var/lib/docker/overlay2/0713c8fded3b70688d57dcd396c223c0547a1f773f4847a502a4d6b7246c5a62/merged
overlay                            194G   84G  103G  45% /var/lib/docker/overlay2/a8acca0ccd95879440af9d725b532fbb26c051fce5a1700f2481cc9ad33c4e15/merged
overlay                            194G   84G  103G  45% /var/lib/docker/overlay2/ad8c87cdb8b4f80befbcc3dd291ca4d726c951396bcdc55ff9b5cb279f918fc1/merged
overlay                            194G   84G  103G  45% /var/lib/docker/overlay2/03df9e174d4b9325cf011fbb9cc235042c975aa75040a3b00c4a88b6270db15d/merged
overlay                            194G   84G  103G  45% /var/lib/docker/overlay2/ec0df24be1f5a11d4a24faf42aa85bdcf0b6808a1e34a6f6dc73fb82a7fd426d/merged
overlay                            194G   84G  103G  45% /var/lib/docker/overlay2/df7635e5431a5d93c6dc51e99f5faac9068e89525f34d11b88abd011bee20604/merged
overlay                            194G   84G  103G  45% /var/lib/docker/overlay2/cbb651d2b94ebdbd40d0804976c0fe595932a653b969cf4bad29ca1bbb9a079c/merged
overlay                            194G   84G  103G  45% /var/lib/docker/overlay2/9f2858e2f2174c8b3375b3fca4a15fe528511e09b5fa301b98c83dc6d10ec113/merged
overlay                            194G   84G  103G  45% /var/lib/docker/overlay2/5ad97030659f8f15bcba1b3f2ab1258e09f777dfa94adcc129003791dd8b588a/merged
tmpfs                              1.6G  4.0K  1.6G   1% /run/user/0
overlay                            194G   84G  103G  45% /var/lib/docker/overlay2/9a7b7828e46f3f9d05283f70d7f7be7bf4aab326248f53881f69a27a60eaf9e0/merged
~~~

## 6-12.9 Final Evidence Inventory

~~~text
docs/faz6/evidence/FAZ_6_10_EDGE_DNS_PROBE_EVIDENCE.md
docs/faz6/evidence/FAZ_6_10_EDGE_HEADER_DIAGNOSTIC_20260501_154122.md
docs/faz6/evidence/FAZ_6_10_EDGE_HEADER_FIX_V2_EVIDENCE.md
docs/faz6/evidence/FAZ_6_10_EDGE_HEADER_HARDENING_EVIDENCE.md
docs/faz6/evidence/FAZ_6_10_EDGE_HTTP_SMOKE_EVIDENCE.md
docs/faz6/evidence/FAZ_6_10_EDGE_RUNTIME_AUDIT.md
docs/faz6/evidence/FAZ_6_10_REAL_IMPLEMENTATION_AUDIT.md
docs/faz6/evidence/FAZ_6_10_ROOT_LOCATION_HEADER_FIX_EVIDENCE.md
docs/faz6/evidence/FAZ_6_11_OPS_CONSOLE_PROBE_EVIDENCE.md
docs/faz6/evidence/FAZ_6_11_OPS_RUNTIME_AUDIT.md
docs/faz6/evidence/FAZ_6_11_REAL_IMPLEMENTATION_AUDIT.md
docs/faz6/evidence/FAZ_6_11_RUNBOOK_TEMPLATE_CHECK_EVIDENCE.md
docs/faz6/evidence/FAZ_6_12_FINAL_GATE_PROBE_EVIDENCE.md
docs/faz6/evidence/FAZ_6_12_RUNTIME_AUDIT.md
docs/faz6/evidence/FAZ_6_2_DB_L8_AUDIT_EVIDENCE.md
docs/faz6/evidence/FAZ_6_2_REAL_IMPLEMENTATION_AUDIT.md
docs/faz6/evidence/FAZ_6_3_MULTI_NODE_RUNTIME_AUDIT.md
docs/faz6/evidence/FAZ_6_3_REAL_IMPLEMENTATION_AUDIT.md
docs/faz6/evidence/FAZ_6_4_EVENT_BUS_RUNTIME_AUDIT.md
docs/faz6/evidence/FAZ_6_4_REAL_IMPLEMENTATION_AUDIT.md
docs/faz6/evidence/FAZ_6_5_OBSERVABILITY_RUNTIME_AUDIT.md
docs/faz6/evidence/FAZ_6_5_REAL_IMPLEMENTATION_AUDIT.md
docs/faz6/evidence/FAZ_6_6_BACKUP_RESTORE_RUNTIME_AUDIT.md
docs/faz6/evidence/FAZ_6_6_REAL_IMPLEMENTATION_AUDIT.md
docs/faz6/evidence/FAZ_6_7_REAL_IMPLEMENTATION_AUDIT.md
docs/faz6/evidence/FAZ_6_7_SECURITY_RUNTIME_AUDIT.md
docs/faz6/evidence/FAZ_6_8_PERFORMANCE_RUNTIME_AUDIT.md
docs/faz6/evidence/FAZ_6_8_REAL_IMPLEMENTATION_AUDIT.md
docs/faz6/evidence/FAZ_6_9_NATS_MONITORING_FIX_EVIDENCE.md
docs/faz6/evidence/FAZ_6_9_POSTDEPLOY_SMOKE_EVIDENCE.md
docs/faz6/evidence/FAZ_6_9_PREDEPLOY_CHECK_EVIDENCE.md
docs/faz6/evidence/FAZ_6_9_REAL_IMPLEMENTATION_AUDIT.md
docs/faz6/evidence/FAZ_6_9_RELEASE_RUNTIME_AUDIT.md
docs/faz6/evidence/FAZ_6_9_ROLLBACK_READINESS_EVIDENCE.md
~~~

## 6-12 Runtime Audit Final Seal

~~~text
FAZ_6_12_RUNTIME_AUDIT=COMPLETE ✅
~~~
