# FAZ 6-5 Observability Runtime Audit Evidence

Generated At: 2026-05-01T14:39:13+03:00  
Host: vm12827.ovadns.com  
Repo: /root/pix2pi/pix2pi-SaaS  

Bu audit runtime ortaminda observability / early warning / SRE dashboard izlerini toplar. Destructive islem yapmaz.

FAZ_6_5_RUNTIME_AUDIT=STARTED ✅

---


## 6-5.1 Host / Kernel

```text
Linux vm12827.ovadns.com 5.15.0-176-generic #186-Ubuntu SMP Fri Mar 13 11:01:42 UTC 2026 x86_64 x86_64 x86_64 GNU/Linux
```

## 6-5.2 Observability Docker Containers

```text
NAMES                     IMAGE                             STATUS                PORTS
pix2pi-redis              redis:7-alpine                    Up 9 days             0.0.0.0:6379->6379/tcp, [::]:6379->6379/tcp
pix2pi_pg_replica         postgres:16                       Up 9 days             0.0.0.0:5434->5432/tcp, [::]:5434->5432/tcp
pix2pi_grafana            grafana/grafana:latest            Up 9 days             0.0.0.0:3001->3000/tcp, [::]:3001->3000/tcp
pix2pi_promtail           grafana/promtail:2.9.8            Up 9 days             
pix2pi_loki               grafana/loki:2.9.8                Up 9 days             0.0.0.0:3100->3100/tcp, [::]:3100->3100/tcp
pix2pi_prometheus         prom/prometheus:latest            Up 9 days             0.0.0.0:9090->9090/tcp, [::]:9090->9090/tcp
pix2pi_node_exporter      prom/node-exporter:latest         Up 9 days             0.0.0.0:9100->9100/tcp, [::]:9100->9100/tcp
pix2pi_nats               nats:2.10-alpine                  Up 9 days             0.0.0.0:4222->4222/tcp, [::]:4222->4222/tcp, 0.0.0.0:8222->8222/tcp, [::]:8222->8222/tcp, 6222/tcp
pix2pi_tempo              grafana/tempo:2.6.1               Up 9 days             0.0.0.0:3200->3200/tcp, [::]:3200->3200/tcp, 0.0.0.0:4317-4318->4317-4318/tcp, [::]:4317-4318->4317-4318/tcp
pix2pi_pg                 postgres:16                       Up 3 days             0.0.0.0:5433->5432/tcp, [::]:5433->5432/tcp
pix2pi_cadvisor           gcr.io/cadvisor/cadvisor:latest   Up 9 days (healthy)   0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp
```

## 6-5.3 Observability Systemd Services

```text
  kmod-static-nodes.service                                                                 loaded    active   exited  Create List of Static Device Nodes
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
  systemd-tmpfiles-setup-dev.service                                                        loaded    active   exited  Create Static Device Nodes in /dev
```

## 6-5.4 Observability Listening Ports

```text
LISTEN 0      4096       127.0.0.1:9010       0.0.0.0:*    users:(("pix2pi-api-gate",pid=4016338,fd=7))                                                                                                                                                                                                               
LISTEN 0      4096         0.0.0.0:8080       0.0.0.0:*    users:(("docker-proxy",pid=4033,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096         0.0.0.0:4222       0.0.0.0:*    users:(("docker-proxy",pid=3151,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096         0.0.0.0:3100       0.0.0.0:*    users:(("docker-proxy",pid=3328,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096         0.0.0.0:8222       0.0.0.0:*    users:(("docker-proxy",pid=3226,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096         0.0.0.0:9090       0.0.0.0:*    users:(("docker-proxy",pid=2893,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096         0.0.0.0:9100       0.0.0.0:*    users:(("docker-proxy",pid=3938,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096            [::]:8080          [::]:*    users:(("docker-proxy",pid=4051,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096            [::]:4222          [::]:*    users:(("docker-proxy",pid=3165,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096            [::]:3100          [::]:*    users:(("docker-proxy",pid=3342,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096            [::]:8222          [::]:*    users:(("docker-proxy",pid=3256,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096            [::]:9090          [::]:*    users:(("docker-proxy",pid=2902,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096            [::]:9100          [::]:*    users:(("docker-proxy",pid=3958,fd=8))                                                                                                                                                                                                                     
```

## 6-5.5 Prometheus Ready Probe

```text
Prometheus Server is Ready.
```

## 6-5.6 Prometheus Targets Probe

```text
{"status":"success","data":{"activeTargets":[{"discoveredLabels":{"__address__":"node_exporter:9100","__metrics_path__":"/metrics","__scheme__":"http","__scrape_interval__":"15s","__scrape_timeout__":"10s","job":"node_exporter"},"labels":{"instance":"node_exporter:9100","job":"node_exporter"},"scrapePool":"node_exporter","scrapeUrl":"http://node_exporter:9100/metrics","globalUrl":"http://node_exporter:9100/metrics","lastError":"","lastScrape":"2026-05-01T11:39:08.529394354Z","lastScrapeDuration":0.028332392,"health":"up","scrapeInterval":"15s","scrapeTimeout":"10s"},{"discoveredLabels":{"__address__":"prometheus:9090","__metrics_path__":"/metrics","__scheme__":"http","__scrape_interval__":"15s","__scrape_timeout__":"10s","job":"prometheus"},"labels":{"instance":"prometheus:9090","job":"prometheus"},"scrapePool":"prometheus","scrapeUrl":"http://prometheus:9090/metrics","globalUrl":"http://prometheus:9090/metrics","lastError":"","lastScrape":"2026-05-01T11:39:10.829484212Z","lastScrapeDuration":0.006977622,"health":"up","scrapeInterval":"15s","scrapeTimeout":"10s"}],"droppedTargets":[],"droppedTargetCounts":{"node_exporter":0,"prometheus":0}}}```

## 6-5.7 Grafana Health Probe

```text
```

## 6-5.8 Node Exporter Metrics Probe

