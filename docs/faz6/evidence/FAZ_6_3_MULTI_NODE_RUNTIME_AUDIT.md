# FAZ 6-3 Multi-node Runtime Audit Evidence

Generated At: 2026-05-01T14:29:06+03:00  
Host: vm12827.ovadns.com  
Repo: /root/pix2pi/pix2pi-SaaS  

Bu audit runtime ortaminda multi-node / scale-out hazirlik izlerini toplar. Destructive islem yapmaz.

FAZ_6_3_RUNTIME_AUDIT=STARTED ✅

---


## 6-3.1 Host / Kernel

```text
Linux vm12827.ovadns.com 5.15.0-176-generic #186-Ubuntu SMP Fri Mar 13 11:01:42 UTC 2026 x86_64 x86_64 x86_64 GNU/Linux
```

## 6-3.2 Pix2pi Systemd Services

```text
  dm-event.service                                                                          loaded    inactive dead    Device-mapper event daemon
  lvm2-monitor.service                                                                      loaded    active   exited  Monitoring of LVM2 mirrors, snapshots etc. using dmeventd or progress polling
  lvm2-pvscan@8:3.service                                                                   loaded    active   exited  LVM event activation on device 8:3
  lvm2-pvscan@8:4.service                                                                   loaded    active   exited  LVM event activation on device 8:4
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
```

## 6-3.3 Docker Runtime Services

```text
NAMES                     IMAGE                             STATUS                PORTS
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
pix2pi_nats               nats:2.10-alpine                  Up 9 days             0.0.0.0:4222->4222/tcp, [::]:4222->4222/tcp, 0.0.0.0:8222->8222/tcp, [::]:8222->8222/tcp, 6222/tcp
pix2pi_tempo              grafana/tempo:2.6.1               Up 9 days             0.0.0.0:3200->3200/tcp, [::]:3200->3200/tcp, 0.0.0.0:4317-4318->4317-4318/tcp, [::]:4317-4318->4317-4318/tcp
pix2pi-api-gateway        kong:3.7                          Up 9 days (healthy)   
pix2pi_pg                 postgres:16                       Up 3 days             0.0.0.0:5433->5432/tcp, [::]:5433->5432/tcp
pix2pi_cadvisor           gcr.io/cadvisor/cadvisor:latest   Up 9 days (healthy)   0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp
```

## 6-3.4 Listening Ports

