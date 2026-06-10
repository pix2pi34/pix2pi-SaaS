# FAZ 4C — 4C-2B Critical Runtime Gap Classification

## Blok

4C-2B — Critical Runtime Gap Classification

## Kaynak

Kaynak rapor:
reports/pilot/faz4c/4c_2a_runtime_baseline_gap_scan_report.md

---

## 1. 4C-2A ozet

4C_2A_CRITICAL_BLOCKER_COUNT=0
4C_2A_WARNING_COUNT=1

4C-2A sonucuna gore sistemde kritik blocker tespit edilmedi.
4C-2B bu sonucu ayrintili siniflandirir.

---

## 2. Critical blocker listesi

- Kritik blocker yok


---

## 3. Warning listesi

- Repo kokunde docker-compose.yml yok. Sistem calisiyor ama deploy dosya yeri netlestirilmeli.
- pix2pi-identity-api.service systemd tarafinda active degil. Ancak Docker container aktif olabilir; servis stratejisi netlestirilmeli.
- Identity icin 9001 beklenmis ama cevap yok. Docker raporunda identity-api 9002 portunda gorunuyor; port standardi netlestirilmeli.
- Grafana 3000 portunda cevap vermiyor. Docker raporunda Grafana 3001->3000 map edilmis; port standardi netlestirilmeli.


---

## 4. Info listesi

- /etc/pix2pi/ports.env bulundu.
- /opt/pix2pi/orchestrator/env/common.env bulundu.
- fail2ban active.
- cron active.
- Prometheus ready 200.
- Node exporter metrics 200.
- cAdvisor metrics 200.


---

## 5. Ozel yorum

Identity icin 9001 portu beklenmis, fakat Docker container listesinde identity-api 9002 portunda calisiyor gorunuyor.

Grafana icin 3000 portu beklenmis, fakat Docker container listesinde Grafana 3001->3000 map edilmis gorunuyor.

Bu iki durum su an pilot tenant kurulumu icin kritik blocker degil.
Ancak 4C-2 icinde runtime port standardi netlestirilmelidir.

---

## 6. Karar

4C_2B_CLASSIFICATION_STATUS=PASS
4C_2B_CRITICAL_BLOCKER_COUNT=0
4C_2B_WARNING_COUNT=4
4C_2B_INFO_COUNT=7
4C_2B_RUNTIME_PORT_STANDARDIZATION_NEEDED=YES
4C_2B_IDENTITY_PORT_MISMATCH=YES
4C_2B_GRAFANA_PORT_MISMATCH=YES
4C_2B_NEXT_STEP_READY=YES
4C_2C_READY=YES