```text
# HELP go_gc_duration_seconds A summary of the wall-time pause (stop-the-world) duration in garbage collection cycles.
# TYPE go_gc_duration_seconds summary
go_gc_duration_seconds{quantile="0"} 4.8432e-05
go_gc_duration_seconds{quantile="0.25"} 6.4486e-05
go_gc_duration_seconds{quantile="0.5"} 7.6462e-05
go_gc_duration_seconds{quantile="0.75"} 8.7529e-05
go_gc_duration_seconds{quantile="1"} 0.000159607
go_gc_duration_seconds_sum 7.045412793
go_gc_duration_seconds_count 88440
# HELP go_gc_gogc_percent Heap size target percentage configured by the user, otherwise 100. This value is set by the GOGC environment variable, and the runtime/debug.SetGCPercent function. Sourced from /gc/gogc:percent.
# TYPE go_gc_gogc_percent gauge
go_gc_gogc_percent 100
# HELP go_gc_gomemlimit_bytes Go runtime memory limit configured by the user, otherwise math.MaxInt64. This value is set by the GOMEMLIMIT environment variable, and the runtime/debug.SetMemoryLimit function. Sourced from /gc/gomemlimit:bytes.
# TYPE go_gc_gomemlimit_bytes gauge
go_gc_gomemlimit_bytes 9.223372036854776e+18
# HELP go_goroutines Number of goroutines that currently exist.
# TYPE go_goroutines gauge
go_goroutines 8
# HELP go_info Information about the Go environment.
# TYPE go_info gauge
```

## 6-5.9 cAdvisor Metrics Probe