```text
LISTEN 0      4096         0.0.0.0:6379       0.0.0.0:*    users:(("docker-proxy",pid=3788,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096       127.0.0.1:9010       0.0.0.0:*    users:(("pix2pi-api-gate",pid=4016338,fd=7))                                                                                                                                                                                                               
LISTEN 0      4096         0.0.0.0:8080       0.0.0.0:*    users:(("docker-proxy",pid=4033,fd=8))                                                                                                                                                                                                                     
LISTEN 0      511          0.0.0.0:8002       0.0.0.0:*    users:(("nginx",pid=4520,fd=12),("nginx",pid=4519,fd=12),("nginx",pid=4518,fd=12),("nginx",pid=4517,fd=12),("nginx",pid=4516,fd=12),("nginx",pid=4515,fd=12),("nginx",pid=4514,fd=12),("nginx",pid=4513,fd=12),("nginx",pid=2172,fd=12))                   
LISTEN 0      511          0.0.0.0:8000       0.0.0.0:*    users:(("nginx",pid=4520,fd=9),("nginx",pid=4519,fd=9),("nginx",pid=4518,fd=9),("nginx",pid=4517,fd=9),("nginx",pid=4516,fd=9),("nginx",pid=4515,fd=9),("nginx",pid=4514,fd=9),("nginx",pid=4513,fd=9),("nginx",pid=2172,fd=9))                            
LISTEN 0      511          0.0.0.0:8001       0.0.0.0:*    users:(("nginx",pid=4520,fd=10),("nginx",pid=4519,fd=10),("nginx",pid=4518,fd=10),("nginx",pid=4517,fd=10),("nginx",pid=4516,fd=10),("nginx",pid=4515,fd=10),("nginx",pid=4514,fd=10),("nginx",pid=4513,fd=10),("nginx",pid=2172,fd=10))                   
LISTEN 0      4096         0.0.0.0:4222       0.0.0.0:*    users:(("docker-proxy",pid=3151,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096         0.0.0.0:5433       0.0.0.0:*    users:(("docker-proxy",pid=1294029,fd=8))                                                                                                                                                                                                                  
LISTEN 0      511          0.0.0.0:80         0.0.0.0:*    users:(("nginx",pid=2611616,fd=9),("nginx",pid=308628,fd=9),("nginx",pid=308626,fd=9),("nginx",pid=308625,fd=9),("nginx",pid=308624,fd=9),("nginx",pid=308623,fd=9),("nginx",pid=308621,fd=9),("nginx",pid=308620,fd=9),("nginx",pid=308619,fd=9))         
LISTEN 0      4096         0.0.0.0:8222       0.0.0.0:*    users:(("docker-proxy",pid=3226,fd=8))                                                                                                                                                                                                                     
LISTEN 0      511          0.0.0.0:443        0.0.0.0:*    users:(("nginx",pid=2611616,fd=10),("nginx",pid=308628,fd=10),("nginx",pid=308626,fd=10),("nginx",pid=308625,fd=10),("nginx",pid=308624,fd=10),("nginx",pid=308623,fd=10),("nginx",pid=308621,fd=10),("nginx",pid=308620,fd=10),("nginx",pid=308619,fd=10))
LISTEN 0      4096       127.0.0.1:8007       0.0.0.0:*    users:(("nginx",pid=4520,fd=21),("nginx",pid=2172,fd=21))                                                                                                                                                                                                  
LISTEN 0      4096       127.0.0.1:8007       0.0.0.0:*    users:(("nginx",pid=4519,fd=20),("nginx",pid=2172,fd=20))                                                                                                                                                                                                  
LISTEN 0      4096       127.0.0.1:8007       0.0.0.0:*    users:(("nginx",pid=4518,fd=19),("nginx",pid=2172,fd=19))                                                                                                                                                                                                  
LISTEN 0      4096       127.0.0.1:8007       0.0.0.0:*    users:(("nginx",pid=4517,fd=18),("nginx",pid=2172,fd=18))                                                                                                                                                                                                  
LISTEN 0      4096       127.0.0.1:8007       0.0.0.0:*    users:(("nginx",pid=4516,fd=17),("nginx",pid=2172,fd=17))                                                                                                                                                                                                  
LISTEN 0      4096       127.0.0.1:8007       0.0.0.0:*    users:(("nginx",pid=4515,fd=16),("nginx",pid=2172,fd=16))                                                                                                                                                                                                  
LISTEN 0      4096       127.0.0.1:8007       0.0.0.0:*    users:(("nginx",pid=4514,fd=15),("nginx",pid=2172,fd=15))                                                                                                                                                                                                  
LISTEN 0      4096       127.0.0.1:8007       0.0.0.0:*    users:(("nginx",pid=4513,fd=11),("nginx",pid=2172,fd=11))                                                                                                                                                                                                  
LISTEN 0      511        127.0.0.1:8099       0.0.0.0:*    users:(("nginx",pid=2611616,fd=8),("nginx",pid=308628,fd=8),("nginx",pid=308626,fd=8),("nginx",pid=308625,fd=8),("nginx",pid=308624,fd=8),("nginx",pid=308623,fd=8),("nginx",pid=308621,fd=8),("nginx",pid=308620,fd=8),("nginx",pid=308619,fd=8))         
LISTEN 0      4096         0.0.0.0:9090       0.0.0.0:*    users:(("docker-proxy",pid=2893,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096         0.0.0.0:9100       0.0.0.0:*    users:(("docker-proxy",pid=3938,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096         0.0.0.0:9002       0.0.0.0:*    users:(("docker-proxy",pid=2986,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096            [::]:6379          [::]:*    users:(("docker-proxy",pid=3795,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096            [::]:8080          [::]:*    users:(("docker-proxy",pid=4051,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096               *:8091             *:*    users:(("query-read-mode",pid=6735,fd=3))                                                                                                                                                                                                                  
LISTEN 0      4096            [::]:4222          [::]:*    users:(("docker-proxy",pid=3165,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096            [::]:5433          [::]:*    users:(("docker-proxy",pid=1294037,fd=8))                                                                                                                                                                                                                  
LISTEN 0      4096            [::]:8222          [::]:*    users:(("docker-proxy",pid=3256,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096            [::]:9090          [::]:*    users:(("docker-proxy",pid=2902,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096            [::]:9100          [::]:*    users:(("docker-proxy",pid=3958,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096            [::]:9002          [::]:*    users:(("docker-proxy",pid=3006,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096               *:9012             *:*    users:(("identity-api",pid=6565,fd=6))                                                                                                                                                                                                                     
```

## 6-3.5 Nginx Upstream / Proxy Inventory

