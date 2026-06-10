# FAZ 2-7.2.5 — Incident Note / Action Log Runtime

## Amaç

Bu adım Mission Control runtime içinde incident note ve operator action log temelini kurar.

## Kapsam

- Incident note runtime
- Operator action log runtime
- Severity modeli
- Tenant-safe incident/action log guard
- Service instance incident metadata bridge
- Incident note / action log runtime testleri

## Operator role modeli

İzinli roller:

```text
PLATFORM_ADMIN
OPS_ADMIN
SRE
```

## Action type modeli

```text
INCIDENT_NOTE
OPERATOR_ACTION
```

## Severity modeli

```text
INFO
WARNING
CRITICAL
```

## Tenant güvenliği

Incident note / action log sadece request tenant_id kapsamındaki instance için oluşturulur.

Başka tenant instance log isteği reddedilir:

```text
ErrIncidentActionLogCrossTenant
```

## Metadata bridge

Runtime şu metadata kayıtlarını yazar:

```text
incident_action_log_id
incident_action_type
incident_action_severity
incident_action_operator_id
incident_action_logged_at
```

## Final gate

Bu adım ancak Go test ve real implementation audit PASS olduğunda kapanır.

## Dosyalar

- Runtime: `internal/platform/ops/runtime/incident_note_action_log_runtime.go`
- Test: `internal/platform/ops/runtime/incident_note_action_log_runtime_test.go`
- Config: `configs/faz2/ops_runtime/incident_note_action_log_runtime.v1.json`
- Audit: `scripts/audit/faz2/faz_2_7_2_5_incident_note_action_log_runtime_audit.sh`
- Evidence: `docs/faz2/evidence/FAZ_2_7_2_5_INCIDENT_NOTE_ACTION_LOG_RUNTIME_REAL_IMPLEMENTATION_AUDIT_20260507_071452.md`