```text
# HELP cadvisor_version_info A metric with a constant '1' value labeled by kernel version, OS version, docker version, cadvisor version & cadvisor revision.
# TYPE cadvisor_version_info gauge
cadvisor_version_info{cadvisorRevision="f5bec374",cadvisorVersion="v0.55.1",dockerVersion="",kernelVersion="5.15.0-176-generic",osVersion="Alpine Linux v3.22"} 1
# HELP container_blkio_device_usage_total Blkio Device bytes usage
# TYPE container_blkio_device_usage_total counter
container_blkio_device_usage_total{container_label_com_docker_compose_config_hash="",container_label_com_docker_compose_container_number="",container_label_com_docker_compose_depends_on="",container_label_com_docker_compose_image="",container_label_com_docker_compose_oneoff="",container_label_com_docker_compose_project="",container_label_com_docker_compose_project_config_files="",container_label_com_docker_compose_project_working_dir="",container_label_com_docker_compose_service="",container_label_com_docker_compose_version="",container_label_maintainer="",container_label_org_opencontainers_image_authors="",container_label_org_opencontainers_image_created="",container_label_org_opencontainers_image_description="",container_label_org_opencontainers_image_documentation="",container_label_org_opencontainers_image_licenses="",container_label_org_opencontainers_image_ref_name="",container_label_org_opencontainers_image_revision="",container_label_org_opencontainers_image_source="",container_label_org_opencontainers_image_title="",container_label_org_opencontainers_image_url="",container_label_org_opencontainers_image_vendor="",container_label_org_opencontainers_image_version="",device="",id="/",image="",major="11",minor="0",name="",operation="Read"} 2048 1777635553742
container_blkio_device_usage_total{container_label_com_docker_compose_config_hash="",container_label_com_docker_compose_container_number="",container_label_com_docker_compose_depends_on="",container_label_com_docker_compose_image="",container_label_com_docker_compose_oneoff="",container_label_com_docker_compose_project="",container_label_com_docker_compose_project_config_files="",container_label_com_docker_compose_project_working_dir="",container_label_com_docker_compose_service="",container_label_com_docker_compose_version="",container_label_maintainer="",container_label_org_opencontainers_image_authors="",container_label_org_opencontainers_image_created="",container_label_org_opencontainers_image_description="",container_label_org_opencontainers_image_documentation="",container_label_org_opencontainers_image_licenses="",container_label_org_opencontainers_image_ref_name="",container_label_org_opencontainers_image_revision="",container_label_org_opencontainers_image_source="",container_label_org_opencontainers_image_title="",container_label_org_opencontainers_image_url="",container_label_org_opencontainers_image_vendor="",container_label_org_opencontainers_image_version="",device="",id="/",image="",major="11",minor="0",name="",operation="Write"} 0 1777635553742
container_blkio_device_usage_total{container_label_com_docker_compose_config_hash="",container_label_com_docker_compose_container_number="",container_label_com_docker_compose_depends_on="",container_label_com_docker_compose_image="",container_label_com_docker_compose_oneoff="",container_label_com_docker_compose_project="",container_label_com_docker_compose_project_config_files="",container_label_com_docker_compose_project_working_dir="",container_label_com_docker_compose_service="",container_label_com_docker_compose_version="",container_label_maintainer="",container_label_org_opencontainers_image_authors="",container_label_org_opencontainers_image_created="",container_label_org_opencontainers_image_description="",container_label_org_opencontainers_image_documentation="",container_label_org_opencontainers_image_licenses="",container_label_org_opencontainers_image_ref_name="",container_label_org_opencontainers_image_revision="",container_label_org_opencontainers_image_source="",container_label_org_opencontainers_image_title="",container_label_org_opencontainers_image_url="",container_label_org_opencontainers_image_vendor="",container_label_org_opencontainers_image_version="",device="",id="/",image="",major="7",minor="11",name="",operation="Read"} 166400 1777635553742
container_blkio_device_usage_total{container_label_com_docker_compose_config_hash="",container_label_com_docker_compose_container_number="",container_label_com_docker_compose_depends_on="",container_label_com_docker_compose_image="",container_label_com_docker_compose_oneoff="",container_label_com_docker_compose_project="",container_label_com_docker_compose_project_config_files="",container_label_com_docker_compose_project_working_dir="",container_label_com_docker_compose_service="",container_label_com_docker_compose_version="",container_label_maintainer="",container_label_org_opencontainers_image_authors="",container_label_org_opencontainers_image_created="",container_label_org_opencontainers_image_description="",container_label_org_opencontainers_image_documentation="",container_label_org_opencontainers_image_licenses="",container_label_org_opencontainers_image_ref_name="",container_label_org_opencontainers_image_revision="",container_label_org_opencontainers_image_source="",container_label_org_opencontainers_image_title="",container_label_org_opencontainers_image_url="",container_label_org_opencontainers_image_vendor="",container_label_org_opencontainers_image_version="",device="",id="/",image="",major="7",minor="11",name="",operation="Write"} 0 1777635553742
container_blkio_device_usage_total{container_label_com_docker_compose_config_hash="",container_label_com_docker_compose_container_number="",container_label_com_docker_compose_depends_on="",container_label_com_docker_compose_image="",container_label_com_docker_compose_oneoff="",container_label_com_docker_compose_project="",container_label_com_docker_compose_project_config_files="",container_label_com_docker_compose_project_working_dir="",container_label_com_docker_compose_service="",container_label_com_docker_compose_version="",container_label_maintainer="",container_label_org_opencontainers_image_authors="",container_label_org_opencontainers_image_created="",container_label_org_opencontainers_image_description="",container_label_org_opencontainers_image_documentation="",container_label_org_opencontainers_image_licenses="",container_label_org_opencontainers_image_ref_name="",container_label_org_opencontainers_image_revision="",container_label_org_opencontainers_image_source="",container_label_org_opencontainers_image_title="",container_label_org_opencontainers_image_url="",container_label_org_opencontainers_image_vendor="",container_label_org_opencontainers_image_version="",device="",id="/",image="",major="7",minor="6",name="",operation="Read"} 304128 1777635553742
container_blkio_device_usage_total{container_label_com_docker_compose_config_hash="",container_label_com_docker_compose_container_number="",container_label_com_docker_compose_depends_on="",container_label_com_docker_compose_image="",container_label_com_docker_compose_oneoff="",container_label_com_docker_compose_project="",container_label_com_docker_compose_project_config_files="",container_label_com_docker_compose_project_working_dir="",container_label_com_docker_compose_service="",container_label_com_docker_compose_version="",container_label_maintainer="",container_label_org_opencontainers_image_authors="",container_label_org_opencontainers_image_created="",container_label_org_opencontainers_image_description="",container_label_org_opencontainers_image_documentation="",container_label_org_opencontainers_image_licenses="",container_label_org_opencontainers_image_ref_name="",container_label_org_opencontainers_image_revision="",container_label_org_opencontainers_image_source="",container_label_org_opencontainers_image_title="",container_label_org_opencontainers_image_url="",container_label_org_opencontainers_image_vendor="",container_label_org_opencontainers_image_version="",device="",id="/",image="",major="7",minor="6",name="",operation="Write"} 0 1777635553742
container_blkio_device_usage_total{container_label_com_docker_compose_config_hash="",container_label_com_docker_compose_container_number="",container_label_com_docker_compose_depends_on="",container_label_com_docker_compose_image="",container_label_com_docker_compose_oneoff="",container_label_com_docker_compose_project="",container_label_com_docker_compose_project_config_files="",container_label_com_docker_compose_project_working_dir="",container_label_com_docker_compose_service="",container_label_com_docker_compose_version="",container_label_maintainer="",container_label_org_opencontainers_image_authors="",container_label_org_opencontainers_image_created="",container_label_org_opencontainers_image_description="",container_label_org_opencontainers_image_documentation="",container_label_org_opencontainers_image_licenses="",container_label_org_opencontainers_image_ref_name="",container_label_org_opencontainers_image_revision="",container_label_org_opencontainers_image_source="",container_label_org_opencontainers_image_title="",container_label_org_opencontainers_image_url="",container_label_org_opencontainers_image_vendor="",container_label_org_opencontainers_image_version="",device="",id="/",image="",major="7",minor="7",name="",operation="Read"} 152064 1777635553742
container_blkio_device_usage_total{container_label_com_docker_compose_config_hash="",container_label_com_docker_compose_container_number="",container_label_com_docker_compose_depends_on="",container_label_com_docker_compose_image="",container_label_com_docker_compose_oneoff="",container_label_com_docker_compose_project="",container_label_com_docker_compose_project_config_files="",container_label_com_docker_compose_project_working_dir="",container_label_com_docker_compose_service="",container_label_com_docker_compose_version="",container_label_maintainer="",container_label_org_opencontainers_image_authors="",container_label_org_opencontainers_image_created="",container_label_org_opencontainers_image_description="",container_label_org_opencontainers_image_documentation="",container_label_org_opencontainers_image_licenses="",container_label_org_opencontainers_image_ref_name="",container_label_org_opencontainers_image_revision="",container_label_org_opencontainers_image_source="",container_label_org_opencontainers_image_title="",container_label_org_opencontainers_image_url="",container_label_org_opencontainers_image_vendor="",container_label_org_opencontainers_image_version="",device="",id="/",image="",major="7",minor="7",name="",operation="Write"} 0 1777635553742
container_blkio_device_usage_total{container_label_com_docker_compose_config_hash="",container_label_com_docker_compose_container_number="",container_label_com_docker_compose_depends_on="",container_label_com_docker_compose_image="",container_label_com_docker_compose_oneoff="",container_label_com_docker_compose_project="",container_label_com_docker_compose_project_config_files="",container_label_com_docker_compose_project_working_dir="",container_label_com_docker_compose_service="",container_label_com_docker_compose_version="",container_label_maintainer="",container_label_org_opencontainers_image_authors="",container_label_org_opencontainers_image_created="",container_label_org_opencontainers_image_description="",container_label_org_opencontainers_image_documentation="",container_label_org_opencontainers_image_licenses="",container_label_org_opencontainers_image_ref_name="",container_label_org_opencontainers_image_revision="",container_label_org_opencontainers_image_source="",container_label_org_opencontainers_image_title="",container_label_org_opencontainers_image_url="",container_label_org_opencontainers_image_vendor="",container_label_org_opencontainers_image_version="",device="",id="/system.slice",image="",major="7",minor="11",name="",operation="Read"} 166400 1777635552569
container_blkio_device_usage_total{container_label_com_docker_compose_config_hash="",container_label_com_docker_compose_container_number="",container_label_com_docker_compose_depends_on="",container_label_com_docker_compose_image="",container_label_com_docker_compose_oneoff="",container_label_com_docker_compose_project="",container_label_com_docker_compose_project_config_files="",container_label_com_docker_compose_project_working_dir="",container_label_com_docker_compose_service="",container_label_com_docker_compose_version="",container_label_maintainer="",container_label_org_opencontainers_image_authors="",container_label_org_opencontainers_image_created="",container_label_org_opencontainers_image_description="",container_label_org_opencontainers_image_documentation="",container_label_org_opencontainers_image_licenses="",container_label_org_opencontainers_image_ref_name="",container_label_org_opencontainers_image_revision="",container_label_org_opencontainers_image_source="",container_label_org_opencontainers_image_title="",container_label_org_opencontainers_image_url="",container_label_org_opencontainers_image_vendor="",container_label_org_opencontainers_image_version="",device="",id="/system.slice",image="",major="7",minor="11",name="",operation="Write"} 0 1777635552569
container_blkio_device_usage_total{container_label_com_docker_compose_config_hash="",container_label_com_docker_compose_container_number="",container_label_com_docker_compose_depends_on="",container_label_com_docker_compose_image="",container_label_com_docker_compose_oneoff="",container_label_com_docker_compose_project="",container_label_com_docker_compose_project_config_files="",container_label_com_docker_compose_project_working_dir="",container_label_com_docker_compose_service="",container_label_com_docker_compose_version="",container_label_maintainer="",container_label_org_opencontainers_image_authors="",container_label_org_opencontainers_image_created="",container_label_org_opencontainers_image_description="",container_label_org_opencontainers_image_documentation="",container_label_org_opencontainers_image_licenses="",container_label_org_opencontainers_image_ref_name="",container_label_org_opencontainers_image_revision="",container_label_org_opencontainers_image_source="",container_label_org_opencontainers_image_title="",container_label_org_opencontainers_image_url="",container_label_org_opencontainers_image_vendor="",container_label_org_opencontainers_image_version="",device="",id="/system.slice",image="",major="7",minor="6",name="",operation="Read"} 304128 1777635552569
container_blkio_device_usage_total{container_label_com_docker_compose_config_hash="",container_label_com_docker_compose_container_number="",container_label_com_docker_compose_depends_on="",container_label_com_docker_compose_image="",container_label_com_docker_compose_oneoff="",container_label_com_docker_compose_project="",container_label_com_docker_compose_project_config_files="",container_label_com_docker_compose_project_working_dir="",container_label_com_docker_compose_service="",container_label_com_docker_compose_version="",container_label_maintainer="",container_label_org_opencontainers_image_authors="",container_label_org_opencontainers_image_created="",container_label_org_opencontainers_image_description="",container_label_org_opencontainers_image_documentation="",container_label_org_opencontainers_image_licenses="",container_label_org_opencontainers_image_ref_name="",container_label_org_opencontainers_image_revision="",container_label_org_opencontainers_image_source="",container_label_org_opencontainers_image_title="",container_label_org_opencontainers_image_url="",container_label_org_opencontainers_image_vendor="",container_label_org_opencontainers_image_version="",device="",id="/system.slice",image="",major="7",minor="6",name="",operation="Write"} 0 1777635552569
container_blkio_device_usage_total{container_label_com_docker_compose_config_hash="",container_label_com_docker_compose_container_number="",container_label_com_docker_compose_depends_on="",container_label_com_docker_compose_image="",container_label_com_docker_compose_oneoff="",container_label_com_docker_compose_project="",container_label_com_docker_compose_project_config_files="",container_label_com_docker_compose_project_working_dir="",container_label_com_docker_compose_service="",container_label_com_docker_compose_version="",container_label_maintainer="",container_label_org_opencontainers_image_authors="",container_label_org_opencontainers_image_created="",container_label_org_opencontainers_image_description="",container_label_org_opencontainers_image_documentation="",container_label_org_opencontainers_image_licenses="",container_label_org_opencontainers_image_ref_name="",container_label_org_opencontainers_image_revision="",container_label_org_opencontainers_image_source="",container_label_org_opencontainers_image_title="",container_label_org_opencontainers_image_url="",container_label_org_opencontainers_image_vendor="",container_label_org_opencontainers_image_version="",device="",id="/system.slice",image="",major="7",minor="7",name="",operation="Read"} 152064 1777635552569
container_blkio_device_usage_total{container_label_com_docker_compose_config_hash="",container_label_com_docker_compose_container_number="",container_label_com_docker_compose_depends_on="",container_label_com_docker_compose_image="",container_label_com_docker_compose_oneoff="",container_label_com_docker_compose_project="",container_label_com_docker_compose_project_config_files="",container_label_com_docker_compose_project_working_dir="",container_label_com_docker_compose_service="",container_label_com_docker_compose_version="",container_label_maintainer="",container_label_org_opencontainers_image_authors="",container_label_org_opencontainers_image_created="",container_label_org_opencontainers_image_description="",container_label_org_opencontainers_image_documentation="",container_label_org_opencontainers_image_licenses="",container_label_org_opencontainers_image_ref_name="",container_label_org_opencontainers_image_revision="",container_label_org_opencontainers_image_source="",container_label_org_opencontainers_image_title="",container_label_org_opencontainers_image_url="",container_label_org_opencontainers_image_vendor="",container_label_org_opencontainers_image_version="",device="",id="/system.slice",image="",major="7",minor="7",name="",operation="Write"} 0 1777635552569
container_blkio_device_usage_total{container_label_com_docker_compose_config_hash="",container_label_com_docker_compose_container_number="",container_label_com_docker_compose_depends_on="",container_label_com_docker_compose_image="",container_label_com_docker_compose_oneoff="",container_label_com_docker_compose_project="",container_label_com_docker_compose_project_config_files="",container_label_com_docker_compose_project_working_dir="",container_label_com_docker_compose_service="",container_label_com_docker_compose_version="",container_label_maintainer="",container_label_org_opencontainers_image_authors="",container_label_org_opencontainers_image_created="",container_label_org_opencontainers_image_description="",container_label_org_opencontainers_image_documentation="",container_label_org_opencontainers_image_licenses="",container_label_org_opencontainers_image_ref_name="",container_label_org_opencontainers_image_revision="",container_label_org_opencontainers_image_source="",container_label_org_opencontainers_image_title="",container_label_org_opencontainers_image_url="",container_label_org_opencontainers_image_vendor="",container_label_org_opencontainers_image_version="",device="",id="/system.slice/snapd.service",image="",major="7",minor="11",name="",operation="Read"} 13312 1777635554258
```