```text
/etc/nginx/sites-available/pix2pi.bak_20260320_080106:3:    server_name _;
/etc/nginx/sites-available/pix2pi.bak_20260320_080106:8:        proxy_pass http://127.0.0.1:5858;
/etc/nginx/sites-available/pix2pi.bak_20260320_080106:10:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi.bak_20260320_080106:11:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi.bak_20260320_080106:12:        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
/etc/nginx/sites-available/pix2pi.bak_20260320_080106:13:        proxy_set_header X-Forwarded-Proto $scheme;
/etc/nginx/sites-available/pix2pi.bak_20260320_080106:19:        proxy_pass http://127.0.0.1:9001/health;
/etc/nginx/sites-available/pix2pi.bak_20260320_080106:21:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi.bak_20260320_080106:27:        proxy_pass http://127.0.0.1:9001;
/etc/nginx/sites-available/pix2pi.bak_20260320_080106:29:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi.bak_20260320_080106:30:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi.bak_20260320_080106:31:        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
/etc/nginx/sites-available/pix2pi.bak_20260320_080106:32:        proxy_set_header X-Forwarded-Proto $scheme;
/etc/nginx/sites-available/pix2pi.bak_20260320_080106:37:        proxy_pass http://127.0.0.1:9011;
/etc/nginx/sites-available/pix2pi.bak_20260320_080106:39:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi.bak_20260320_080106:40:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_1773945801:3:    server_name pix2pi.com.tr www.pix2pi.com.tr panel.pix2pi.com.tr;
/etc/nginx/sites-available/pix2pi_ssl.bak_1773945801:16:        proxy_pass http://127.0.0.1:8080/api/health;
/etc/nginx/sites-available/pix2pi_ssl.bak_1773945801:17:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_1773945801:18:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_1773945801:22:        proxy_pass http://127.0.0.1:8080/dev/token;
/etc/nginx/sites-available/pix2pi_ssl.bak_1773945801:23:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_1773945801:24:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_1773945801:28:        proxy_pass http://127.0.0.1:9016/status;
/etc/nginx/sites-available/pix2pi_ssl.bak_1773945801:29:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_1773945801:30:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_1773945801:34:        proxy_pass http://127.0.0.1:9016/health;
/etc/nginx/sites-available/pix2pi_ssl.bak_1773945801:35:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_1773945801:36:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_1773945801:52:    server_name server.pix2pi.com.tr;
/etc/nginx/sites-available/pix2pi_ssl.bak_1773945801:64:        proxy_pass http://127.0.0.1:8080/containers/;
/etc/nginx/sites-available/pix2pi_ssl.bak_1773945801:65:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_1773945801:66:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_215025:3:    server_name pix2pi.com.tr www.pix2pi.com.tr panel.pix2pi.com.tr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_215025:23:        proxy_pass http://127.0.0.1:8080/api/health;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_215025:24:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_215025:25:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_215025:29:        proxy_pass http://127.0.0.1:8080/dev/token;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_215025:30:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_215025:31:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_215025:35:        proxy_pass http://127.0.0.1:9016/status;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_215025:36:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_215025:37:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_215025:41:        proxy_pass http://127.0.0.1:9016/health;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_215025:42:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_215025:43:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_215025:59:    server_name server.pix2pi.com.tr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_215025:77:        proxy_pass http://127.0.0.1:8080/containers/;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_215025:78:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_215025:79:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_080805:3:    server_name pix2pi.com.tr www.pix2pi.com.tr panel.pix2pi.com.tr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_080805:24:        proxy_pass http://127.0.0.1:8080/api/health;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_080805:25:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_080805:26:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_080805:30:        proxy_pass http://127.0.0.1:8080/dev/token;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_080805:31:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_080805:32:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_080805:36:        proxy_pass http://127.0.0.1:9016/status;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_080805:37:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_080805:38:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_080805:42:        proxy_pass http://127.0.0.1:9016/health;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_080805:43:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_080805:44:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_080805:60:    server_name server.pix2pi.com.tr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_080805:78:        proxy_pass http://127.0.0.1:8080/containers/;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_080805:79:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_080805:80:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi:3:    server_name _;
/etc/nginx/sites-available/pix2pi:7:        proxy_pass http://127.0.0.1:8090/status;
/etc/nginx/sites-available/pix2pi:9:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi:10:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi:11:        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
/etc/nginx/sites-available/pix2pi:12:        proxy_set_header X-Forwarded-Proto $scheme;
/etc/nginx/sites-available/pix2pi:17:        proxy_pass http://127.0.0.1:8090/health;
/etc/nginx/sites-available/pix2pi:19:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi:20:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi:21:        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
/etc/nginx/sites-available/pix2pi:22:        proxy_set_header X-Forwarded-Proto $scheme;
/etc/nginx/sites-available/pix2pi:27:        proxy_pass http://127.0.0.1:5858;
/etc/nginx/sites-available/pix2pi:29:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi:30:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi:31:        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
/etc/nginx/sites-available/pix2pi:32:        proxy_set_header X-Forwarded-Proto $scheme;
/etc/nginx/sites-available/pix2pi:37:        proxy_pass http://127.0.0.1:9001/health;
/etc/nginx/sites-available/pix2pi:39:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi:45:        proxy_pass http://127.0.0.1:9001;
/etc/nginx/sites-available/pix2pi:47:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi:48:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi:49:        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
/etc/nginx/sites-available/pix2pi:50:        proxy_set_header X-Forwarded-Proto $scheme;
/etc/nginx/sites-available/pix2pi:55:        proxy_pass http://127.0.0.1:9011;
/etc/nginx/sites-available/pix2pi:57:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi:58:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi:64:        proxy_pass http://127.0.0.1:8090/status;
/etc/nginx/sites-available/pix2pi:66:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi:67:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi:68:        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
/etc/nginx/sites-available/pix2pi:69:        proxy_set_header X-Forwarded-Proto $scheme;
/etc/nginx/sites-available/pix2pi_api_gateway:3:    server_name api.pix2pi.com.tr;
/etc/nginx/sites-available/pix2pi_api_gateway:8:        proxy_pass http://127.0.0.1:9010;
/etc/nginx/sites-available/pix2pi_api_gateway:12:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_api_gateway:13:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_api_gateway:15:        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
/etc/nginx/sites-available/pix2pi_api_gateway:35:    server_name api.pix2pi.com.tr;
/etc/nginx/sites-available/default.bak.2026-03-19-061610:46:	server_name _;
/etc/nginx/sites-available/default.bak.2026-03-19-061610:83:#	server_name example.com;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_214713:3:    server_name pix2pi.com.tr www.pix2pi.com.tr panel.pix2pi.com.tr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_214713:22:        proxy_pass http://127.0.0.1:8080/api/health;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_214713:23:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_214713:24:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_214713:28:        proxy_pass http://127.0.0.1:8080/dev/token;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_214713:29:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_214713:30:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_214713:34:        proxy_pass http://127.0.0.1:9016/status;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_214713:35:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_214713:36:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_214713:40:        proxy_pass http://127.0.0.1:9016/health;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_214713:41:        proxy_set_header Host $host;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_214713:42:        proxy_set_header X-Real-IP $remote_addr;
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_214713:58:    server_name server.pix2pi.com.tr;
```

