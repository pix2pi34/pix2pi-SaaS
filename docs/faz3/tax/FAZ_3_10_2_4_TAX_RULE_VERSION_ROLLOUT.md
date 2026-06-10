# 125 — FAZ 3-10.2.4 — Vergi rule version rollout

## Amaç

Bu adım, KDV / Stopaj / Tax Exemption gibi vergi runtime kurallarının versiyonlu şekilde rollout edilmesini sağlar.

## Kapsam

- Tax rule version modeli
- Full rollout
- Canary rollout
- Blue/green rollout readiness
- Activate version
- Rollback version
- Legal reference guard
- Approval guard
- Evidence file/hash guard
- Artifact path guard
- Country TR guard
- Canary percent guard
- Canary tenant allowlist guard
- Rollback reason guard
- Version family consistency guard
- Runtime/config/audit switch readiness

## Desteklenen Vergi Aileleri

- KDV
- STOPAJ
- TAX_EXEMPTION
- OTV
- DAMGA
- CUSTOM

## Kapanış Kuralı

Bu adım şu durumda PASS olur:

- Runtime dosyası var
- Test dosyası var
- Config artifact var
- Documentation artifact var
- Go test PASS
- Real implementation audit PASS
- Full rollout / canary / activate / rollback / invalid path testleri PASS
