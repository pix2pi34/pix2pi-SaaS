# Consent Registry Runtime Contract

DOCUMENT_SLUG: consent_registry_runtime_contract
DOCUMENT_STATUS: DRAFT
DOCUMENT_VERSION: 0.1.0-draft
PUBLIC_PUBLISH_ALLOWED: NO
LEGAL_APPROVAL_STATUS: PENDING
KVKK_APPROVAL_STATUS: PENDING
SYSTEM_NAME: Pix2pi Ticaret Operasyon Sistemi

## 1. Zorunlu Alanlar

- tenant_id
- user_id
- consent_scope
- consent_status
- document_version
- accepted_at
- revoked_at
- ip_address
- user_agent
- channel
- evidence_hash

## 2. Runtime Kuralı

Her ticari veri hattı, sponsorlu teklif hedefleme, ticari elektronik ileti, çerez ve kişisel veri bazlı öneri akışı consent registry ve feature gate durumunu okumalıdır.

## 3. Bloklama

Gerekli onay veya plan tercihi yoksa ilgili özellik kapatılır veya ücretli/kısıtlı plana yönlendirilir.