## 6-5.10 Pix2pi Local Health Probes

```text
===== PORT 9001 HEALTH/METRICS PROBE =====

===== PORT 9010 HEALTH/METRICS PROBE =====
Pix2pi API Gateway OK
===== PORT 9090 HEALTH/METRICS PROBE =====
# HELP go_gc_cycles_automatic_gc_cycles_total Count of completed GC cycles generated by the Go runtime. Sourced from /gc/cycles/automatic:gc-cycles.
# TYPE go_gc_cycles_automatic_gc_cycles_total counter
go_gc_cycles_automatic_gc_cycles_total 6904
# HELP go_gc_cycles_forced_gc_cycles_total Count of completed GC cycles forced by the application. Sourced from /gc/cycles/forced:gc-cycles.
# TYPE go_gc_cycles_forced_gc_cycles_total counter

===== PORT 9100 HEALTH/METRICS PROBE =====
# HELP go_gc_duration_seconds A summary of the wall-time pause (stop-the-world) duration in garbage collection cycles.
# TYPE go_gc_duration_seconds summary
go_gc_duration_seconds{quantile="0"} 4.8432e-05
go_gc_duration_seconds{quantile="0.25"} 6.4771e-05
go_gc_duration_seconds{quantile="0.5"} 7.6463e-05

===== PORT 8080 HEALTH/METRICS PROBE =====
<a href="/containers/">Temporary Redirect</a>.

# HELP cadvisor_version_info A metric with a constant '1' value labeled by kernel version, OS version, docker version, cadvisor version & cadvisor revision.
# TYPE cadvisor_version_info gauge
cadvisor_version_info{cadvisorRevision="f5bec374",cadvisorVersion="v0.55.1",dockerVersion="",kernelVersion="5.15.0-176-generic",osVersion="Alpine Linux v3.22"} 1
# HELP container_blkio_device_usage_total Blkio Device bytes usage
# TYPE container_blkio_device_usage_total counter

===== PORT 3000 HEALTH/METRICS PROBE =====

===== PORT 8222 HEALTH/METRICS PROBE =====

```

