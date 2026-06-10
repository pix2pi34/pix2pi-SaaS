# FAZ 7-8 Marketplace / Integration Catalog Foundation

## Status

This document represents FAZ 7-8 FIX/V2 scope alignment.

The first 7-8 foundation created a provider-neutral catalog. FIX/V2 expands the phase into the enterprise catalog scope required before FAZ 7-9.

## 7-8 Objective

Build the central catalog foundation for future Pix2pi integrations, marketplace applications, and connector modules.

This phase is not a real connector implementation phase. It defines the controlled catalog, runtime model, tenant install readiness model, entitlement mapping, and auditable integration foundation.

## 7-8.1 Module Boundary / Scope Freeze

Rules:

- Marketplace catalog is separated from real connector runtime.
- Real Trendyol, Hepsiburada, N11, Paraşüt, Logo, Mikro, Zirve, ETA, payment, e-document, logistics, CRM, and public API connector runtime is not implemented in this phase.
- This phase implements only the catalog foundation.
- Each real integration provider must later be opened as a provider-specific module.
- Production provider credentials remain closed.
- Real payment live status remains CLOSED.

## 7-8.2 Integration Catalog Domain Model

Required models:

- IntegrationProvider
- IntegrationApp
- IntegrationCategory
- Capability
- AuthMode
- SyncDirection
- PricingPlanRequirement

The catalog model must be provider-neutral and tenant-safe.

## 7-8.3 Marketplace Catalog Model

Marketplace application listing fields:

- app_code
- title
- description
- category
- provider_code
- module_code
- status
- required_plan
- required_entitlement
- setup_mode
- capabilities

## 7-8.4 Connector Capability Matrix

Supported capabilities:

- READ_PRODUCTS
- WRITE_PRODUCTS
- READ_ORDERS
- WRITE_ORDERS
- READ_CUSTOMERS
- WRITE_CUSTOMERS
- WEBHOOK_INTAKE
- FILE_EXPORT
- API_SYNC
- MANUAL_IMPORT

Unsupported capabilities must be rejected by validation.

## 7-8.5 Tenant Install / Enablement Readiness

Required tenant install statuses:

- INSTALLED
- DISABLED
- PENDING_CONFIG
- BLOCKED

Tenant installs must use a tenant-safe install key.

Install key shape:

tenant:<tenant_id>|provider:<provider_code>|app:<app_code>

The install readiness model does not store provider secrets and does not activate a real external connector.

## 7-8.6 Entitlement Integration

The catalog must support:

- plan requirement checks
- entitlement feature gate checks
- marketplace item to feature_code mapping
- app install readiness based on plan and entitlement

## 7-8.7 Config Artifact

Config artifact:

configs/faz7/marketplace_integration_catalog.v1.json

It includes:

- provider list
- app listing list
- category list
- capability list
- auth mode list
- sync direction list
- entitlement requirement list
- default safety rules

## 7-8.8 Runtime Code

Runtime package:

internal/platform/commercial/integrationcatalog/catalog.go

Runtime responsibilities:

- provider catalog runtime
- marketplace listing runtime
- tenant install readiness runtime
- entitlement check helper
- capability check helper
- validation helpers

## 7-8.9 Tests

Required tests:

- provider catalog validation test
- marketplace listing test
- capability matrix test
- tenant install status test
- entitlement gate test
- duplicate provider_code reject test
- unsupported capability reject test
- tenant-safe install key test
- config artifact validation test

## 7-8.10 Real Implementation Audit

Audit checks:

- doc exists
- config exists
- runtime code exists
- test code exists
- provider model exists
- app/listing model exists
- category model exists
- capability model exists
- auth mode model exists
- sync direction model exists
- pricing/plan requirement model exists
- tenant install model exists
- entitlement mapping exists
- go test passes
- audit evidence file is written

## 7-8.11 Final Gate

Final gate must be counter-derived:

- GO_TEST_STATUS=PASS
- REAL_AUDIT_STATUS=PASS
- PASS_COUNT > 0
- FAIL_COUNT=0
- REQUIRED_FAIL=0
- OPTIONAL_WARN=0
- FAZ_7_8_FINAL_STATUS=PASS
- FAZ_7_8_SCOPE_ALIGNMENT_STATUS=PASS
- FAZ_7_8_ENTERPRISE_CATALOG_STATUS=PASS
- FAZ_7_9_READY=YES

## Non-Goals

This phase does not implement:

- real marketplace API sync
- real order import
- real stock push
- real customer sync
- real e-document dispatch
- real payment provider production connection
- real logistics provider connection
- real provider secret management
- real webhook public endpoint
