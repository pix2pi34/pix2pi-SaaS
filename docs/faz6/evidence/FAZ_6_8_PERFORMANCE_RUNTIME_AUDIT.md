# FAZ 6-8 Performance Runtime Audit Evidence

Generated At: 2026-05-01T15:04:28+03:00  
Host: vm12827.ovadns.com  
Repo: /root/pix2pi/pix2pi-SaaS  

Bu audit runtime ortaminda performance / load / stress readiness sinyallerini toplar. Agir load test calistirmaz.

FAZ_6_8_RUNTIME_AUDIT=STARTED ✅

---


## 6-8.1 Host / Kernel

```text
Linux vm12827.ovadns.com 5.15.0-176-generic #186-Ubuntu SMP Fri Mar 13 11:01:42 UTC 2026 x86_64 x86_64 x86_64 GNU/Linux
```

## 6-8.2 Uptime / Load Average

```text
 15:04:28 up 9 days,  8:23,  2 users,  load average: 0.17, 0.41, 0.50
```

## 6-8.3 Memory Snapshot

```text
               total        used        free      shared  buff/cache   available
Mem:            15Gi       2.0Gi       9.7Gi        55Mi       4.0Gi        13Gi
Swap:          2.0Gi        14Mi       2.0Gi
```

## 6-8.4 Disk Usage

```text
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
overlay                            194G   84G  103G  45% /var/lib/docker/overlay2/c432d53e3d3897c3ba88018f53ad40d87dd7841841c7bbf3eda5fd79be51e312/merged
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
```

## 6-8.5 Process CPU Memory Top

```text
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root        2183  5.9  0.6 1331440 99576 ?       Ssl  Apr22 797:54 /usr/bin/cadvisor -logtostderr
root      462074  3.3  0.0  10456  6648 pts/1    R+   14:30   1:09 htop
root        1222  1.4  0.4 5155652 80056 ?       Ssl  Apr22 194:50 /usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock
root        2106  0.6  0.2 2061464 43080 ?       Ssl  Apr22  82:01 /usr/bin/promtail -config.file=/etc/promtail/config.yml
lxd         2143  0.6  0.0  48352  7280 ?        Ssl  Apr22  84:43 redis-server *:6379
472         2041  0.5  0.9 1764140 162808 ?      Ssl  Apr22  76:44 grafana server --homepath=/usr/share/grafana --config=/etc/grafana/grafana.ini --packaging=docker cfg:default.log.mode=console cfg:default.paths.data=/var/lib/grafana cfg:default.paths.logs=/var/log/grafana cfg:default.paths.plugins=/var/lib/grafana/plugins cfg:default.paths.provisioning=/etc/grafana/provisioning
10001       2074  0.4  0.4 1362640 69532 ?       Ssl  Apr22  65:48 /usr/bin/loki -config.file=/etc/loki/local-config.yaml
root        1000  0.2  0.2 3049516 40492 ?       Ssl  Apr22  29:16 /usr/bin/containerd
root        2029  0.2  0.0 1241604 12144 ?       Ssl  Apr22  36:18 nats-server -js -sd /data
1000        4513  0.2  0.8 2579212 136968 ?      S    Apr22  30:47 nginx: worker process
1000        4514  0.2  0.8 2578056 135384 ?      S    Apr22  30:22 nginx: worker process
1000        4515  0.2  0.8 2578632 135976 ?      S    Apr22  29:52 nginx: worker process
1000        4516  0.2  0.8 2580680 138012 ?      S    Apr22  29:49 nginx: worker process
1000        4517  0.2  0.8 2579720 137244 ?      S    Apr22  29:24 nginx: worker process
1000        4518  0.2  0.8 2578632 136020 ?      S    Apr22  29:51 nginx: worker process
1000        4519  0.2  0.8 2579720 137100 ?      S    Apr22  29:39 nginx: worker process
1000        4520  0.2  0.8 2578312 135688 ?      S    Apr22  30:31 nginx: worker process
root          14  0.1  0.0      0     0 ?        I    Apr22  18:18 [rcu_sched]
root         822  0.1  0.0 241912  9420 ?        Ssl  Apr22  16:35 /usr/bin/vmtoolsd

USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
472         2041  0.5  0.9 1764140 162808 ?      Ssl  Apr22  76:44 grafana server --homepath=/usr/share/grafana --config=/etc/grafana/grafana.ini --packaging=docker cfg:default.log.mode=console cfg:default.paths.data=/var/lib/grafana cfg:default.paths.logs=/var/log/grafana cfg:default.paths.plugins=/var/lib/grafana/plugins cfg:default.paths.provisioning=/etc/grafana/provisioning
1000        4516  0.2  0.8 2580680 138012 ?      S    Apr22  29:49 nginx: worker process
1000        4517  0.2  0.8 2579720 137244 ?      S    Apr22  29:24 nginx: worker process
1000        4519  0.2  0.8 2579720 137100 ?      S    Apr22  29:39 nginx: worker process
1000        4513  0.2  0.8 2579212 136968 ?      S    Apr22  30:47 nginx: worker process
1000        4518  0.2  0.8 2578632 136020 ?      S    Apr22  29:51 nginx: worker process
1000        4515  0.2  0.8 2578632 135976 ?      S    Apr22  29:52 nginx: worker process
1000        4520  0.2  0.8 2578312 135688 ?      S    Apr22  30:31 nginx: worker process
1000        4514  0.2  0.8 2578056 135384 ?      S    Apr22  30:22 nginx: worker process
root         555  0.0  0.7 170636 123476 ?       S<s  Apr22   4:51 /lib/systemd/systemd-journald
root        2183  5.9  0.6 1331440 99576 ?       Ssl  Apr22 797:54 /usr/bin/cadvisor -logtostderr
root        1222  1.4  0.4 5155652 80056 ?       Ssl  Apr22 194:50 /usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock
10001       2074  0.4  0.4 1362640 69532 ?       Ssl  Apr22  65:48 /usr/bin/loki -config.file=/etc/loki/local-config.yaml
nobody      2086  0.1  0.4 1937060 69496 ?       Ssl  Apr22  17:11 /bin/prometheus --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/prometheus
10001       2093  0.0  0.3 1302368 57936 ?       Ssl  Apr22  13:23 /tempo -config.file=/etc/tempo/tempo.yml
1000        2172  0.0  0.3 392544 54388 ?        Ss   Apr22   0:01 nginx: master process /usr/local/openresty/nginx/sbin/nginx -p /usr/local/kong -c nginx.conf
root     1700080  0.1  0.3 918716 52388 ?        Ssl  Apr24  10:41 /usr/bin/python3 /usr/bin/fail2ban-server -xf start
root        2106  0.6  0.2 2061464 43080 ?       Ssl  Apr22  82:01 /usr/bin/promtail -config.file=/etc/promtail/config.yml
root        1000  0.2  0.2 3049516 40492 ?       Ssl  Apr22  29:16 /usr/bin/containerd
```

## 6-8.6 Docker Stats Snapshot

```text
NAME                      CPU %     MEM USAGE / LIMIT     NET I/O           BLOCK I/O         PIDS
pix2pi-redis              0.84%     8.113MiB / 15.61GiB   4.65MB / 4.78MB   22.7MB / 582kB    8
pix2pi_pg_replica         0.00%     65.86MiB / 15.61GiB   40.5MB / 11.6MB   106MB / 212MB     5
pix2pi-mission-control    0.00%     4.891MiB / 15.61GiB   30.1kB / 5.99kB   15.5MB / 0B       5
pix2pi-service-registry   0.00%     3.238MiB / 15.61GiB   0B / 0B           11.1MB / 49.2kB   5
pix2pi-identity-api       0.00%     5.137MiB / 15.61GiB   47.9kB / 23.4kB   15MB / 0B         5
pix2pi_grafana            0.48%     159.2MiB / 15.61GiB   12.1MB / 133MB    573MB / 1.16GB    17
pix2pi_promtail           0.54%     46.41MiB / 15.61GiB   24.9kB / 1.91kB   141MB / 662MB     11
pix2pi_loki               0.43%     67.32MiB / 15.61GiB   457kB / 1.25MB    141MB / 1.43MB    13
pix2pi_prometheus         0.00%     72.76MiB / 15.61GiB   681MB / 39.8MB    272MB / 2.56GB    14
pix2pi_node_exporter      0.00%     18.64MiB / 15.61GiB   37.4MB / 682MB    34.9MB / 0B       5
pix2pi_nats               0.23%     13.41MiB / 15.61GiB   17.2MB / 15.5MB   34.9MB / 131kB    12
pix2pi_tempo              0.06%     49.08MiB / 15.61GiB   486kB / 683kB     149MB / 434kB     13
pix2pi-api-gateway        1.80%     1.022GiB / 15.61GiB   0B / 0B           69.1MB / 1.16MB   9
pix2pi_pg                 0.00%     35.28MiB / 15.61GiB   6.36MB / 13.7MB   27.2MB / 8.42MB   7
pix2pi_cadvisor           5.81%     100.7MiB / 15.61GiB   1.71MB / 47.2MB   73.5MB / 213kB    23
```

## 6-8.7 Docker Runtime Containers

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

## 6-8.8 Listening Ports

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

## 6-8.9 Safe Health Timing Probe

```text
===== http://127.0.0.1:9001/health =====
curl: (7) Failed to connect to 127.0.0.1 port 9001 after 0 ms: Connection refused
http_code=000 time_total=0.000398 time_connect=0.000000 size=0
WARN ⚠️ probe failed
===== http://127.0.0.1:9010/health =====
http_code=200 time_total=0.001366 time_connect=0.000644 size=21
===== http://127.0.0.1:9090/-/ready =====
http_code=200 time_total=0.001750 time_connect=0.000494 size=28
===== http://127.0.0.1:3000/api/health =====
curl: (7) Failed to connect to 127.0.0.1 port 3000 after 0 ms: Connection refused
http_code=000 time_total=0.000258 time_connect=0.000000 size=0
WARN ⚠️ probe failed
===== http://127.0.0.1:8222/varz =====
curl: (56) Recv failure: Connection reset by peer
http_code=000 time_total=0.001048 time_connect=0.000174 size=0
WARN ⚠️ probe failed
```