## 6-5.11 Observability Config Inventory

```text
===== ./ops =====
===== /opt/pix2pi =====
/opt/pix2pi/bin/pix2pi_alert_dispatch.sh
/opt/pix2pi/runtime/watchdog_alerts.log
/opt/pix2pi/runtime/watchdog_alerts.json
/opt/pix2pi/runtime/auto_heal/logs/alert_engine.log
/opt/pix2pi/runtime/auto_heal/alert.env
===== /opt/pix2pi/orchestrator =====
===== /etc/pix2pi =====
```

## 6-5.12 Alert / Rule Inventory

```text
./install_phase1_scaffold.sh:8:cat > "$ROOT_DIR/db/migrations/001_phase1_foundation.down.sql" <<'EOF'
./grafana/dashboards/docker-monitoring.json:248:            "thresholdLabels": false,
./grafana/dashboards/docker-monitoring.json:249:            "thresholdMarkers": true
./grafana/dashboards/docker-monitoring.json:298:          "thresholds": "",
./grafana/dashboards/docker-monitoring.json:329:            "thresholdLabels": false,
./grafana/dashboards/docker-monitoring.json:330:            "thresholdMarkers": true
./grafana/dashboards/docker-monitoring.json:370:              "expr": "((node_memory_MemTotal{instance=~\"$server:.*\"} - node_memory_MemAvailable{instance=~\"$server:.*\"}) / node_memory_MemTotal{instance=~\"$server:.*\"}) * 100",
./grafana/dashboards/docker-monitoring.json:376:          "thresholds": "70, 90",
./grafana/dashboards/docker-monitoring.json:407:            "thresholdLabels": false,
./grafana/dashboards/docker-monitoring.json:408:            "thresholdMarkers": true
./grafana/dashboards/docker-monitoring.json:455:          "thresholds": "0.75, 0.90",
./grafana/dashboards/docker-monitoring.json:486:            "thresholdLabels": false,
./grafana/dashboards/docker-monitoring.json:487:            "thresholdMarkers": true
./grafana/dashboards/docker-monitoring.json:527:              "expr": "node_load1{instance=~\"$server:.*\"} / count by(job, instance)(count by(job, instance, cpu)(node_cpu{instance=~\"$server:.*\"}))",
./grafana/dashboards/docker-monitoring.json:533:          "thresholds": "0.8,0.9",
./grafana/dashboards/docker-monitoring.json:610:          "thresholds": [],
./grafana/dashboards/docker-monitoring.json:682:              "expr": "sum(rate(container_cpu_system_seconds_total[1m]))",
./grafana/dashboards/docker-monitoring.json:690:              "expr": "sum(rate(container_cpu_system_seconds_total{name=~\".+\"}[1m]))",
./grafana/dashboards/docker-monitoring.json:699:              "expr": "sum(rate(container_cpu_system_seconds_total{id=\"/\"}[1m]))",
./grafana/dashboards/docker-monitoring.json:709:              "expr": "sum(rate(process_cpu_seconds_total[$interval])) * 100",
./grafana/dashboards/docker-monitoring.json:719:              "expr": "sum(rate(container_cpu_system_seconds_total{name=~\".+\"}[1m])) + sum(rate(container_cpu_system_seconds_total{id=\"/\"}[1m])) + sum(rate(process_cpu_seconds_total[1m]))",
./grafana/dashboards/docker-monitoring.json:727:          "thresholds": [],
./grafana/dashboards/docker-monitoring.json:830:              "expr": "node_load1{instance=~\"$server:.*\"} / count by(job, instance)(count by(job, instance, cpu)(node_cpu{instance=~\"$server:.*\"}))",
./grafana/dashboards/docker-monitoring.json:836:          "thresholds": [
./grafana/dashboards/docker-monitoring.json:960:          "thresholds": [
./grafana/dashboards/docker-monitoring.json:1074:              "expr": "container_memory_rss{name=~\".+\"}",
./grafana/dashboards/docker-monitoring.json:1082:              "expr": "sum(container_memory_rss{name=~\".+\"})",
./grafana/dashboards/docker-monitoring.json:1090:              "expr": "container_memory_usage_bytes{name=~\".+\"}",
./grafana/dashboards/docker-monitoring.json:1098:              "expr": "container_memory_rss{id=\"/\"}",
./grafana/dashboards/docker-monitoring.json:1106:              "expr": "sum(container_memory_rss)",
./grafana/dashboards/docker-monitoring.json:1114:              "expr": "node_memory_Buffers",
./grafana/dashboards/docker-monitoring.json:1117:              "legendFormat": "node_memory_Dirty",
./grafana/dashboards/docker-monitoring.json:1122:              "expr": "node_memory_MemFree",
./grafana/dashboards/docker-monitoring.json:1130:              "expr": "node_memory_MemAvailable",
./grafana/dashboards/docker-monitoring.json:1138:              "expr": "node_memory_MemTotal - node_memory_MemAvailable",
./grafana/dashboards/docker-monitoring.json:1146:              "expr": "node_memory_Inactive",
./grafana/dashboards/docker-monitoring.json:1154:              "expr": "node_memory_KernelStack",
./grafana/dashboards/docker-monitoring.json:1162:              "expr": "node_memory_Active",
./grafana/dashboards/docker-monitoring.json:1170:              "expr": "node_memory_MemTotal - (node_memory_Active + node_memory_MemFree + node_memory_Inactive)",
./grafana/dashboards/docker-monitoring.json:1178:              "expr": "node_memory_MemFree + node_memory_Inactive ",
./grafana/dashboards/docker-monitoring.json:1186:              "expr": "container_memory_rss{name=~\".+\"}",
./grafana/dashboards/docker-monitoring.json:1194:              "expr": "node_memory_Inactive + node_memory_MemFree + node_memory_MemAvailable",
./grafana/dashboards/docker-monitoring.json:1202:          "thresholds": [
./grafana/dashboards/docker-monitoring.json:1279:              "expr": "sum(rate(node_disk_bytes_read[$interval])) by (device)",
./grafana/dashboards/docker-monitoring.json:1282:              "metric": "node_disk_bytes_read",
./grafana/dashboards/docker-monitoring.json:1287:              "expr": "sum(rate(node_disk_bytes_written[$interval])) by (device)",
./grafana/dashboards/docker-monitoring.json:1300:          "thresholds": [],
./grafana/dashboards/docker-monitoring.json:1385:              "expr": "sum(rate(container_cpu_usage_seconds_total{name=~\".+\"}[$interval])) by (name) * 100",
./grafana/dashboards/docker-monitoring.json:1395:          "thresholds": [],
./grafana/dashboards/docker-monitoring.json:1473:          "thresholds": [],
./grafana/dashboards/docker-monitoring.json:1575:          "thresholds": [],
./grafana/dashboards/docker-monitoring.json:1647:              "expr": "sum(container_memory_rss{name=~\".+\"}) by (name)",
./grafana/dashboards/docker-monitoring.json:1655:              "expr": "container_memory_usage_bytes{name=~\".+\"}",
./grafana/dashboards/docker-monitoring.json:1663:          "thresholds": [],
./grafana/dashboards/docker-monitoring.json:1763:          "thresholds": [],
./grafana/dashboards/docker-monitoring.json:1835:              "expr": "container_memory_rss{name=~\".+\"}",
./grafana/dashboards/docker-monitoring.json:1843:              "expr": "container_memory_usage_bytes{name=~\".+\"}",
./grafana/dashboards/docker-monitoring.json:1851:              "expr": "sum(container_memory_cache{name=~\".+\"}) by (name)",
./grafana/dashboards/docker-monitoring.json:1859:          "thresholds": [],
./grafana/dashboards/node-exporter-full.json:134:            "mode": "thresholds"
./grafana/dashboards/node-exporter-full.json:141:          "thresholds": {
./grafana/dashboards/node-exporter-full.json:194:          "expr": "irate(node_pressure_cpu_waiting_seconds_total{instance=\"$node\",job=\"$job\"}[$__rate_interval])",
./grafana/dashboards/node-exporter-full.json:210:          "expr": "irate(node_pressure_memory_waiting_seconds_total{instance=\"$node\",job=\"$job\"}[$__rate_interval])",
./grafana/dashboards/node-exporter-full.json:250:            "mode": "thresholds"
./grafana/dashboards/node-exporter-full.json:266:          "thresholds": {
./grafana/dashboards/node-exporter-full.json:316:          "expr": "100 * (1 - avg(rate(node_cpu_seconds_total{mode=\"idle\", instance=\"$node\"}[$__rate_interval])))",
./grafana/dashboards/node-exporter-full.json:338:            "mode": "thresholds"
./grafana/dashboards/node-exporter-full.json:354:          "thresholds": {
./grafana/dashboards/node-exporter-full.json:404:          "expr": "scalar(node_load1{instance=\"$node\",job=\"$job\"}) * 100 / count(count(node_cpu_seconds_total{instance=\"$node\",job=\"$job\"}) by (cpu))",
./grafana/dashboards/node-exporter-full.json:422:      "description": "Non available RAM memory",
./grafana/dashboards/node-exporter-full.json:426:            "mode": "thresholds"
./grafana/dashboards/node-exporter-full.json:432:          "thresholds": {
./grafana/dashboards/node-exporter-full.json:483:          "expr": "((node_memory_MemTotal_bytes{instance=\"$node\", job=\"$job\"} - node_memory_MemFree_bytes{instance=\"$node\", job=\"$job\"}) / node_memory_MemTotal_bytes{instance=\"$node\", job=\"$job\"}) * 100",
./grafana/dashboards/node-exporter-full.json:499:          "expr": "(1 - (node_memory_MemAvailable_bytes{instance=\"$node\", job=\"$job\"} / node_memory_MemTotal_bytes{instance=\"$node\", job=\"$job\"})) * 100",
./grafana/dashboards/node-exporter-full.json:521:            "mode": "thresholds"
./grafana/dashboards/node-exporter-full.json:537:          "thresholds": {
./grafana/dashboards/node-exporter-full.json:587:          "expr": "((node_memory_SwapTotal_bytes{instance=\"$node\",job=\"$job\"} - node_memory_SwapFree_bytes{instance=\"$node\",job=\"$job\"}) / (node_memory_SwapTotal_bytes{instance=\"$node\",job=\"$job\"})) * 100",
./grafana/dashboards/node-exporter-full.json:607:            "mode": "thresholds"
./grafana/dashboards/node-exporter-full.json:623:          "thresholds": {
./grafana/dashboards/node-exporter-full.json:694:            "mode": "thresholds"
./grafana/dashboards/node-exporter-full.json:707:          "thresholds": {
./grafana/dashboards/node-exporter-full.json:756:          "expr": "count(count(node_cpu_seconds_total{instance=\"$node\",job=\"$job\"}) by (cpu))",
./grafana/dashboards/node-exporter-full.json:775:            "mode": "thresholds"
./grafana/dashboards/node-exporter-full.json:789:          "thresholds": {
./grafana/dashboards/node-exporter-full.json:859:            "mode": "thresholds"
./grafana/dashboards/node-exporter-full.json:873:          "thresholds": {
./grafana/dashboards/node-exporter-full.json:948:            "mode": "thresholds"
./grafana/dashboards/node-exporter-full.json:962:          "thresholds": {
./grafana/dashboards/node-exporter-full.json:1011:          "expr": "node_memory_MemTotal_bytes{instance=\"$node\",job=\"$job\"}",
./grafana/dashboards/node-exporter-full.json:1031:            "mode": "thresholds"
./grafana/dashboards/node-exporter-full.json:1045:          "thresholds": {
./grafana/dashboards/node-exporter-full.json:1094:          "expr": "node_memory_SwapTotal_bytes{instance=\"$node\",job=\"$job\"}",
./grafana/dashboards/node-exporter-full.json:1168:            "thresholdsStyle": {
./grafana/dashboards/node-exporter-full.json:1175:          "thresholds": {
./grafana/dashboards/node-exporter-full.json:1328:          "expr": "sum(irate(node_cpu_seconds_total{instance=\"$node\",job=\"$job\", mode=\"system\"}[$__rate_interval])) / scalar(count(count(node_cpu_seconds_total{instance=\"$node\",job=\"$job\"}) by (cpu)))",
./grafana/dashboards/node-exporter-full.json:1344:          "expr": "sum(irate(node_cpu_seconds_total{instance=\"$node\",job=\"$job\", mode=\"user\"}[$__rate_interval])) / scalar(count(count(node_cpu_seconds_total{instance=\"$node\",job=\"$job\"}) by (cpu)))",
./grafana/dashboards/node-exporter-full.json:1359:          "expr": "sum(irate(node_cpu_seconds_total{instance=\"$node\",job=\"$job\", mode=\"iowait\"}[$__rate_interval])) / scalar(count(count(node_cpu_seconds_total{instance=\"$node\",job=\"$job\"}) by (cpu)))",
./grafana/dashboards/node-exporter-full.json:1373:          "expr": "sum(irate(node_cpu_seconds_total{instance=\"$node\",job=\"$job\", mode=~\".*irq\"}[$__rate_interval])) / scalar(count(count(node_cpu_seconds_total{instance=\"$node\",job=\"$job\"}) by (cpu)))",
./grafana/dashboards/node-exporter-full.json:1387:          "expr": "sum(irate(node_cpu_seconds_total{instance=\"$node\",job=\"$job\",  mode!='idle',mode!='user',mode!='system',mode!='iowait',mode!='irq',mode!='softirq'}[$__rate_interval])) / scalar(count(count(node_cpu_seconds_total{instance=\"$node\",job=\"$job\"}) by (cpu)))",
./grafana/dashboards/node-exporter-full.json:1401:          "expr": "sum(irate(node_cpu_seconds_total{instance=\"$node\",job=\"$job\", mode=\"idle\"}[$__rate_interval])) / scalar(count(count(node_cpu_seconds_total{instance=\"$node\",job=\"$job\"}) by (cpu)))",
./grafana/dashboards/node-exporter-full.json:1418:      "description": "Basic memory usage",
./grafana/dashboards/node-exporter-full.json:1450:            "thresholdsStyle": {
./grafana/dashboards/node-exporter-full.json:1457:          "thresholds": {
./grafana/dashboards/node-exporter-full.json:1870:          "expr": "node_memory_MemTotal_bytes{instance=\"$node\",job=\"$job\"}",
./grafana/dashboards/node-exporter-full.json:1883:          "expr": "node_memory_MemTotal_bytes{instance=\"$node\",job=\"$job\"} - node_memory_MemFree_bytes{instance=\"$node\",job=\"$job\"} - (node_memory_Cached_bytes{instance=\"$node\",job=\"$job\"} + node_memory_Buffers_bytes{instance=\"$node\",job=\"$job\"} + node_memory_SReclaimable_bytes{instance=\"$node\",job=\"$job\"})",
./grafana/dashboards/node-exporter-full.json:1896:          "expr": "node_memory_Cached_bytes{instance=\"$node\",job=\"$job\"} + node_memory_Buffers_bytes{instance=\"$node\",job=\"$job\"} + node_memory_SReclaimable_bytes{instance=\"$node\",job=\"$job\"}",
./grafana/dashboards/node-exporter-full.json:1908:          "expr": "node_memory_MemFree_bytes{instance=\"$node\",job=\"$job\"}",
./grafana/dashboards/node-exporter-full.json:1920:          "expr": "(node_memory_SwapTotal_bytes{instance=\"$node\",job=\"$job\"} - node_memory_SwapFree_bytes{instance=\"$node\",job=\"$job\"})",
./grafana/dashboards/node-exporter-full.json:1968:            "thresholdsStyle": {
./grafana/dashboards/node-exporter-full.json:1974:          "thresholds": {
./grafana/dashboards/node-exporter-full.json:2436:            "thresholdsStyle": {
./grafana/dashboards/node-exporter-full.json:2444:          "thresholds": {
./grafana/dashboards/node-exporter-full.json:2550:                "thresholdsStyle": {
./grafana/dashboards/node-exporter-full.json:2557:              "thresholds": {
./grafana/dashboards/node-exporter-full.json:2728:              "expr": "sum(irate(node_cpu_seconds_total{instance=\"$node\",job=\"$job\", mode=\"system\"}[$__rate_interval])) / scalar(count(count(node_cpu_seconds_total{instance=\"$node\",job=\"$job\"}) by (cpu)))",
./grafana/dashboards/node-exporter-full.json:2743:              "expr": "sum(irate(node_cpu_seconds_total{instance=\"$node\",job=\"$job\", mode=\"user\"}[$__rate_interval])) / scalar(count(count(node_cpu_seconds_total{instance=\"$node\",job=\"$job\"}) by (cpu)))",
./grafana/dashboards/node-exporter-full.json:2757:              "expr": "sum(irate(node_cpu_seconds_total{instance=\"$node\",job=\"$job\", mode=\"nice\"}[$__rate_interval])) / scalar(count(count(node_cpu_seconds_total{instance=\"$node\",job=\"$job\"}) by (cpu)))",
./grafana/dashboards/node-exporter-full.json:2771:              "expr": "sum by(instance) (irate(node_cpu_seconds_total{instance=\"$node\",job=\"$job\", mode=\"iowait\"}[$__rate_interval])) / scalar(count(count(node_cpu_seconds_total{instance=\"$node\",job=\"$job\"}) by (cpu)))",
./grafana/dashboards/node-exporter-full.json:2785:              "expr": "sum(irate(node_cpu_seconds_total{instance=\"$node\",job=\"$job\", mode=\"irq\"}[$__rate_interval])) / scalar(count(count(node_cpu_seconds_total{instance=\"$node\",job=\"$job\"}) by (cpu)))",
./grafana/dashboards/node-exporter-full.json:2799:              "expr": "sum(irate(node_cpu_seconds_total{instance=\"$node\",job=\"$job\", mode=\"softirq\"}[$__rate_interval])) / scalar(count(count(node_cpu_seconds_total{instance=\"$node\",job=\"$job\"}) by (cpu)))",
./grafana/dashboards/node-exporter-full.json:2813:              "expr": "sum(irate(node_cpu_seconds_total{instance=\"$node\",job=\"$job\", mode=\"steal\"}[$__rate_interval])) / scalar(count(count(node_cpu_seconds_total{instance=\"$node\",job=\"$job\"}) by (cpu)))",
./grafana/dashboards/node-exporter-full.json:2827:              "expr": "sum(irate(node_cpu_seconds_total{instance=\"$node\",job=\"$job\", mode=\"idle\"}[$__rate_interval])) / scalar(count(count(node_cpu_seconds_total{instance=\"$node\",job=\"$job\"}) by (cpu)))",
./grafana/dashboards/node-exporter-full.json:2877:                "thresholdsStyle": {
./grafana/dashboards/node-exporter-full.json:2884:              "thresholds": {
./grafana/dashboards/node-exporter-full.json:3112:                  "options": "Swap - Swap memory usage"
./grafana/dashboards/node-exporter-full.json:3172:                  "options": "Unused - Free memory unassigned"
./grafana/dashboards/node-exporter-full.json:3234:              "expr": "node_memory_MemTotal_bytes{instance=\"$node\",job=\"$job\"} - node_memory_MemFree_bytes{instance=\"$node\",job=\"$job\"} - node_memory_Buffers_bytes{instance=\"$node\",job=\"$job\"} - node_memory_Cached_bytes{instance=\"$node\",job=\"$job\"} - node_memory_Slab_bytes{instance=\"$node\",job=\"$job\"} - node_memory_PageTables_bytes{instance=\"$node\",job=\"$job\"} - node_memory_SwapCached_bytes{instance=\"$node\",job=\"$job\"}",
./grafana/dashboards/node-exporter-full.json:3247:              "expr": "node_memory_PageTables_bytes{instance=\"$node\",job=\"$job\"}",
./grafana/dashboards/node-exporter-full.json:3251:              "legendFormat": "PageTables - Memory used to map between virtual and physical memory addresses",
./grafana/dashboards/node-exporter-full.json:3260:              "expr": "node_memory_SwapCached_bytes{instance=\"$node\",job=\"$job\"}",
./grafana/dashboards/node-exporter-full.json:3272:              "expr": "node_memory_Slab_bytes{instance=\"$node\",job=\"$job\"}",
./grafana/dashboards/node-exporter-full.json:3285:              "expr": "node_memory_Cached_bytes{instance=\"$node\",job=\"$job\"}",
./grafana/dashboards/node-exporter-full.json:3298:              "expr": "node_memory_Buffers_bytes{instance=\"$node\",job=\"$job\"}",
./grafana/dashboards/node-exporter-full.json:3302:              "legendFormat": "Buffers - Block device (e.g. harddisk) cache",
./grafana/dashboards/node-exporter-full.json:3311:              "expr": "node_memory_MemFree_bytes{instance=\"$node\",job=\"$job\"}",
./grafana/dashboards/node-exporter-full.json:3315:              "legendFormat": "Unused - Free memory unassigned",
./grafana/dashboards/node-exporter-full.json:3324:              "expr": "(node_memory_SwapTotal_bytes{instance=\"$node\",job=\"$job\"} - node_memory_SwapFree_bytes{instance=\"$node\",job=\"$job\"})",
./grafana/dashboards/node-exporter-full.json:3337:              "expr": "node_memory_HardwareCorrupted_bytes{instance=\"$node\",job=\"$job\"}",
./grafana/dashboards/node-exporter-full.json:3385:                "thresholdsStyle": {
./grafana/dashboards/node-exporter-full.json:3391:              "thresholds": {
./grafana/dashboards/node-exporter-full.json:3572:                "thresholdsStyle": {
./grafana/dashboards/node-exporter-full.json:3579:              "thresholds": {
./grafana/dashboards/node-exporter-full.json:3675:                "thresholdsStyle": {
./grafana/dashboards/node-exporter-full.json:3681:              "thresholds": {
./grafana/dashboards/node-exporter-full.json:4057:              "expr": "irate(node_disk_reads_completed_total{instance=\"$node\",job=\"$job\",device=~\"$diskdevices\"}[$__rate_interval])",
./grafana/dashboards/node-exporter-full.json:4068:              "expr": "irate(node_disk_writes_completed_total{instance=\"$node\",job=\"$job\",device=~\"$diskdevices\"}[$__rate_interval])",
./grafana/dashboards/node-exporter-full.json:4115:                "thresholdsStyle": {
./grafana/dashboards/node-exporter-full.json:4121:              "thresholds": {
./grafana/dashboards/node-exporter-full.json:4284:              "expr": "irate(node_disk_read_bytes_total{instance=\"$node\",job=\"$job\",device=~\"$diskdevices\"}[$__rate_interval])",
./grafana/dashboards/node-exporter-full.json:4297:              "expr": "irate(node_disk_written_bytes_total{instance=\"$node\",job=\"$job\",device=~\"$diskdevices\"}[$__rate_interval])",
./grafana/dashboards/node-exporter-full.json:4346:                "thresholdsStyle": {
./grafana/dashboards/node-exporter-full.json:4353:              "thresholds": {
./grafana/dashboards/node-exporter-full.json:4429:              "expr": "irate(node_disk_io_time_seconds_total{instance=\"$node\",job=\"$job\",device=~\"$diskdevices\"} [$__rate_interval])",
./grafana/dashboards/node-exporter-full.json:4478:                "thresholdsStyle": {
./grafana/dashboards/node-exporter-full.json:4484:              "thresholds": {
./grafana/dashboards/node-exporter-full.json:4562:              "expr": "sum by(instance) (irate(node_cpu_guest_seconds_total{instance=\"$node\",job=\"$job\", mode=\"user\"}[1m])) / on(instance) group_left sum by (instance)((irate(node_cpu_seconds_total{instance=\"$node\",job=\"$job\"}[1m])))",
./grafana/dashboards/node-exporter-full.json:4574:              "expr": "sum by(instance) (irate(node_cpu_guest_seconds_total{instance=\"$node\",job=\"$job\", mode=\"nice\"}[1m])) / on(instance) group_left sum by (instance)((irate(node_cpu_seconds_total{instance=\"$node\",job=\"$job\"}[1m])))",
./grafana/dashboards/node-exporter-full.json:4647:                "thresholdsStyle": {
./grafana/dashboards/node-exporter-full.json:4654:              "thresholds": {
./grafana/dashboards/node-exporter-full.json:4959:              "expr": "node_memory_Inactive_bytes{instance=\"$node\",job=\"$job\"}",
```

## 6-5.13 Runtime Audit Interpretation

```text
6-5.1 Host inventory collected OK ✅
6-5.2 Observability docker inventory collected OK ✅
6-5.3 Observability systemd inventory collected OK ✅
6-5.4 Observability ports inventory collected OK ✅
6-5.5 Prometheus ready probe collected OK ✅
6-5.6 Prometheus targets probe collected OK ✅
6-5.7 Grafana health probe collected OK ✅
6-5.8 Node exporter probe collected OK ✅
6-5.9 cAdvisor probe collected OK ✅
6-5.10 Pix2pi health/metrics probe collected OK ✅
6-5.11 Observability config inventory collected OK ✅
6-5.12 Alert/rule inventory collected OK ✅
FAZ_6_5_RUNTIME_AUDIT=COMPLETE ✅
```
