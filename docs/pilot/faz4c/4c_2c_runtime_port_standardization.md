# FAZ 4C — 4C-2C Runtime Port Standardization Notes

## Blok

4C-2C — Runtime Port Standardization Notes

## Amaç

Bu adımda FAZ 4C pilot öncesi gerçek runtime port durumu kayıt altına alınır.

Bu adım port değiştirmez.
Bu adım servis restart etmez.
Bu adım sadece mevcut çalışan port standardını dokümante eder.

Amaç:
Yanlış port beklentisi yüzünden hatalı test sonucu oluşmasını engellemek.

---

## 1. Kaynak raporlar

Kaynak raporlar:

- reports/pilot/faz4c/4c_2a_runtime_baseline_gap_scan_report.md
- reports/pilot/faz4c/4c_2b_critical_runtime_gap_classification_report.md

4C-2A sonucu:
4C_2A_CRITICAL_BLOCKER_COUNT=0

4C-2B sonucu:
4C_2B_CRITICAL_BLOCKER_COUNT=0
4C_2B_WARNING_COUNT=4

---

## 2. Gerçek runtime port durumu

4C-2A taramasına göre gerçek durum:

| Servis / Bileşen | Beklenen / Eski Port | Gerçek Durum | Karar |
|---|---:|---|---|
| API Gateway | 9010 | 9010 LISTEN / health 200 | Standart kabul |
| PostgreSQL primary host | 5433 | 5433 LISTEN | Standart kabul |
| PostgreSQL replica host | 5434 | Docker container aktif | Bilgi |
| Identity API | 9001 beklenmişti | Docker container 9002 portunda | 9002 runtime gerçekliği not edildi |
| Mission Control | 9101 | Docker map 9101->5860 | Runtime gerçekliği not edildi |
| Grafana | 3000 beklenmişti | Docker map 3001->3000 | 3001 runtime gerçekliği not edildi |
| Prometheus | 9090 | 9090 LISTEN / ready 200 | Standart kabul |
| Node Exporter | 9100 | 9100 LISTEN / metrics 200 | Standart kabul |
| cAdvisor | 8080 | 8080 LISTEN / metrics 200 | Standart kabul |
| Loki | 3100 | Docker container aktif | Bilgi |
| Tempo | 3200 / 4317 / 4318 | Docker container aktif | Bilgi |
| Redis | 6379 | Docker container aktif | Bilgi |
| NATS | 4222 / 8222 | Docker container aktif | Bilgi |

---

## 3. Port kararları

### 3.1 Pilot için kritik kabul edilen portlar

Pilot tenant kurulumu ve runtime gap completion için kritik portlar:

- API Gateway: 9010
- PostgreSQL primary host: 5433
- Redis: 6379
- NATS: 4222
- Prometheus: 9090
- Node Exporter: 9100
- cAdvisor: 8080

Bu portlar çalışıyor görünüyor.

---

### 3.2 Warning olarak izlenecek portlar

Aşağıdaki portlar kritik blocker değildir; ancak standartlaştırma gerektirir:

#### Identity API

Eski beklenti:
9001

Gerçek runtime:
9002

Karar:
FAZ 4C içinde testler identity için 9002 gerçek runtime durumunu dikkate alacak.
9001 beklentisi eski veya farklı servis routing izinden gelmiş olabilir.

#### Grafana

Eski beklenti:
3000

Gerçek runtime:
3001 -> 3000

Karar:
FAZ 4C içinde Grafana host erişimi için 3001 gerçek runtime portu kabul edilecek.

#### docker-compose.yml

Repo kökünde docker-compose.yml bulunmadı.

Karar:
Bu pilot için kritik blocker değildir.
Çalışan container yapısı Docker üzerinde aktif.
Deploy dosya standardı ileride ayrıca netleştirilecek.

#### Identity systemd inactive

pix2pi-identity-api.service systemd tarafında inactive.

Karar:
Bu pilot için kritik blocker değildir.
Çünkü identity-api Docker container olarak çalışıyor görünüyor.
Ama servis yönetim stratejisi ileride netleştirilecek: systemd mi container mı?

---

## 4. FAZ 4C port standardı

FAZ 4C pilot runtime kontrollerinde kullanılacak port standardı:

API_GATEWAY_PORT=9010
IDENTITY_API_PORT=9002
POSTGRES_PRIMARY_HOST_PORT=5433
POSTGRES_REPLICA_HOST_PORT=5434
REDIS_PORT=6379
NATS_CLIENT_PORT=4222
NATS_MONITORING_PORT=8222
PROMETHEUS_PORT=9090
GRAFANA_HOST_PORT=3001
NODE_EXPORTER_PORT=9100
CADVISOR_PORT=8080
LOKI_PORT=3100
TEMPO_PORT=3200
MISSION_CONTROL_HOST_PORT=9101

---

## 5. Pilot için karar

Bu port uyumsuzlukları FAZ 4C pilot tenant setup adımını durdurmaz.

Kritik blocker yoktur.

4C_2C_RUNTIME_PORT_STANDARDIZATION_STATUS=PASS
4C_2C_CRITICAL_BLOCKER_COUNT=0
4C_2C_WARNING_COUNT=4
4C_2C_IDENTITY_RUNTIME_PORT=9002
4C_2C_GRAFANA_RUNTIME_PORT=3001
4C_2C_GATEWAY_RUNTIME_PORT=9010
4C_2C_POSTGRES_PRIMARY_PORT=5433
4C_2C_NEXT_STEP_READY=YES
4C_2D_READY=YES

---

## 6. Sonraki adım

Sonraki adım:

4C-2D — Runtime Endpoint Validation

Bu adımda artık port standardına göre endpoint doğrulamaları yapılacak.
