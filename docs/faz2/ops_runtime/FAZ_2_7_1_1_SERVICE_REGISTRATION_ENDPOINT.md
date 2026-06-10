# FAZ 2-7.1.1 — Gerçek Service Registration Endpoint

## Amaç

Bu adım Ops Runtime Closure içinde gerçek service registration HTTP endpoint temelini kurar.

## Kapsam

- Gerçek service registration HTTP endpoint
- Service instance register bridge
- Metadata persistence bridge
- Tenant-aware registration guard
- Endpoint request validation
- Endpoint response / audit decision fields
- Service registration endpoint testleri

## Endpoint

```text
POST /ops/registry/register
X-Tenant-ID: <tenant_id>
```

## Request örneği

```json
{
  "service_name": "identity-api",
  "host": "10.0.0.7",
  "port": 9001,
  "zone": "tr-istanbul-1",
  "node_id": "node-a",
  "runtime": "go",
  "version": "1.0.0",
  "status": "HEALTHY",
  "metadata_visibility": "TENANT",
  "metadata": {
    "build_sha": "abc123"
  }
}
```

## Tenant güvenliği

Varsayılan olarak tenant header zorunludur:

```text
X-Tenant-ID
```

Body içinde tenant_id verilirse header ile eşleşmelidir. Eşleşmezse reddedilir:

```text
ErrServiceRegistrationEndpointCrossTenant
```

## Final gate

Bu adım ancak Go test ve real implementation audit PASS olduğunda kapanır.

## Dosyalar

- Runtime: `internal/platform/ops/runtime/service_registration_endpoint_runtime.go`
- Test: `internal/platform/ops/runtime/service_registration_endpoint_runtime_test.go`
- Config: `configs/faz2/ops_runtime/service_registration_endpoint.v1.json`
- Audit: `scripts/audit/faz2/faz_2_7_1_1_service_registration_endpoint_audit.sh`
- Evidence: `docs/faz2/evidence/FAZ_2_7_1_1_SERVICE_REGISTRATION_ENDPOINT_REAL_IMPLEMENTATION_AUDIT_20260507_070321.md`