## 6-8.10 Prometheus Targets / Metrics Probe

```text
{"status":"success","data":{"activeTargets":[{"discoveredLabels":{"__address__":"node_exporter:9100","__metrics_path__":"/metrics","__scheme__":"http","__scrape_interval__":"15s","__scrape_timeout__":"10s","job":"node_exporter"},"labels":{"instance":"node_exporter:9100","job":"node_exporter"},"scrapePool":"node_exporter","scrapeUrl":"http://node_exporter:9100/metrics","globalUrl":"http://node_exporter:9100/metrics","lastError":"","lastScrape":"2026-05-01T12:04:23.529394354Z","lastScrapeDuration":0.024671245,"health":"up","scrapeInterval":"15s","scrapeTimeout":"10s"},{"discoveredLabels":{"__address__":"prometheus:9090","__metrics_path__":"/metrics","__scheme__":"http","__scrape_interval__":"15s","__scrape_timeout__":"10s","job":"prometheus"},"labels":{"instance":"prometheus:9090","job":"prometheus"},"scrapePool":"prometheus","scrapeUrl":"http://prometheus:9090/metrics","globalUrl":"http://prometheus:9090/metrics","lastError":"","lastScrape":"2026-05-01T12:04:25.829484212Z","lastScrapeDuration":0.0086392,"health":"up","scrapeInterval":"15s","scrapeTimeout":"10s"}],"droppedTargets":[],"droppedTargetCounts":{"node_exporter":0,"prometheus":0}}}```

## 6-8.11 Node Exporter Key Metrics Probe

```text
# HELP node_cpu_seconds_total Seconds the CPUs spent in each mode.
# TYPE node_cpu_seconds_total counter
node_cpu_seconds_total{cpu="0",mode="idle"} 783911.65
node_cpu_seconds_total{cpu="0",mode="iowait"} 33.15
node_cpu_seconds_total{cpu="0",mode="irq"} 0
node_cpu_seconds_total{cpu="0",mode="nice"} 11.28
node_cpu_seconds_total{cpu="0",mode="softirq"} 3663.26
node_cpu_seconds_total{cpu="0",mode="steal"} 0
node_cpu_seconds_total{cpu="0",mode="system"} 7543.04
node_cpu_seconds_total{cpu="0",mode="user"} 12123.08
node_cpu_seconds_total{cpu="1",mode="idle"} 783936.25
node_cpu_seconds_total{cpu="1",mode="iowait"} 34.49
node_cpu_seconds_total{cpu="1",mode="irq"} 0
node_cpu_seconds_total{cpu="1",mode="nice"} 16
node_cpu_seconds_total{cpu="1",mode="softirq"} 1565.84
node_cpu_seconds_total{cpu="1",mode="steal"} 0
node_cpu_seconds_total{cpu="1",mode="system"} 7563.5
node_cpu_seconds_total{cpu="1",mode="user"} 12210.64
node_cpu_seconds_total{cpu="2",mode="idle"} 783681.83
node_cpu_seconds_total{cpu="2",mode="iowait"} 43.79
node_cpu_seconds_total{cpu="2",mode="irq"} 0
node_cpu_seconds_total{cpu="2",mode="nice"} 25.46
node_cpu_seconds_total{cpu="2",mode="softirq"} 750.41
node_cpu_seconds_total{cpu="2",mode="steal"} 0
node_cpu_seconds_total{cpu="2",mode="system"} 7544.4
node_cpu_seconds_total{cpu="2",mode="user"} 12168.61
node_cpu_seconds_total{cpu="3",mode="idle"} 782364.12
node_cpu_seconds_total{cpu="3",mode="iowait"} 32.6
node_cpu_seconds_total{cpu="3",mode="irq"} 0
node_cpu_seconds_total{cpu="3",mode="nice"} 4.94
node_cpu_seconds_total{cpu="3",mode="softirq"} 348.56
node_cpu_seconds_total{cpu="3",mode="steal"} 0
node_cpu_seconds_total{cpu="3",mode="system"} 9055.46
node_cpu_seconds_total{cpu="3",mode="user"} 12096.67
node_cpu_seconds_total{cpu="4",mode="idle"} 784074.59
node_cpu_seconds_total{cpu="4",mode="iowait"} 32.91
node_cpu_seconds_total{cpu="4",mode="irq"} 0
node_cpu_seconds_total{cpu="4",mode="nice"} 15.24
node_cpu_seconds_total{cpu="4",mode="softirq"} 211.5
node_cpu_seconds_total{cpu="4",mode="steal"} 0
```

## 6-8.12 cAdvisor Key Metrics Probe

