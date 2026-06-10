# FAZ 6-2 DB-L8 Audit Evidence

Generated At: 2026-05-01T14:13:07+03:00  
Host: vm12827.ovadns.com  
Repo: /root/pix2pi/pix2pi-SaaS  

FAZ_6_2_AUDIT_EVIDENCE=READY ✅

---

## 6-2.1 Environment Files Inventory

```text
OK ✅ env file exists: .env
WARN ⚠️ env file missing: .env.production
OK ✅ env file exists: /etc/pix2pi/ports.env
OK ✅ env file exists: /opt/pix2pi/orchestrator/env/common.env
```

## 6-2.2 DB DSN Presence Check

```text
OK ✅ DB_WRITE_DSN found in .env
DB_WRITE_DSN=postgres://pix2pi:pix2pi@127.0.0.1:5433/pix2pi?sslmode=disable
OK ✅ DB_READ_DSN found in .env
DB_READ_DSN=postgres://user:pass@localhost:5433/dbname?sslmode=disable
OK ✅ DB_WRITE_DSN found in /opt/pix2pi/orchestrator/env/common.env
DB_WRITE_DSN="host=localhost port=5433 user=pix2pi password=***MASKED*** dbname=pix2pi sslmode=disable"
OK ✅ DB_READ_DSN found in /opt/pix2pi/orchestrator/env/common.env
DB_READ_DSN="host=localhost port=5433 user=pix2pi password=***MASKED*** dbname=pix2pi sslmode=disable"
```

## 6-2.3 Host / Kernel

```text
Linux vm12827.ovadns.com 5.15.0-176-generic #186-Ubuntu SMP Fri Mar 13 11:01:42 UTC 2026 x86_64 x86_64 x86_64 GNU/Linux
```

## 6-2.4 Disk Usage

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

## 6-2.5 DB Port Listening Check

```text
LISTEN 0      4096         0.0.0.0:5434       0.0.0.0:*    users:(("docker-proxy",pid=3064,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096         0.0.0.0:5433       0.0.0.0:*    users:(("docker-proxy",pid=1294029,fd=8))                                                                                                                                                                                                                  
LISTEN 0      4096            [::]:5434          [::]:*    users:(("docker-proxy",pid=3072,fd=8))                                                                                                                                                                                                                     
LISTEN 0      4096            [::]:5433          [::]:*    users:(("docker-proxy",pid=1294037,fd=8))                                                                                                                                                                                                                  
```

## 6-2.6 Docker PostgreSQL Containers

```text
NAMES                     IMAGE                             STATUS                PORTS
pix2pi_pg_replica         postgres:16                       Up 9 days             0.0.0.0:5434->5432/tcp, [::]:5434->5432/tcp
pix2pi_pg                 postgres:16                       Up 3 days             0.0.0.0:5433->5432/tcp, [::]:5433->5432/tcp
```

## 6-2.7 pg_isready Container Probe

```text
===== container: pix2pi_pg_replica =====
/var/run/postgresql:5432 - accepting connections
===== container: pix2pi_pg =====
/var/run/postgresql:5432 - accepting connections
```

## 6-2.8 psql Version

```text
psql (PostgreSQL) 14.22 (Ubuntu 14.22-0ubuntu0.22.04.1)
```

## 6-2.9 DB-L8 Readiness Result

```text
6-2.1 Read/write split inventory checked OK ✅
6-2.2 Replica/read pool readiness inventory checked OK ✅
6-2.3 Connection pool strategy document checked OK ✅
6-2.4 Index/query tuning checklist checked OK ✅
6-2.5 PITR/restore readiness checklist checked OK ✅
6-2.6 Partition/shard readiness model checked OK ✅
6-2.7 DB observability evidence generated OK ✅
6-2.8 DB final closure gate evidence generated OK ✅
FAZ_6_2_AUDIT_EVIDENCE=READY ✅
```