## 6-3.6 Pix2pi Env Port Inventory

```text
===== .env =====
DB_HOST=localhost
DB_PORT=5433
REDIS_HOST=localhost
REDIS_PORT=6379
DB_READ_DSN=postgres://user:pass@localhost:5433/dbname?sslmode=disable
DB_WRITE_DSN=postgres://pix2pi:pix2pi@127.0.0.1:5433/pix2pi?sslmode=disable
DB_DSN=postgres://pix2pi:pix2pi@127.0.0.1:5433/pix2pi?sslmode=disable
===== /etc/pix2pi/ports.env =====
PANEL_PORT=7100
IDENTITY_PORT=9001
PG_PORT=5433
MISSION_PORT=5860
REGISTRY_PORT=5870
PLUGIN_ERP_PORT=9002
API_GATEWAY_PORT=9010
REGISTRY_HOST=127.0.0.1
JOBS_RUNTIME_PORT=5880
WEBHOOK_RUNTIME_PORT=5890
WORKFLOW_RUNTIME_PORT=5900
PLUGIN_RUNTIME_PORT=5910
PUBLICAPI_RUNTIME_PORT=5920
NOTIFICATION_RUNTIME_PORT=5930
EARLY_WARNING_RUNTIME_PORT=5940
INCIDENT_AUDIT_RUNTIME_PORT=5950
RUNTIME_TOPOLOGY_PORT=5960
REALTIME_RUNTIME_PORT=5970
===== /opt/pix2pi/orchestrator/env/common.env =====
DB_WRITE_DSN="host=localhost port=5433 user=pix2pi password=***MASKED*** dbname=pix2pi sslmode=disable"
DB_READ_DSN="host=localhost port=5433 user=pix2pi password=***MASKED*** dbname=pix2pi sslmode=disable"
INTERNAL_GATEWAY_KEY=route-secret-001
GATEWAY_INTERNAL_KEY=route-secret-001
GATEWAY_BIND_ADDR=127.0.0.1
```

## 6-3.7 Local Health Endpoint Probe

```text
===== PORT 9001 /health =====

===== PORT 9010 /health =====
Pix2pi API Gateway OK
===== PORT 9090 /health =====

===== PORT 9100 /health =====

===== PORT 8080 /health =====
<a href="/containers/">Temporary Redirect</a>.


===== PORT 3000 /health =====

```

## 6-3.8 Runtime Audit Interpretation

```text
6-3.1 Host inventory collected OK ✅
6-3.2 Systemd service inventory collected OK ✅
6-3.3 Docker service inventory collected OK ✅
6-3.4 Listening ports inventory collected OK ✅
6-3.5 Nginx proxy/upstream inventory collected OK ✅
6-3.6 Env/port inventory collected OK ✅
6-3.7 Health endpoint probe collected OK ✅
FAZ_6_3_RUNTIME_AUDIT=COMPLETE ✅
```