```text
# HELP container_cpu_usage_seconds_total Cumulative cpu time consumed in seconds.
# TYPE container_cpu_usage_seconds_total counter
container_cpu_usage_seconds_total{container_label_com_docker_compose_config_hash="",container_label_com_docker_compose_container_number="",container_label_com_docker_compose_depends_on="",container_label_com_docker_compose_image="",container_label_com_docker_compose_oneoff="",container_label_com_docker_compose_project="",container_label_com_docker_compose_project_config_files="",container_label_com_docker_compose_project_working_dir="",container_label_com_docker_compose_service="",container_label_com_docker_compose_version="",container_label_maintainer="",container_label_org_opencontainers_image_authors="",container_label_org_opencontainers_image_created="",container_label_org_opencontainers_image_description="",container_label_org_opencontainers_image_documentation="",container_label_org_opencontainers_image_licenses="",container_label_org_opencontainers_image_ref_name="",container_label_org_opencontainers_image_revision="",container_label_org_opencontainers_image_source="",container_label_org_opencontainers_image_title="",container_label_org_opencontainers_image_url="",container_label_org_opencontainers_image_vendor="",container_label_org_opencontainers_image_version="",cpu="total",id="/",image="",name=""} 167086.992 1777637070889
container_cpu_usage_seconds_total{container_label_com_docker_compose_config_hash="",container_label_com_docker_compose_container_number="",container_label_com_docker_compose_depends_on="",container_label_com_docker_compose_image="",container_label_com_docker_compose_oneoff="",container_label_com_docker_compose_project="",container_label_com_docker_compose_project_config_files="",container_label_com_docker_compose_project_working_dir="",container_label_com_docker_compose_service="",container_label_com_docker_compose_version="",container_label_maintainer="",container_label_org_opencontainers_image_authors="",container_label_org_opencontainers_image_created="",container_label_org_opencontainers_image_description="",container_label_org_opencontainers_image_documentation="",container_label_org_opencontainers_image_licenses="",container_label_org_opencontainers_image_ref_name="",container_label_org_opencontainers_image_revision="",container_label_org_opencontainers_image_source="",container_label_org_opencontainers_image_title="",container_label_org_opencontainers_image_url="",container_label_org_opencontainers_image_vendor="",container_label_org_opencontainers_image_version="",cpu="total",id="/init.scope",image="",name=""} 330.049794 1777637070251
container_cpu_usage_seconds_total{container_label_com_docker_compose_config_hash="",container_label_com_docker_compose_container_number="",container_label_com_docker_compose_depends_on="",container_label_com_docker_compose_image="",container_label_com_docker_compose_oneoff="",container_label_com_docker_compose_project="",container_label_com_docker_compose_project_config_files="",container_label_com_docker_compose_project_working_dir="",container_label_com_docker_compose_service="",container_label_com_docker_compose_version="",container_label_maintainer="",container_label_org_opencontainers_image_authors="",container_label_org_opencontainers_image_created="",container_label_org_opencontainers_image_description="",container_label_org_opencontainers_image_documentation="",container_label_org_opencontainers_image_licenses="",container_label_org_opencontainers_image_ref_name="",container_label_org_opencontainers_image_revision="",container_label_org_opencontainers_image_source="",container_label_org_opencontainers_image_title="",container_label_org_opencontainers_image_url="",container_label_org_opencontainers_image_vendor="",container_label_org_opencontainers_image_version="",cpu="total",id="/system.slice",image="",name=""} 163024.649031 1777637070419
container_cpu_usage_seconds_total{container_label_com_docker_compose_config_hash="",container_label_com_docker_compose_container_number="",container_label_com_docker_compose_depends_on="",container_label_com_docker_compose_image="",container_label_com_docker_compose_oneoff="",container_label_com_docker_compose_project="",container_label_com_docker_compose_project_config_files="",container_label_com_docker_compose_project_working_dir="",container_label_com_docker_compose_service="",container_label_com_docker_compose_version="",container_label_maintainer="",container_label_org_opencontainers_image_authors="",container_label_org_opencontainers_image_created="",container_label_org_opencontainers_image_description="",container_label_org_opencontainers_image_documentation="",container_label_org_opencontainers_image_licenses="",container_label_org_opencontainers_image_ref_name="",container_label_org_opencontainers_image_revision="",container_label_org_opencontainers_image_source="",container_label_org_opencontainers_image_title="",container_label_org_opencontainers_image_url="",container_label_org_opencontainers_image_vendor="",container_label_org_opencontainers_image_version="",cpu="total",id="/system.slice/ModemManager.service",image="",name=""} 0.313798 1777637046642
container_cpu_usage_seconds_total{container_label_com_docker_compose_config_hash="",container_label_com_docker_compose_container_number="",container_label_com_docker_compose_depends_on="",container_label_com_docker_compose_image="",container_label_com_docker_compose_oneoff="",container_label_com_docker_compose_project="",container_label_com_docker_compose_project_config_files="",container_label_com_docker_compose_project_working_dir="",container_label_com_docker_compose_service="",container_label_com_docker_compose_version="",container_label_maintainer="",container_label_org_opencontainers_image_authors="",container_label_org_opencontainers_image_created="",container_label_org_opencontainers_image_description="",container_label_org_opencontainers_image_documentation="",container_label_org_opencontainers_image_licenses="",container_label_org_opencontainers_image_ref_name="",container_label_org_opencontainers_image_revision="",container_label_org_opencontainers_image_source="",container_label_org_opencontainers_image_title="",container_label_org_opencontainers_image_url="",container_label_org_opencontainers_image_vendor="",container_label_org_opencontainers_image_version="",cpu="total",id="/system.slice/containerd.service",image="",name=""} 5714.228209 1777637070104
container_cpu_usage_seconds_total{container_label_com_docker_compose_config_hash="",container_label_com_docker_compose_container_number="",container_label_com_docker_compose_depends_on="",container_label_com_docker_compose_image="",container_label_com_docker_compose_oneoff="",container_label_com_docker_compose_project="",container_label_com_docker_compose_project_config_files="",container_label_com_docker_compose_project_working_dir="",container_label_com_docker_compose_service="",container_label_com_docker_compose_version="",container_label_maintainer="",container_label_org_opencontainers_image_authors="",container_label_org_opencontainers_image_created="",container_label_org_opencontainers_image_description="",container_label_org_opencontainers_image_documentation="",container_label_org_opencontainers_image_licenses="",container_label_org_opencontainers_image_ref_name="",container_label_org_opencontainers_image_revision="",container_label_org_opencontainers_image_source="",container_label_org_opencontainers_image_title="",container_label_org_opencontainers_image_url="",container_label_org_opencontainers_image_vendor="",container_label_org_opencontainers_image_version="",cpu="total",id="/system.slice/cron.service",image="",name=""} 27838.6332 1777637070764
container_cpu_usage_seconds_total{container_label_com_docker_compose_config_hash="",container_label_com_docker_compose_container_number="",container_label_com_docker_compose_depends_on="",container_label_com_docker_compose_image="",container_label_com_docker_compose_oneoff="",container_label_com_docker_compose_project="",container_label_com_docker_compose_project_config_files="",container_label_com_docker_compose_project_working_dir="",container_label_com_docker_compose_service="",container_label_com_docker_compose_version="",container_label_maintainer="",container_label_org_opencontainers_image_authors="",container_label_org_opencontainers_image_created="",container_label_org_opencontainers_image_description="",container_label_org_opencontainers_image_documentation="",container_label_org_opencontainers_image_licenses="",container_label_org_opencontainers_image_ref_name="",container_label_org_opencontainers_image_revision="",container_label_org_opencontainers_image_source="",container_label_org_opencontainers_image_title="",container_label_org_opencontainers_image_url="",container_label_org_opencontainers_image_vendor="",container_label_org_opencontainers_image_version="",cpu="total",id="/system.slice/dbus.service",image="",name=""} 4.685764 1777637069639
container_cpu_usage_seconds_total{container_label_com_docker_compose_config_hash="",container_label_com_docker_compose_container_number="",container_label_com_docker_compose_depends_on="",container_label_com_docker_compose_image="",container_label_com_docker_compose_oneoff="",container_label_com_docker_compose_project="",container_label_com_docker_compose_project_config_files="",container_label_com_docker_compose_project_working_dir="",container_label_com_docker_compose_service="",container_label_com_docker_compose_version="",container_label_maintainer="",container_label_org_opencontainers_image_authors="",container_label_org_opencontainers_image_created="",container_label_org_opencontainers_image_description="",container_label_org_opencontainers_image_documentation="",container_label_org_opencontainers_image_licenses="",container_label_org_opencontainers_image_ref_name="",container_label_org_opencontainers_image_revision="",container_label_org_opencontainers_image_source="",container_label_org_opencontainers_image_title="",container_label_org_opencontainers_image_url="",container_label_org_opencontainers_image_vendor="",container_label_org_opencontainers_image_version="",cpu="total",id="/system.slice/docker-abeb5a39998fd401bdf6f8db0cb5399d86fb417ecba254d03a959c96283b6bbb.scope",image="gcr.io/cadvisor/cadvisor:latest",name="pix2pi_cadvisor"} 48225.202862 1777637070077
container_cpu_usage_seconds_total{container_label_com_docker_compose_config_hash="",container_label_com_docker_compose_container_number="",container_label_com_docker_compose_depends_on="",container_label_com_docker_compose_image="",container_label_com_docker_compose_oneoff="",container_label_com_docker_compose_project="",container_label_com_docker_compose_project_config_files="",container_label_com_docker_compose_project_working_dir="",container_label_com_docker_compose_service="",container_label_com_docker_compose_version="",container_label_maintainer="",container_label_org_opencontainers_image_authors="",container_label_org_opencontainers_image_created="",container_label_org_opencontainers_image_description="",container_label_org_opencontainers_image_documentation="",container_label_org_opencontainers_image_licenses="",container_label_org_opencontainers_image_ref_name="",container_label_org_opencontainers_image_revision="",container_label_org_opencontainers_image_source="",container_label_org_opencontainers_image_title="",container_label_org_opencontainers_image_url="",container_label_org_opencontainers_image_vendor="",container_label_org_opencontainers_image_version="",cpu="total",id="/system.slice/docker.service",image="",name=""} 11761.178193 1777637070648
container_cpu_usage_seconds_total{container_label_com_docker_compose_config_hash="",container_label_com_docker_compose_container_number="",container_label_com_docker_compose_depends_on="",container_label_com_docker_compose_image="",container_label_com_docker_compose_oneoff="",container_label_com_docker_compose_project="",container_label_com_docker_compose_project_config_files="",container_label_com_docker_compose_project_working_dir="",container_label_com_docker_compose_service="",container_label_com_docker_compose_version="",container_label_maintainer="",container_label_org_opencontainers_image_authors="",container_label_org_opencontainers_image_created="",container_label_org_opencontainers_image_description="",container_label_org_opencontainers_image_documentation="",container_label_org_opencontainers_image_licenses="",container_label_org_opencontainers_image_ref_name="",container_label_org_opencontainers_image_revision="",container_label_org_opencontainers_image_source="",container_label_org_opencontainers_image_title="",container_label_org_opencontainers_image_url="",container_label_org_opencontainers_image_vendor="",container_label_org_opencontainers_image_version="",cpu="total",id="/system.slice/docker.socket",image="",name=""} 0.001314 1777637063104
container_cpu_usage_seconds_total{container_label_com_docker_compose_config_hash="",container_label_com_docker_compose_container_number="",container_label_com_docker_compose_depends_on="",container_label_com_docker_compose_image="",container_label_com_docker_compose_oneoff="",container_label_com_docker_compose_project="",container_label_com_docker_compose_project_config_files="",container_label_com_docker_compose_project_working_dir="",container_label_com_docker_compose_service="",container_label_com_docker_compose_version="",container_label_maintainer="",container_label_org_opencontainers_image_authors="",container_label_org_opencontainers_image_created="",container_label_org_opencontainers_image_description="",container_label_org_opencontainers_image_documentation="",container_label_org_opencontainers_image_licenses="",container_label_org_opencontainers_image_ref_name="",container_label_org_opencontainers_image_revision="",container_label_org_opencontainers_image_source="",container_label_org_opencontainers_image_title="",container_label_org_opencontainers_image_url="",container_label_org_opencontainers_image_vendor="",container_label_org_opencontainers_image_version="",cpu="total",id="/system.slice/fail2ban.service",image="",name=""} 648.329265 1777637069986
container_cpu_usage_seconds_total{container_label_com_docker_compose_config_hash="",container_label_com_docker_compose_container_number="",container_label_com_docker_compose_depends_on="",container_label_com_docker_compose_image="",container_label_com_docker_compose_oneoff="",container_label_com_docker_compose_project="",container_label_com_docker_compose_project_config_files="",container_label_com_docker_compose_project_working_dir="",container_label_com_docker_compose_service="",container_label_com_docker_compose_version="",container_label_maintainer="",container_label_org_opencontainers_image_authors="",container_label_org_opencontainers_image_created="",container_label_org_opencontainers_image_description="",container_label_org_opencontainers_image_documentation="",container_label_org_opencontainers_image_licenses="",container_label_org_opencontainers_image_ref_name="",container_label_org_opencontainers_image_revision="",container_label_org_opencontainers_image_source="",container_label_org_opencontainers_image_title="",container_label_org_opencontainers_image_url="",container_label_org_opencontainers_image_vendor="",container_label_org_opencontainers_image_version="",cpu="total",id="/system.slice/irqbalance.service",image="",name=""} 41.742826 1777637067208
container_cpu_usage_seconds_total{container_label_com_docker_compose_config_hash="",container_label_com_docker_compose_container_number="",container_label_com_docker_compose_depends_on="",container_label_com_docker_compose_image="",container_label_com_docker_compose_oneoff="",container_label_com_docker_compose_project="",container_label_com_docker_compose_project_config_files="",container_label_com_docker_compose_project_working_dir="",container_label_com_docker_compose_service="",container_label_com_docker_compose_version="",container_label_maintainer="",container_label_org_opencontainers_image_authors="",container_label_org_opencontainers_image_created="",container_label_org_opencontainers_image_description="",container_label_org_opencontainers_image_documentation="",container_label_org_opencontainers_image_licenses="",container_label_org_opencontainers_image_ref_name="",container_label_org_opencontainers_image_revision="",container_label_org_opencontainers_image_source="",container_label_org_opencontainers_image_title="",container_label_org_opencontainers_image_url="",container_label_org_opencontainers_image_vendor="",container_label_org_opencontainers_image_version="",cpu="total",id="/system.slice/multipathd.service",image="",name=""} 84.069963 1777637069415
container_cpu_usage_seconds_total{container_label_com_docker_compose_config_hash="",container_label_com_docker_compose_container_number="",container_label_com_docker_compose_depends_on="",container_label_com_docker_compose_image="",container_label_com_docker_compose_oneoff="",container_label_com_docker_compose_project="",container_label_com_docker_compose_project_config_files="",container_label_com_docker_compose_project_working_dir="",container_label_com_docker_compose_service="",container_label_com_docker_compose_version="",container_label_maintainer="",container_label_org_opencontainers_image_authors="",container_label_org_opencontainers_image_created="",container_label_org_opencontainers_image_description="",container_label_org_opencontainers_image_documentation="",container_label_org_opencontainers_image_licenses="",container_label_org_opencontainers_image_ref_name="",container_label_org_opencontainers_image_revision="",container_label_org_opencontainers_image_source="",container_label_org_opencontainers_image_title="",container_label_org_opencontainers_image_url="",container_label_org_opencontainers_image_vendor="",container_label_org_opencontainers_image_version="",cpu="total",id="/system.slice/networkd-dispatcher.service",image="",name=""} 0.330625 1777637064970
container_cpu_usage_seconds_total{container_label_com_docker_compose_config_hash="",container_label_com_docker_compose_container_number="",container_label_com_docker_compose_depends_on="",container_label_com_docker_compose_image="",container_label_com_docker_compose_oneoff="",container_label_com_docker_compose_project="",container_label_com_docker_compose_project_config_files="",container_label_com_docker_compose_project_working_dir="",container_label_com_docker_compose_service="",container_label_com_docker_compose_version="",container_label_maintainer="",container_label_org_opencontainers_image_authors="",container_label_org_opencontainers_image_created="",container_label_org_opencontainers_image_description="",container_label_org_opencontainers_image_documentation="",container_label_org_opencontainers_image_licenses="",container_label_org_opencontainers_image_ref_name="",container_label_org_opencontainers_image_revision="",container_label_org_opencontainers_image_source="",container_label_org_opencontainers_image_title="",container_label_org_opencontainers_image_url="",container_label_org_opencontainers_image_vendor="",container_label_org_opencontainers_image_version="",cpu="total",id="/system.slice/nginx.service",image="",name=""} 3.201493 1777637068823
container_cpu_usage_seconds_total{container_label_com_docker_compose_config_hash="",container_label_com_docker_compose_container_number="",container_label_com_docker_compose_depends_on="",container_label_com_docker_compose_image="",container_label_com_docker_compose_oneoff="",container_label_com_docker_compose_project="",container_label_com_docker_compose_project_config_files="",container_label_com_docker_compose_project_working_dir="",container_label_com_docker_compose_service="",container_label_com_docker_compose_version="",container_label_maintainer="",container_label_org_opencontainers_image_authors="",container_label_org_opencontainers_image_created="",container_label_org_opencontainers_image_description="",container_label_org_opencontainers_image_documentation="",container_label_org_opencontainers_image_licenses="",container_label_org_opencontainers_image_ref_name="",container_label_org_opencontainers_image_revision="",container_label_org_opencontainers_image_source="",container_label_org_opencontainers_image_title="",container_label_org_opencontainers_image_url="",container_label_org_opencontainers_image_vendor="",container_label_org_opencontainers_image_version="",cpu="total",id="/system.slice/ollama.service",image="",name=""} 21.324279 1777637070698
container_cpu_usage_seconds_total{container_label_com_docker_compose_config_hash="",container_label_com_docker_compose_container_number="",container_label_com_docker_compose_depends_on="",container_label_com_docker_compose_image="",container_label_com_docker_compose_oneoff="",container_label_com_docker_compose_project="",container_label_com_docker_compose_project_config_files="",container_label_com_docker_compose_project_working_dir="",container_label_com_docker_compose_service="",container_label_com_docker_compose_version="",container_label_maintainer="",container_label_org_opencontainers_image_authors="",container_label_org_opencontainers_image_created="",container_label_org_opencontainers_image_description="",container_label_org_opencontainers_image_documentation="",container_label_org_opencontainers_image_licenses="",container_label_org_opencontainers_image_ref_name="",container_label_org_opencontainers_image_revision="",container_label_org_opencontainers_image_source="",container_label_org_opencontainers_image_title="",container_label_org_opencontainers_image_url="",container_label_org_opencontainers_image_vendor="",container_label_org_opencontainers_image_version="",cpu="total",id="/system.slice/open-vm-tools.service",image="",name=""} 995.697641 1777637070360
container_cpu_usage_seconds_total{container_label_com_docker_compose_config_hash="",container_label_com_docker_compose_container_number="",container_label_com_docker_compose_depends_on="",container_label_com_docker_compose_image="",container_label_com_docker_compose_oneoff="",container_label_com_docker_compose_project="",container_label_com_docker_compose_project_config_files="",container_label_com_docker_compose_project_working_dir="",container_label_com_docker_compose_service="",container_label_com_docker_compose_version="",container_label_maintainer="",container_label_org_opencontainers_image_authors="",container_label_org_opencontainers_image_created="",container_label_org_opencontainers_image_description="",container_label_org_opencontainers_image_documentation="",container_label_org_opencontainers_image_licenses="",container_label_org_opencontainers_image_ref_name="",container_label_org_opencontainers_image_revision="",container_label_org_opencontainers_image_source="",container_label_org_opencontainers_image_title="",container_label_org_opencontainers_image_url="",container_label_org_opencontainers_image_vendor="",container_label_org_opencontainers_image_version="",cpu="total",id="/system.slice/packagekit.service",image="",name=""} 5.462752 1777637065967
container_cpu_usage_seconds_total{container_label_com_docker_compose_config_hash="",container_label_com_docker_compose_container_number="",container_label_com_docker_compose_depends_on="",container_label_com_docker_compose_image="",container_label_com_docker_compose_oneoff="",container_label_com_docker_compose_project="",container_label_com_docker_compose_project_config_files="",container_label_com_docker_compose_project_working_dir="",container_label_com_docker_compose_service="",container_label_com_docker_compose_version="",container_label_maintainer="",container_label_org_opencontainers_image_authors="",container_label_org_opencontainers_image_created="",container_label_org_opencontainers_image_description="",container_label_org_opencontainers_image_documentation="",container_label_org_opencontainers_image_licenses="",container_label_org_opencontainers_image_ref_name="",container_label_org_opencontainers_image_revision="",container_label_org_opencontainers_image_source="",container_label_org_opencontainers_image_title="",container_label_org_opencontainers_image_url="",container_label_org_opencontainers_image_vendor="",container_label_org_opencontainers_image_version="",cpu="total",id="/system.slice/pix2pi-accounting.service",image="",name=""} 5.681131 1777637062551
container_cpu_usage_seconds_total{container_label_com_docker_compose_config_hash="",container_label_com_docker_compose_container_number="",container_label_com_docker_compose_depends_on="",container_label_com_docker_compose_image="",container_label_com_docker_compose_oneoff="",container_label_com_docker_compose_project="",container_label_com_docker_compose_project_config_files="",container_label_com_docker_compose_project_working_dir="",container_label_com_docker_compose_service="",container_label_com_docker_compose_version="",container_label_maintainer="",container_label_org_opencontainers_image_authors="",container_label_org_opencontainers_image_created="",container_label_org_opencontainers_image_description="",container_label_org_opencontainers_image_documentation="",container_label_org_opencontainers_image_licenses="",container_label_org_opencontainers_image_ref_name="",container_label_org_opencontainers_image_revision="",container_label_org_opencontainers_image_source="",container_label_org_opencontainers_image_title="",container_label_org_opencontainers_image_url="",container_label_org_opencontainers_image_vendor="",container_label_org_opencontainers_image_version="",cpu="total",id="/system.slice/pix2pi-api-gateway.service",image="",name=""} 8.794249 1777637067386
container_cpu_usage_seconds_total{container_label_com_docker_compose_config_hash="",container_label_com_docker_compose_container_number="",container_label_com_docker_compose_depends_on="",container_label_com_docker_compose_image="",container_label_com_docker_compose_oneoff="",container_label_com_docker_compose_project="",container_label_com_docker_compose_project_config_files="",container_label_com_docker_compose_project_working_dir="",container_label_com_docker_compose_service="",container_label_com_docker_compose_version="",container_label_maintainer="",container_label_org_opencontainers_image_authors="",container_label_org_opencontainers_image_created="",container_label_org_opencontainers_image_description="",container_label_org_opencontainers_image_documentation="",container_label_org_opencontainers_image_licenses="",container_label_org_opencontainers_image_ref_name="",container_label_org_opencontainers_image_revision="",container_label_org_opencontainers_image_source="",container_label_org_opencontainers_image_title="",container_label_org_opencontainers_image_url="",container_label_org_opencontainers_image_vendor="",container_label_org_opencontainers_image_version="",cpu="total",id="/system.slice/pix2pi-auth.service",image="",name=""} 149.200237 1777637070939
container_cpu_usage_seconds_total{container_label_com_docker_compose_config_hash="",container_label_com_docker_compose_container_number="",container_label_com_docker_compose_depends_on="",container_label_com_docker_compose_image="",container_label_com_docker_compose_oneoff="",container_label_com_docker_compose_project="",container_label_com_docker_compose_project_config_files="",container_label_com_docker_compose_project_working_dir="",container_label_com_docker_compose_service="",container_label_com_docker_compose_version="",container_label_maintainer="",container_label_org_opencontainers_image_authors="",container_label_org_opencontainers_image_created="",container_label_org_opencontainers_image_description="",container_label_org_opencontainers_image_documentation="",container_label_org_opencontainers_image_licenses="",container_label_org_opencontainers_image_ref_name="",container_label_org_opencontainers_image_revision="",container_label_org_opencontainers_image_source="",container_label_org_opencontainers_image_title="",container_label_org_opencontainers_image_url="",container_label_org_opencontainers_image_vendor="",container_label_org_opencontainers_image_version="",cpu="total",id="/system.slice/pix2pi-early-warning-runtime.service",image="",name=""} 140.937446 1777637069604
container_cpu_usage_seconds_total{container_label_com_docker_compose_config_hash="",container_label_com_docker_compose_container_number="",container_label_com_docker_compose_depends_on="",container_label_com_docker_compose_image="",container_label_com_docker_compose_oneoff="",container_label_com_docker_compose_project="",container_label_com_docker_compose_project_config_files="",container_label_com_docker_compose_project_working_dir="",container_label_com_docker_compose_service="",container_label_com_docker_compose_version="",container_label_maintainer="",container_label_org_opencontainers_image_authors="",container_label_org_opencontainers_image_created="",container_label_org_opencontainers_image_description="",container_label_org_opencontainers_image_documentation="",container_label_org_opencontainers_image_licenses="",container_label_org_opencontainers_image_ref_name="",container_label_org_opencontainers_image_revision="",container_label_org_opencontainers_image_source="",container_label_org_opencontainers_image_title="",container_label_org_opencontainers_image_url="",container_label_org_opencontainers_image_vendor="",container_label_org_opencontainers_image_version="",cpu="total",id="/system.slice/pix2pi-identity.service",image="",name=""} 4.671749 1777637061999
container_cpu_usage_seconds_total{container_label_com_docker_compose_config_hash="",container_label_com_docker_compose_container_number="",container_label_com_docker_compose_depends_on="",container_label_com_docker_compose_image="",container_label_com_docker_compose_oneoff="",container_label_com_docker_compose_project="",container_label_com_docker_compose_project_config_files="",container_label_com_docker_compose_project_working_dir="",container_label_com_docker_compose_service="",container_label_com_docker_compose_version="",container_label_maintainer="",container_label_org_opencontainers_image_authors="",container_label_org_opencontainers_image_created="",container_label_org_opencontainers_image_description="",container_label_org_opencontainers_image_documentation="",container_label_org_opencontainers_image_licenses="",container_label_org_opencontainers_image_ref_name="",container_label_org_opencontainers_image_revision="",container_label_org_opencontainers_image_source="",container_label_org_opencontainers_image_title="",container_label_org_opencontainers_image_url="",container_label_org_opencontainers_image_vendor="",container_label_org_opencontainers_image_version="",cpu="total",id="/system.slice/pix2pi-incident-audit-runtime.service",image="",name=""} 139.188344 1777637070457
container_cpu_usage_seconds_total{container_label_com_docker_compose_config_hash="",container_label_com_docker_compose_container_number="",container_label_com_docker_compose_depends_on="",container_label_com_docker_compose_image="",container_label_com_docker_compose_oneoff="",container_label_com_docker_compose_project="",container_label_com_docker_compose_project_config_files="",container_label_com_docker_compose_project_working_dir="",container_label_com_docker_compose_service="",container_label_com_docker_compose_version="",container_label_maintainer="",container_label_org_opencontainers_image_authors="",container_label_org_opencontainers_image_created="",container_label_org_opencontainers_image_description="",container_label_org_opencontainers_image_documentation="",container_label_org_opencontainers_image_licenses="",container_label_org_opencontainers_image_ref_name="",container_label_org_opencontainers_image_revision="",container_label_org_opencontainers_image_source="",container_label_org_opencontainers_image_title="",container_label_org_opencontainers_image_url="",container_label_org_opencontainers_image_vendor="",container_label_org_opencontainers_image_version="",cpu="total",id="/system.slice/pix2pi-jobs-runtime.service",image="",name=""} 148.279414 1777637070030
container_cpu_usage_seconds_total{container_label_com_docker_compose_config_hash="",container_label_com_docker_compose_container_number="",container_label_com_docker_compose_depends_on="",container_label_com_docker_compose_image="",container_label_com_docker_compose_oneoff="",container_label_com_docker_compose_project="",container_label_com_docker_compose_project_config_files="",container_label_com_docker_compose_project_working_dir="",container_label_com_docker_compose_service="",container_label_com_docker_compose_version="",container_label_maintainer="",container_label_org_opencontainers_image_authors="",container_label_org_opencontainers_image_created="",container_label_org_opencontainers_image_description="",container_label_org_opencontainers_image_documentation="",container_label_org_opencontainers_image_licenses="",container_label_org_opencontainers_image_ref_name="",container_label_org_opencontainers_image_revision="",container_label_org_opencontainers_image_source="",container_label_org_opencontainers_image_title="",container_label_org_opencontainers_image_url="",container_label_org_opencontainers_image_vendor="",container_label_org_opencontainers_image_version="",cpu="total",id="/system.slice/pix2pi-mission-control.service",image="",name=""} 0.899856 1777637062062
container_cpu_usage_seconds_total{container_label_com_docker_compose_config_hash="",container_label_com_docker_compose_container_number="",container_label_com_docker_compose_depends_on="",container_label_com_docker_compose_image="",container_label_com_docker_compose_oneoff="",container_label_com_docker_compose_project="",container_label_com_docker_compose_project_config_files="",container_label_com_docker_compose_project_working_dir="",container_label_com_docker_compose_service="",container_label_com_docker_compose_version="",container_label_maintainer="",container_label_org_opencontainers_image_authors="",container_label_org_opencontainers_image_created="",container_label_org_opencontainers_image_description="",container_label_org_opencontainers_image_documentation="",container_label_org_opencontainers_image_licenses="",container_label_org_opencontainers_image_ref_name="",container_label_org_opencontainers_image_revision="",container_label_org_opencontainers_image_source="",container_label_org_opencontainers_image_title="",container_label_org_opencontainers_image_url="",container_label_org_opencontainers_image_vendor="",container_label_org_opencontainers_image_version="",cpu="total",id="/system.slice/pix2pi-notification-runtime.service",image="",name=""} 148.38028 1777637069796
container_cpu_usage_seconds_total{container_label_com_docker_compose_config_hash="",container_label_com_docker_compose_container_number="",container_label_com_docker_compose_depends_on="",container_label_com_docker_compose_image="",container_label_com_docker_compose_oneoff="",container_label_com_docker_compose_project="",container_label_com_docker_compose_project_config_files="",container_label_com_docker_compose_project_working_dir="",container_label_com_docker_compose_service="",container_label_com_docker_compose_version="",container_label_maintainer="",container_label_org_opencontainers_image_authors="",container_label_org_opencontainers_image_created="",container_label_org_opencontainers_image_description="",container_label_org_opencontainers_image_documentation="",container_label_org_opencontainers_image_licenses="",container_label_org_opencontainers_image_ref_name="",container_label_org_opencontainers_image_revision="",container_label_org_opencontainers_image_source="",container_label_org_opencontainers_image_title="",container_label_org_opencontainers_image_url="",container_label_org_opencontainers_image_vendor="",container_label_org_opencontainers_image_version="",cpu="total",id="/system.slice/pix2pi-panel.service",image="",name=""} 196.023259 1777637069769
container_cpu_usage_seconds_total{container_label_com_docker_compose_config_hash="",container_label_com_docker_compose_container_number="",container_label_com_docker_compose_depends_on="",container_label_com_docker_compose_image="",container_label_com_docker_compose_oneoff="",container_label_com_docker_compose_project="",container_label_com_docker_compose_project_config_files="",container_label_com_docker_compose_project_working_dir="",container_label_com_docker_compose_service="",container_label_com_docker_compose_version="",container_label_maintainer="",container_label_org_opencontainers_image_authors="",container_label_org_opencontainers_image_created="",container_label_org_opencontainers_image_description="",container_label_org_opencontainers_image_documentation="",container_label_org_opencontainers_image_licenses="",container_label_org_opencontainers_image_ref_name="",container_label_org_opencontainers_image_revision="",container_label_org_opencontainers_image_source="",container_label_org_opencontainers_image_title="",container_label_org_opencontainers_image_url="",container_label_org_opencontainers_image_vendor="",container_label_org_opencontainers_image_version="",cpu="total",id="/system.slice/pix2pi-plugin-runtime.service",image="",name=""} 146.042355 1777637070516
container_cpu_usage_seconds_total{container_label_com_docker_compose_config_hash="",container_label_com_docker_compose_container_number="",container_label_com_docker_compose_depends_on="",container_label_com_docker_compose_image="",container_label_com_docker_compose_oneoff="",container_label_com_docker_compose_project="",container_label_com_docker_compose_project_config_files="",container_label_com_docker_compose_project_working_dir="",container_label_com_docker_compose_service="",container_label_com_docker_compose_version="",container_label_maintainer="",container_label_org_opencontainers_image_authors="",container_label_org_opencontainers_image_created="",container_label_org_opencontainers_image_description="",container_label_org_opencontainers_image_documentation="",container_label_org_opencontainers_image_licenses="",container_label_org_opencontainers_image_ref_name="",container_label_org_opencontainers_image_revision="",container_label_org_opencontainers_image_source="",container_label_org_opencontainers_image_title="",container_label_org_opencontainers_image_url="",container_label_org_opencontainers_image_vendor="",container_label_org_opencontainers_image_version="",cpu="total",id="/system.slice/pix2pi-publicapi-runtime.service",image="",name=""} 146.304677 1777637070013
container_cpu_usage_seconds_total{container_label_com_docker_compose_config_hash="",container_label_com_docker_compose_container_number="",container_label_com_docker_compose_depends_on="",container_label_com_docker_compose_image="",container_label_com_docker_compose_oneoff="",container_label_com_docker_compose_project="",container_label_com_docker_compose_project_config_files="",container_label_com_docker_compose_project_working_dir="",container_label_com_docker_compose_service="",container_label_com_docker_compose_version="",container_label_maintainer="",container_label_org_opencontainers_image_authors="",container_label_org_opencontainers_image_created="",container_label_org_opencontainers_image_description="",container_label_org_opencontainers_image_documentation="",container_label_org_opencontainers_image_licenses="",container_label_org_opencontainers_image_ref_name="",container_label_org_opencontainers_image_revision="",container_label_org_opencontainers_image_source="",container_label_org_opencontainers_image_title="",container_label_org_opencontainers_image_url="",container_label_org_opencontainers_image_vendor="",container_label_org_opencontainers_image_version="",cpu="total",id="/system.slice/pix2pi-query-read-model.service",image="",name=""} 40.378911 1777637047855
container_cpu_usage_seconds_total{container_label_com_docker_compose_config_hash="",container_label_com_docker_compose_container_number="",container_label_com_docker_compose_depends_on="",container_label_com_docker_compose_image="",container_label_com_docker_compose_oneoff="",container_label_com_docker_compose_project="",container_label_com_docker_compose_project_config_files="",container_label_com_docker_compose_project_working_dir="",container_label_com_docker_compose_service="",container_label_com_docker_compose_version="",container_label_maintainer="",container_label_org_opencontainers_image_authors="",container_label_org_opencontainers_image_created="",container_label_org_opencontainers_image_description="",container_label_org_opencontainers_image_documentation="",container_label_org_opencontainers_image_licenses="",container_label_org_opencontainers_image_ref_name="",container_label_org_opencontainers_image_revision="",container_label_org_opencontainers_image_source="",container_label_org_opencontainers_image_title="",container_label_org_opencontainers_image_url="",container_label_org_opencontainers_image_vendor="",container_label_org_opencontainers_image_version="",cpu="total",id="/system.slice/pix2pi-realtime-runtime.service",image="",name=""} 136.818699 1777637070440
container_cpu_usage_seconds_total{container_label_com_docker_compose_config_hash="",container_label_com_docker_compose_container_number="",container_label_com_docker_compose_depends_on="",container_label_com_docker_compose_image="",container_label_com_docker_compose_oneoff="",container_label_com_docker_compose_project="",container_label_com_docker_compose_project_config_files="",container_label_com_docker_compose_project_working_dir="",container_label_com_docker_compose_service="",container_label_com_docker_compose_version="",container_label_maintainer="",container_label_org_opencontainers_image_authors="",container_label_org_opencontainers_image_created="",container_label_org_opencontainers_image_description="",container_label_org_opencontainers_image_documentation="",container_label_org_opencontainers_image_licenses="",container_label_org_opencontainers_image_ref_name="",container_label_org_opencontainers_image_revision="",container_label_org_opencontainers_image_source="",container_label_org_opencontainers_image_title="",container_label_org_opencontainers_image_url="",container_label_org_opencontainers_image_vendor="",container_label_org_opencontainers_image_version="",cpu="total",id="/system.slice/pix2pi-runtime-topology.service",image="",name=""} 137.170807 1777637070445
container_cpu_usage_seconds_total{container_label_com_docker_compose_config_hash="",container_label_com_docker_compose_container_number="",container_label_com_docker_compose_depends_on="",container_label_com_docker_compose_image="",container_label_com_docker_compose_oneoff="",container_label_com_docker_compose_project="",container_label_com_docker_compose_project_config_files="",container_label_com_docker_compose_project_working_dir="",container_label_com_docker_compose_service="",container_label_com_docker_compose_version="",container_label_maintainer="",container_label_org_opencontainers_image_authors="",container_label_org_opencontainers_image_created="",container_label_org_opencontainers_image_description="",container_label_org_opencontainers_image_documentation="",container_label_org_opencontainers_image_licenses="",container_label_org_opencontainers_image_ref_name="",container_label_org_opencontainers_image_revision="",container_label_org_opencontainers_image_source="",container_label_org_opencontainers_image_title="",container_label_org_opencontainers_image_url="",container_label_org_opencontainers_image_vendor="",container_label_org_opencontainers_image_version="",cpu="total",id="/system.slice/pix2pi-service-registry.service",image="",name=""} 41.031112 1777637059223
container_cpu_usage_seconds_total{container_label_com_docker_compose_config_hash="",container_label_com_docker_compose_container_number="",container_label_com_docker_compose_depends_on="",container_label_com_docker_compose_image="",container_label_com_docker_compose_oneoff="",container_label_com_docker_compose_project="",container_label_com_docker_compose_project_config_files="",container_label_com_docker_compose_project_working_dir="",container_label_com_docker_compose_service="",container_label_com_docker_compose_version="",container_label_maintainer="",container_label_org_opencontainers_image_authors="",container_label_org_opencontainers_image_created="",container_label_org_opencontainers_image_description="",container_label_org_opencontainers_image_documentation="",container_label_org_opencontainers_image_licenses="",container_label_org_opencontainers_image_ref_name="",container_label_org_opencontainers_image_revision="",container_label_org_opencontainers_image_source="",container_label_org_opencontainers_image_title="",container_label_org_opencontainers_image_url="",container_label_org_opencontainers_image_vendor="",container_label_org_opencontainers_image_version="",cpu="total",id="/system.slice/pix2pi-user-created-consumer.service",image="",name=""} 5.119249 1777637069708
container_cpu_usage_seconds_total{container_label_com_docker_compose_config_hash="",container_label_com_docker_compose_container_number="",container_label_com_docker_compose_depends_on="",container_label_com_docker_compose_image="",container_label_com_docker_compose_oneoff="",container_label_com_docker_compose_project="",container_label_com_docker_compose_project_config_files="",container_label_com_docker_compose_project_working_dir="",container_label_com_docker_compose_service="",container_label_com_docker_compose_version="",container_label_maintainer="",container_label_org_opencontainers_image_authors="",container_label_org_opencontainers_image_created="",container_label_org_opencontainers_image_description="",container_label_org_opencontainers_image_documentation="",container_label_org_opencontainers_image_licenses="",container_label_org_opencontainers_image_ref_name="",container_label_org_opencontainers_image_revision="",container_label_org_opencontainers_image_source="",container_label_org_opencontainers_image_title="",container_label_org_opencontainers_image_url="",container_label_org_opencontainers_image_vendor="",container_label_org_opencontainers_image_version="",cpu="total",id="/system.slice/pix2pi-webhook-runtime.service",image="",name=""} 148.39259 1777637070544
container_cpu_usage_seconds_total{container_label_com_docker_compose_config_hash="",container_label_com_docker_compose_container_number="",container_label_com_docker_compose_depends_on="",container_label_com_docker_compose_image="",container_label_com_docker_compose_oneoff="",container_label_com_docker_compose_project="",container_label_com_docker_compose_project_config_files="",container_label_com_docker_compose_project_working_dir="",container_label_com_docker_compose_service="",container_label_com_docker_compose_version="",container_label_maintainer="",container_label_org_opencontainers_image_authors="",container_label_org_opencontainers_image_created="",container_label_org_opencontainers_image_description="",container_label_org_opencontainers_image_documentation="",container_label_org_opencontainers_image_licenses="",container_label_org_opencontainers_image_ref_name="",container_label_org_opencontainers_image_revision="",container_label_org_opencontainers_image_source="",container_label_org_opencontainers_image_title="",container_label_org_opencontainers_image_url="",container_label_org_opencontainers_image_vendor="",container_label_org_opencontainers_image_version="",cpu="total",id="/system.slice/pix2pi-workflow-runtime.service",image="",name=""} 148.87783 1777637070654
container_cpu_usage_seconds_total{container_label_com_docker_compose_config_hash="",container_label_com_docker_compose_container_number="",container_label_com_docker_compose_depends_on="",container_label_com_docker_compose_image="",container_label_com_docker_compose_oneoff="",container_label_com_docker_compose_project="",container_label_com_docker_compose_project_config_files="",container_label_com_docker_compose_project_working_dir="",container_label_com_docker_compose_service="",container_label_com_docker_compose_version="",container_label_maintainer="",container_label_org_opencontainers_image_authors="",container_label_org_opencontainers_image_created="",container_label_org_opencontainers_image_description="",container_label_org_opencontainers_image_documentation="",container_label_org_opencontainers_image_licenses="",container_label_org_opencontainers_image_ref_name="",container_label_org_opencontainers_image_revision="",container_label_org_opencontainers_image_source="",container_label_org_opencontainers_image_title="",container_label_org_opencontainers_image_url="",container_label_org_opencontainers_image_vendor="",container_label_org_opencontainers_image_version="",cpu="total",id="/system.slice/polkit.service",image="",name=""} 0.323727 1777637039918
```

