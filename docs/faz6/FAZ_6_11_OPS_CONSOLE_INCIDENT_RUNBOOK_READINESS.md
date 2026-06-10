# Pix2pi — FAZ 6-11 Ops Console / Incident / Runbook Readiness

## Faz Bilgisi

Faz: FAZ 6  
Adim: 6-11  
Adim Adi: Ops Console / Incident / Runbook Readiness  
Onceki Adim: 6-10 CDN / WAF / DNS / Edge Readiness  
Onceki Adim Durumu: PASS  
Bu Adim Amaci: Pix2pi operasyon, incident, runbook, servis sagligi ve SRE yonetim hazirligini kanitlamak  
Risk Seviyesi: Kontrollu  
Runtime Etkisi: Bu adim servis restart etmez, config degistirmez, incident acmaz  
Sonraki Adim: 6-12 Production Readiness / Final Hardening Gate  

---

# 6-11 Ana Karar

Production sistemde sadece teknik altyapi yeterli degildir.

Operasyonel kalite icin hedef:
- servislerin tek bakista gorulebilmesi,
- incident durumunda ne yapilacaginin bilinmesi,
- runbook standardinin olmasi,
- severity / priority kararinin netlesmesi,
- on-call / escalation akisi bulunmasi,
- evidence ve postmortem kulturunun kurulmasidir.

Bu adimda gercek incident acilmaz. Incident/runbook standardi ve audit evidence uretilir.

---

# 6-11.1 Ops Console Readiness

Ops Console hedefi:
- sistemin genel sagligini gostermek,
- servis UP/DOWN durumunu gostermek,
- DB / Redis / NATS / Gateway / Observability durumunu gostermek,
- son incident / warning / blocker sinyallerini gostermek,
- operatorun tek ekrandan karar vermesini saglamaktir.

Minimum ops console alanlari:
- service name,
- status,
- health URL,
- last checked time,
- latency,
- dependency status,
- tenant impact,
- last error,
- action / runbook link.

---

# 6-11.2 Service Health Summary

Service health summary:
- identity-api,
- api-gateway,
- mission-control,
- service-registry,
- event-consumer,
- DB,
- Redis,
- NATS,
- Prometheus,
- Grafana,
- node_exporter,
- cAdvisor,
- Nginx public edge.

Health sonucu:
- OK,
- WARN,
- DOWN,
- UNKNOWN.

---

# 6-11.3 Incident Lifecycle

Incident lifecycle:
- DETECTED,
- TRIAGED,
- MITIGATING,
- MONITORING,
- RESOLVED,
- POSTMORTEM_REQUIRED,
- CLOSED.

Incident kaydinda minimum alanlar:
- incident_id,
- severity,
- priority,
- affected_service,
- affected_tenant,
- detected_at,
- owner,
- summary,
- customer_impact,
- technical_impact,
- action_log,
- evidence_links,
- final_status.

---

# 6-11.4 Severity / Priority Matrix

Severity:
- SEV1: sistem geneli down / veri kaybi riski / finansal double-write riski
- SEV2: kritik servis kismi down / tenant etkisi yuksek / event backlog kritik
- SEV3: sinirli tenant etkisi / performans dususu / warning
- SEV4: kozmetik / dokuman / non-blocking issue

Priority:
- P0: hemen aksiyon
- P1: ayni gun
- P2: planli sprint
- P3: backlog

---

# 6-11.5 Runbook Standard

Her runbook sunlari icermelidir:
- problem tanimi,
- belirtiler,
- ilk bakilacak komutlar,
- riskli komutlar,
- kesinlikle yapilmamasi gerekenler,
- safe diagnostic komutlari,
- recovery adimlari,
- smoke test,
- rollback opsiyonu,
- incident kapanis notu.

---

# 6-11.6 On-call / Escalation Flow

Escalation hedefi:
- kim bakacak,
- ne zaman escalate edilecek,
- hangi kanallardan haber verilecek,
- musteri etkisi nasil bildirilecek,
- teknik root cause ne zaman yazilacak.

Ilk asama:
- founder/operator,
- infra owner,
- backend owner,
- DB owner,
- security owner,
- business owner.

---

# 6-11.7 Incident Evidence Standard

Evidence kaynaklari:
- service health output,
- docker ps,
- systemd status,
- nginx -t,
- journalctl tail,
- app logs,
- DB readiness,
- NATS /varz,
- Prometheus targets,
- Grafana health,
- public GET content check,
- backup/snapshot durumu.

---

# 6-11.8 Postmortem Standard

Postmortem alanlari:
- incident summary,
- timeline,
- root cause,
- trigger,
- impact,
- detection gap,
- response gap,
- what went well,
- what went wrong,
- action items,
- owner,
- due date,
- prevention plan.

---

# 6-11.9 Ops Console Guard Scripts

Bu adimda kurulacak scriptler:
- scripts/pix2pi_ops_console_probe.sh
- scripts/pix2pi_runbook_template_check.sh
- scripts/audit_faz6_11_ops_runtime.sh
- scripts/audit_faz6_11_real_implementation.sh
- scripts/test_faz6_11_ops_console_incident_runbook.sh

Bu scriptler destructive islem yapmaz.
Sadece evidence uretir.

---

# 6-11.10 Ops Final Closure Gate

6-11 kapanis kriterleri:

- Ops Console / Incident / Runbook dokumani hazir olmali.
- Visible checkpoint hazir olmali.
- Incident runbook template hazir olmali.
- Ops console runbook hazir olmali.
- Ops console probe script hazir olmali.
- Runbook template check script hazir olmali.
- Runtime audit evidence uretilmeli.
- Real implementation audit uretilmeli.
- Service health summary izi kontrol edilmeli.
- Incident lifecycle izi kontrol edilmeli.
- Severity / priority matrix izi kontrol edilmeli.
- Evidence / postmortem standardi kontrol edilmeli.
- PASS olmadan 6-12'ye gecilmemeli.

---

# 6-11 Muhur Hedefi

FAZ_6_11_DOC_STATUS=READY ✅  
FAZ_6_11_VISIBLE_CHECKPOINTS_STATUS=READY ✅  
FAZ_6_11_RUNBOOK_STATUS=READY ✅  
FAZ_6_11_OPS_GUARD_SCRIPTS_STATUS=READY ✅  
FAZ_6_11_RUNTIME_AUDIT_STATUS=COMPLETE ✅  
FAZ_6_11_REAL_IMPLEMENTATION_AUDIT_STATUS=COMPLETE ✅  
FAZ_6_11_TEST_STATUS=PASS ✅  
FAZ_6_11_FINAL_STATUS=PASS_OR_NEEDS_IMPLEMENTATION_REVIEW  
FAZ_6_12_READY=CONDITIONAL  
