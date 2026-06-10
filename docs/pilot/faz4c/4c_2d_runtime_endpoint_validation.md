# FAZ 4C — 4C-2D Runtime Endpoint Validation

## Blok

4C-2D — Runtime Endpoint Validation

## Amaç

Bu adım FAZ 4C pilot öncesi gerçek endpoint ve port doğrulamasını yapar.

Bu adım servis değiştirmez.
Bu adım restart yapmaz.
Bu adım sadece doğrulama ve raporlama yapar.

---

## 1. Port validation

| Bileşen | Port | Durum |
|---|---:|---|
| API Gateway | 9010 | LISTEN |
| Identity API | 9002 | LISTEN |
| PostgreSQL Primary | 5433 | LISTEN |
| PostgreSQL Replica | 5434 | LISTEN |
| Redis | 6379 | LISTEN |
| NATS Client | 4222 | LISTEN |
| NATS Monitoring | 8222 | LISTEN |
| Prometheus | 9090 | LISTEN |
| Grafana | 3001 | LISTEN |
| Node Exporter | 9100 | LISTEN |
| cAdvisor | 8080 | LISTEN |
| Loki | 3100 | LISTEN |
| Tempo | 3200 | LISTEN |
| Mission Control | 9101 | LISTEN |

---

## 2. HTTP endpoint validation

| Endpoint | Sonuç |
|---|---|
| Gateway /health | 200 |
| Identity /health | 200 |
| Prometheus /-/ready | 200 |
| Grafana /api/health | 200 |
| Node Exporter /metrics | 200 |
| cAdvisor /metrics | 200 |
| NATS /healthz | NO_RESPONSE |
| NATS /varz | NO_RESPONSE |
| Loki /ready | 200 |
| Tempo /ready | 200 |
| Mission Control /health | 200 |

---

## 3. Critical listesi

- Kritik endpoint blocker yok


---

## 4. Warning listesi

- NATS monitoring endpoint 200 donmedi. healthz=NO_RESPONSE varz=NO_RESPONSE


---

## 5. Info listesi

- Redis port 6379 LISTEN.
- NATS client port 4222 LISTEN.
- NATS monitoring port 8222 LISTEN.
- Identity runtime port 9002 LISTEN.
- Identity /health 200.
- Prometheus ready 200.
- Grafana health 200.
- Node Exporter metrics 200.
- cAdvisor metrics 200.
- Loki ready 200.
- Tempo ready 200.
- Mission Control health 200.


---

## 6. Pilot kararı

4C-2D sonucuna göre kritik endpoint blocker sayısı:

4C_2D_CRITICAL_BLOCKER_COUNT=0

Gateway ve PostgreSQL primary kritik kabul edilir.
Identity warning olarak izlenir; çünkü 4C-4 user/role assignment öncesi tekrar özel kontrol yapılacak.

---

## 7. Status

4C_2D_ENDPOINT_VALIDATION_STATUS=PASS
4C_2D_CRITICAL_BLOCKER_COUNT=0
4C_2D_WARNING_COUNT=1
4C_2D_INFO_COUNT=12
4C_2D_GATEWAY_HEALTH_HTTP=200
4C_2D_IDENTITY_HEALTH_HTTP=200
4C_2D_POSTGRES_PRIMARY_PORT_STATUS=LISTEN
4C_2D_NEXT_STEP_READY=YES
4C_2E_READY=YES