## 6-8.13 NATS / Event Bus Performance Probe

```text

```

## 6-8.14 DB Runtime Performance Probe

```text
===== container: pix2pi_pg_replica =====
/var/run/postgresql:5432 - accepting connections
===== container: pix2pi_pg =====
/var/run/postgresql:5432 - accepting connections
```

## 6-8.15 Performance Tooling Inventory

```text
WARN ⚠️ hey not found
WARN ⚠️ wrk not found
WARN ⚠️ ab not found
WARN ⚠️ k6 not found
WARN ⚠️ vegeta not found
OK ✅ curl exists: /usr/bin/curl
curl 7.81.0 (x86_64-pc-linux-gnu) libcurl/7.81.0 OpenSSL/3.0.2 zlib/1.2.11 brotli/1.0.9 zstd/1.4.8 libidn2/2.3.2 libpsl/0.21.0 (+libidn2/2.3.2) libssh/0.9.6/openssl/zlib nghttp2/1.43.0 librtmp/2.3 OpenLDAP/2.5.20
Release-Date: 2022-01-05
Protocols: dict file ftp ftps gopher gophers http https imap imaps ldap ldaps mqtt pop3 pop3s rtmp rtsp scp sftp smb smbs smtp smtps telnet tftp 
```

## 6-8.16 Performance Scripts Inventory

```text
./1_archive/root_sh/step_132_enable_rate_limit_api_domain.sh
./1_archive/root_sh/step_133_reload_nginx_after_rate_limit.sh
./1_archive/root_sh/step_198_reporting_service_json_sabitle.sh
./1_archive/root_sh/step_1_backup_gelir_tablosu_engine.sh
./1_archive/root_sh/step_204_apply_journal_tables.sh
./1_archive/root_sh/step_240_enable_rls_snapshots.sh
./1_archive/root_sh/step_270_observability_stack.sh
./1_archive/root_sh/step_271_run_observability_stack.sh
./1_archive/root_sh/step_272_test_observability_stack.sh
./1_archive/root_sh/step_274_restart_observability.sh
./1_archive/root_sh/step_283_disable_snapshot_logging.sh
./1_archive/root_sh/step_355e_find_last_buildable_watchdog_backup.sh
./1_archive/root_sh/step_388_fix_unbound_variable.sh
./1_archive/root_sh/step_401_enable_all_services.sh
./1_archive/root_sh/step_81_disable_default_nginx_site.sh
./1_archive/root_sh/step_85_reload_nginx_split.sh
./1_archive/root_sh/step_87_disable_old_pix2pi_site.sh
./1_archive/root_sh/step_93_reload_nginx_after_redirect_fix.sh
./1_archive/root_sh/step_fix_backup_kasa_parabirimi.sh
./1_archive/root_sh/step_run_gelir_tablosu_engine.sh
./1_archive/root_sql/step_200_create_event_store_table.sql
./1_archive/root_sql/step_203_create_journal_tables.sql
./1_archive/root_sql/step_230_create_snapshot_tables.sql
./1_archive/root_sql/step_240_enable_rls_snapshots.sql
./1_archive/root_sql/step_260_create_audit_tables.sql
./_backup_archive/EarlyWarningPage.test.tsx.bak_database_multi_fix_20260424_233625
./.backup/lvl10_live_finalize_20260422_063146/etc/nginx/sites-available/default
./.backup/lvl11_1_11_2_path_fix_20260422_074521/deploy/observability/scripts/lvl11_signal_threshold_smoke.sh
./.backup/lvl11_1_11_2_path_fix_20260422_074521/deploy/observability/scripts/render_lvl11_thresholds.sh
./backups/db/observability_apply/phase4_14_3_4_20260427_163442/postgresql.auto.conf.after
./backups/db/observability_apply/phase4_14_3_4_20260427_163442/postgresql.auto.conf.before
./backups/db/observability_apply/phase4_14_3_4_20260427_163442/postgresql.conf.before
./backups/faz3_13_2b_gateway_build_restart_live_verify_20260426_230109/logs/live_erp_runtime_payload.json
./backups/faz3_13_2c_gateway_live_negative_final_muhur_20260426_230410/logs/valid_payload.json
./backups/faz3_13_3b_gateway_observability_log_visibility_20260426_232013/cmd_api_gateway_before_13_3b.tar.gz
./backups/faz3_13_3b_gateway_observability_log_visibility_20260426_232013/docs_before_13_3b.tar.gz
./backups/faz3_13_3b_gateway_observability_log_visibility_20260426_232013/logs/health_live.json
./backups/faz3_13_3b_gateway_observability_log_visibility_20260426_232013/logs/health_ready.json
./backups/faz3_13_3b_gateway_observability_log_visibility_20260426_232013/logs/internal_routes.json
./backups/faz3_13_3b_gateway_observability_log_visibility_20260426_232013/logs/journal_observability.log
./backups/faz3_13_3b_gateway_observability_log_visibility_20260426_232013/logs/observability_headers.txt
./backups/faz3_13_3b_gateway_observability_log_visibility_20260426_232013/logs/observability_payload.json
./backups/faz3_13_3b_gateway_observability_log_visibility_20260426_232013/logs/observability_response.json
./backups/faz3_13_3b_gateway_observability_log_visibility_20260426_232013/logs/post_health_live.json
./backups/faz3_13_3b_gateway_observability_log_visibility_20260426_232013/logs/token_tenant_7.txt
./backups/faz3_13_3b_gateway_observability_log_visibility_20260426_232013/make_gateway_observability_token.go
./backups/faz3_13_3c_fix_gateway_observability_final_muhur_20260426_232602/cmd_api_gateway_before_13_3c_fix.tar.gz
./backups/faz3_13_3c_fix_gateway_observability_final_muhur_20260426_232602/docs_before_13_3c_fix.tar.gz
./backups/faz3_13_3c_fix_gateway_observability_final_muhur_20260426_232602/logs/apisurface_observability_final.log
./backups/faz3_13_3c_fix_gateway_observability_final_muhur_20260426_232602/logs/cmd_api_gateway_observability_final.log
./backups/faz3_13_3c_fix_gateway_observability_final_muhur_20260426_232602/logs/health_live.json
./backups/faz3_13_3c_fix_gateway_observability_final_muhur_20260426_232602/logs/health_ready.json
./backups/faz3_13_3c_fix_gateway_observability_final_muhur_20260426_232602/logs/internal_policy_final.json
./backups/faz3_13_3c_fix_gateway_observability_final_muhur_20260426_232602/logs/internal_routes_final.json
./backups/faz3_13_3c_fix_gateway_observability_final_muhur_20260426_232602/logs/journal_observability_final.log
./backups/faz3_13_3c_fix_gateway_observability_final_muhur_20260426_232602/logs/missing_bearer_body.json
./backups/faz3_13_3c_fix_gateway_observability_final_muhur_20260426_232602/logs/missing_bearer_headers.txt
./backups/faz3_13_3c_fix_gateway_observability_final_muhur_20260426_232602/logs/port_final.log
./backups/faz3_13_3c_fix_gateway_observability_final_muhur_20260426_232602/pix2pi-api-gateway.current
./backups/faz3_13_3c_fix_gateway_observability_final_muhur_20260426_232602/runtime_before_13_3c_fix.tar.gz
./backups/faz3_13_3c_gateway_observability_final_muhur_20260426_232401/cmd_api_gateway_before_13_3c.tar.gz
./backups/faz3_13_3c_gateway_observability_final_muhur_20260426_232401/docs_before_13_3c.tar.gz
./backups/faz3_13_3c_gateway_observability_final_muhur_20260426_232401/pix2pi-api-gateway.current
./backups/faz3_13_3c_gateway_observability_final_muhur_20260426_232401/runtime_before_13_3c.tar.gz
./backups/faz3_13_4a_step13_gateway_final_muhur_20260426_232851/logs/step13_final_payload.json
./backups/faz3_14_2a_fix2_panel_host_cache_diagnose_20260426_235311/logs/sites_enabled_active.log
./backups/faz3_14_2a_fix2_panel_host_cache_diagnose_20260426_235335/logs/sites_enabled_active.log
./backups/faz3_14_2b_panel_live_positive_api_muhur_20260427_000449/logs/panel_live_payload.json
./backups/faz3_14_2c_panel_ui_final_muhur_20260427_000653/logs/panel_final_payload.json
./backups/faz3_14_3a_content_type_header_diagnose_20260427_001443/logs/direct_payload.json
./backups/faz3_14_3a_content_type_header_diagnose_20260427_001443/logs/panel_payload.json
./backups/faz3_14_3b_fix1_panel_api_content_type_cleanup_resume_20260427_002000/logs/direct_payload.json
./backups/faz3_14_3b_fix1_panel_api_content_type_cleanup_resume_20260427_002000/logs/panel_payload.json
./backups/faz3_14_3b_fix2_content_type_cleanup_muhur_20260427_002326/logs/direct_payload.json
./backups/faz3_14_3b_fix2_content_type_cleanup_muhur_20260427_002326/logs/panel_payload.json
./backups/faz3_14_3c_header_cleanup_final_muhur_20260427_002547/logs/direct_payload.json
./backups/faz3_14_3c_header_cleanup_final_muhur_20260427_002547/logs/panel_payload.json
./backups/faz3_14_4a_faz3_final_muhur_20260427_002901/logs/faz3_final_payload.json
./backups/faz4b_22_8_observability_ops_console_final_closure_20260429_192428/docs/phase4/22_8_observability_ops_console_final_closure_inventory.tsv
./backups/faz4b_22_8_observability_ops_console_final_closure_20260429_192428/docs/phase4/22_8_observability_ops_console_final_closure_matrix.tsv
./backups/faz4b_22_8_observability_ops_console_final_closure_20260429_192428/docs/phase4/22_8_observability_ops_console_final_closure_report.md
./backups/faz4b_22_8_observability_ops_console_final_closure_20260429_192428/docs/phase4/22_8_observability_ops_console_final_closure_standard.md
./backups/faz4b_22_8_observability_ops_console_final_closure_20260429_192428/docs/phase4/22_observability_ops_console_final_closure_report.md
./backups/faz4b_22_8_observability_ops_console_final_closure_20260429_192428/scripts/phase4b_observability_ops_console_final_closure.py
./backups/faz4b_22_8_observability_ops_console_final_closure_20260429_192428/scripts/phase4b_observability_ops_console_final_closure.sh
./backups/faz4b_22_8_observability_ops_console_final_closure_20260429_192428/scripts/test_phase4b_observability_ops_console_final_closure.sh
./backups/faz4c/4c_1_1j_final_closure/20260501_065519/4c_1_1h_real_business_profile_applied.md.bak
./backups/faz4c/4c_1_2a_execution_master_plan/20260501_065731/4c_1_1h_real_business_profile_applied.md.bak
./backups/faz4c/4c_3a_tenant_identity_setup_plan/20260501_070839/4c_1_1h_real_business_profile_applied.md.bak
./backups/faz4c/4c_5c_product_stock_table_discovery/20260501_080246/4c_5b_import_template_structure_precheck_report.md.bak
./backups/faz4c/4c_5c_product_stock_table_discovery/20260501_080246/4c_5b_import_template_structure_precheck_test_report.md.bak
./backups/faz4c/4c_5d_import_mapping_strategy/20260501_080433/4c_5c_product_stock_table_discovery_report.md.bak
./backups/faz4c/4c_5d_import_mapping_strategy/20260501_080433/4c_5c_product_stock_table_discovery_test_report.md.bak
./backups/faz4c/4c_5j_real_pilot_data_import_final_closure/20260501_081931/4c_5c_product_stock_table_discovery_test_report.md.bak
./backups/fix_faz4b_22_8_final_validator_20260429_192914/docs/phase4/22_8_observability_ops_console_final_closure_inventory.tsv
./backups/fix_faz4b_22_8_final_validator_20260429_192914/docs/phase4/22_8_observability_ops_console_final_closure_matrix.tsv
./backups/fix_faz4b_22_8_final_validator_20260429_192914/docs/phase4/22_8_observability_ops_console_final_closure_report.md
./backups/fix_faz4b_22_8_final_validator_20260429_192914/docs/phase4/22_observability_ops_console_final_closure_report.md
./backups/fix_faz4b_22_8_final_validator_20260429_192914/scripts/phase4b_observability_ops_console_final_closure.py
./backups/fix_faz4b_22_8_final_validator_20260429_192914/scripts/phase4b_observability_ops_console_final_closure.sh
./backups/fix_faz4b_22_8_final_validator_20260429_192914/scripts/test_phase4b_observability_ops_console_final_closure.sh
./backups/gw_ingress_scan/20260417_201007/sites-available/default
./backups/gw_ingress_scan/20260417_201007/sites-available/pix2pi
./backups/gw_ingress_scan/20260417_201007/sites-available/pix2pi_api_gateway
./backups/gw_ingress_scan/20260417_201007/sites-available/pix2pi_http_redirect
./backups/gw_ingress_scan/20260417_201007/sites-available/pix2pi_ssl
./backups/nginx_gateway_ingress/20260417_205007/sites-available.bak/default
./backups/nginx_gateway_ingress/20260417_205007/sites-available.bak/pix2pi
./backups/nginx_gateway_ingress/20260417_205007/sites-available.bak/pix2pi_api_gateway
./backups/nginx_gateway_ingress/20260417_205007/sites-available.bak/pix2pi_http_redirect
./backups/nginx_gateway_ingress/20260417_205007/sites-available.bak/pix2pi_ssl
./backups/nginx_gateway_ingress/20260417_205115/sites-available.bak/default
./backups/nginx_gateway_ingress/20260417_205115/sites-available.bak/pix2pi
./backups/nginx_gateway_ingress/20260417_205115/sites-available.bak/pix2pi_api_gateway
./backups/nginx_gateway_ingress/20260417_205115/sites-available.bak/pix2pi_http_redirect
./backups/nginx_gateway_ingress/20260417_205115/sites-available.bak/pix2pi_ssl
./db/migrations/20260427_151001_readmodel_operational_tables.down.sql
./db/migrations/20260427_151001_readmodel_operational_tables.up.sql
./db/migrations/20260428_143001_import_staging_tables.down.sql
./db/migrations/20260428_143001_import_staging_tables.up.sql
./db/migrations/20260428_155001_search_index_projection_tables.down.sql
./db/migrations/20260428_155001_search_index_projection_tables.up.sql
./deploy/observability/config/lvl11_correlation_catalog.yaml
./deploy/observability/config/lvl11_delivery_catalog.yaml
./deploy/observability/config/lvl11_scale_trigger_matrix.yaml.template
./deploy/observability/config/lvl11_signal_catalog.yaml
./deploy/observability/config/lvl11_threshold_rules.yaml.template
./deploy/observability/config/lvl11_validation_matrix.yaml.template
./deploy/observability/docker-compose.yml
./deploy/observability/env/lvl11_delivery_validation.env.example
./deploy/observability/env/lvl11_early_warning.env.example
./deploy/observability/env/lvl11_scale_trigger.env.example
./deploy/observability/generated/lvl11_correlation_summary.md
./deploy/observability/generated/lvl11_delivery_summary.md
./deploy/observability/generated/lvl11_phase_closure_report.md
./deploy/observability/generated/lvl11_phase_closure_summary.env
./deploy/observability/generated/lvl11_scale_trigger_matrix.yaml
./deploy/observability/generated/lvl11_threshold_rules.yaml
./deploy/observability/generated/lvl11_threshold_summary.md
./deploy/observability/generated/lvl11_validation_matrix.yaml
./deploy/observability/grafana/dashboards/docker-monitoring.json
./deploy/observability/grafana/dashboards/node-exporter-full.json
./deploy/observability/grafana/dashboards/node.json
./deploy/observability/grafana/provisioning/dashboards/dashboard.yml
./deploy/observability/grafana/provisioning/dashboards/provider.yml
./deploy/observability/grafana/provisioning/datasources/datasource.yml
./deploy/observability/grafana/provisioning/datasources/ds.yml.disabled
./deploy/observability/loki/loki-config.yml
./deploy/observability/loki/loki.yml
./deploy/observability/prometheus/prometheus.yml
./deploy/observability/prometheus.yml
./deploy/observability/promtail/promtail-config.yml
./deploy/observability/promtail/promtail.yml
./deploy/observability/scripts/lvl11_correlation_scale_smoke.sh
./deploy/observability/scripts/lvl11_delivery_validation_smoke.sh
./deploy/observability/scripts/lvl11_phase_closure_check.sh
./deploy/observability/scripts/lvl11_signal_threshold_smoke.sh
./deploy/observability/scripts/render_lvl11_correlation_scale.sh
./deploy/observability/scripts/render_lvl11_delivery_validation.sh
./deploy/observability/scripts/render_lvl11_thresholds.sh
./deploy/observability/tempo/tempo.yml
./deploy/quality/config/lvl14_performance_gate_catalog.yaml
./deploy/quality/config/lvl14_performance_release_rules.yaml.template
./deploy/quality/env/lvl14_performance_release.env.example
./deploy/quality/generated/lvl14_performance_release_rules.yaml
./deploy/quality/generated/lvl14_performance_summary.md
./deploy/quality/scripts/lvl14_performance_release_smoke.sh
./deploy/quality/scripts/render_lvl14_performance_release.sh
./docs/erp/faz3_step13_3b_gateway_observability_log_visibility.md
./docs/erp/faz3_step13_3_gateway_observability_final_muhur.md
./docs/faz4d/FAZ_4D_12_PILOT_MONITORING_STABILIZATION.md
./docs/faz6/checkpoints/FAZ_6_5_OBSERVABILITY_VISIBLE_CHECKPOINTS.md
./docs/faz6/checkpoints/FAZ_6_8_PERFORMANCE_VISIBLE_CHECKPOINTS.md
./docs/faz6/evidence/FAZ_6_5_OBSERVABILITY_RUNTIME_AUDIT.md
./docs/faz6/evidence/FAZ_6_8_PERFORMANCE_RUNTIME_AUDIT.md
./docs/faz6/FAZ_6_5_OBSERVABILITY_EARLY_WARNING_SRE_DASHBOARD.md
./docs/faz6/FAZ_6_8_PERFORMANCE_LOAD_STRESS_READINESS.md
./docs/observability/lvl11_correlation_scale_trigger_foundation.md
./docs/observability/lvl11_delivery_validation_phase_closure.md
./docs/observability/lvl11_signal_threshold_foundation.md
./docs/phase4/14_2_5_pitr_enable_candidate_plan.sh
./docs/phase4/14_2_6_pitr_enable_candidate_execution.sh
./docs/phase4/14_2_6_pitr_enable_gate_report.md
./docs/phase4/14_2_6_pitr_enable_gate_standard.md
./docs/phase4/14_3_1_db_observability_performance_report.md
./docs/phase4/14_3_1_db_observability_performance_standard.md
./docs/phase4/14_3_2_db_observability_candidate_plan.sh
./docs/phase4/14_3_2_db_observability_enable_gate_report.md
./docs/phase4/14_3_2_db_observability_enable_gate_standard.md
./docs/phase4/14_3_3_db_observability_apply_readiness_report.md
./docs/phase4/14_3_3_db_observability_apply_readiness_standard.md
./docs/phase4/14_3_3_db_observability_config_patch_candidate.sh
./docs/phase4/14_3_3_db_observability_rollback_plan.sh
./docs/phase4/14_3_4_db_observability_controlled_apply_report.md
./docs/phase4/14_3_4_db_observability_controlled_apply_standard.md
./docs/phase4/14_3_5_db_observability_final_baseline_report.md
./docs/phase4/14_3_5_db_observability_final_baseline_standard.md
./docs/phase4/14_3_final_db_observability_closure_report.md
./docs/phase4/14_3_import_staging_tables_inventory.tsv
./docs/phase4/14_3_import_staging_tables_matrix.tsv
./docs/phase4/14_3_import_staging_tables_report.md
./docs/phase4/14_3_import_staging_tables_standard.md
./docs/phase4/14_4_1_query_performance_baseline_report.md
./docs/phase4/14_4_1_query_performance_baseline_standard.md
./docs/phase4/14_4_1_query_performance_top_queries.tsv
./docs/phase4/14_4_2_table_scan_metrics.tsv
./docs/phase4/14_4_3_table_vacuum_metrics.tsv
./docs/phase4/14_4_5_db_performance_final_closure_report.md
./docs/phase4/14_4_5_db_performance_final_closure_standard.md
./docs/phase4/14_4_final_db_performance_closure_report.md
./docs/phase4/15_1_operational_readmodel_tables_inventory.tsv
./docs/phase4/15_1_operational_readmodel_tables_report.md
./docs/phase4/15_1_operational_readmodel_tables_standard.md
./docs/phase4/15_5_search_index_projection_tables_inventory.tsv
./docs/phase4/15_5_search_index_projection_tables_matrix.tsv
./docs/phase4/15_5_search_index_projection_tables_report.md
./docs/phase4/15_5_search_index_projection_tables_standard.md
./docs/phase4/17_4_realtime_payload_envelope.tsv
./docs/phase4/22_1_observability_alert_readiness.tsv
./docs/phase4/22_1_observability_baseline_matrix.tsv
```

## 6-8.17 Runtime Audit Interpretation

```text
6-8.1 Host inventory collected OK ✅
6-8.2 Uptime/load average collected OK ✅
6-8.3 Memory snapshot collected OK ✅
6-8.4 Disk usage collected OK ✅
6-8.5 Process CPU/memory top collected OK ✅
6-8.6 Docker stats snapshot collected OK ✅
6-8.7 Docker runtime containers collected OK ✅
6-8.8 Listening ports collected OK ✅
6-8.9 Safe health timing probe collected OK ✅
6-8.10 Prometheus targets probe collected OK ✅
6-8.11 Node exporter metrics probe collected OK ✅
6-8.12 cAdvisor metrics probe collected OK ✅
6-8.13 NATS/event bus performance probe collected OK ✅
6-8.14 DB runtime performance probe collected OK ✅
6-8.15 Performance tooling inventory collected OK ✅
6-8.16 Performance scripts inventory collected OK ✅
FAZ_6_8_RUNTIME_AUDIT=COMPLETE ✅
```
