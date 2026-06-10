# FAZ 5-18.3.2 — KVKK / Gizlilik Metinleri

## Faz Bilgisi

- Faz: FAZ 5-R — Commercial / Public Launch Final Closure
- İş No: 243
- İş: KVKK / gizlilik metinleri
- Durum: Taslak içerik + runtime contract hazır
- Hukukçu Onayı: Bekliyor
- KVKK Danışmanı Onayı: Bekliyor
- Public Publish Allowed: false
- Core Product Allowed: true
- Data Monetization Public Allowed: false

## Amaç

Bu iş, Pix2pi Ticaret Operasyon Sistemi için KVKK, gizlilik, açık rıza, çerez, ticari elektronik ileti, onay kayıtları ve gizlilik tercihleri dokümanlarını ayrı ayrı, sürümlü ve yazılım tarafından okunabilir hale getirir.

## Kritik Ayrım

Aydınlatma metni, açık rıza metni, çerez politikası ve ticari elektronik ileti onayı birbirinden ayrı tutulur.

Core ERP/POS ürün kullanımı, onaylı temel KVKK ve kullanım metinleriyle açılabilir. Veri destekli ticari fayda modeli, sponsorlu teklif, kişisel veri bazlı hedefleme, ticari elektronik ileti ve veri monetizasyonu ayrı gate ve tercih kayıtlarıyla yönetilir.

## Üretilen Belgeler

1. privacy_notice.tr.md
2. privacy_policy.tr.md
3. explicit_consent.tr.md
4. cookie_policy.tr.md
5. commercial_electronic_message_consent.tr.md
6. data_processing_inventory.tr.md
7. privacy_preference_matrix.tr.md
8. consent_registry_runtime_contract.tr.md

## Runtime Kuralı

Sistem tenant ve kullanıcı bazında şu kayıtları tutmalıdır:

- privacy_notice_version
- explicit_consent_version
- cookie_policy_version
- commercial_message_consent_version
- consent_status
- consent_scope
- accepted_at
- revoked_at
- tenant_id
- user_id
- ip_address
- user_agent
- channel
- evidence_hash

## Public Gate

LEGAL_APPROVAL_STATUS ve KVKK_APPROVAL_STATUS APPROVED olmadan bu metinler production müşteri onay akışına resmi metin olarak bağlanmaz.

## Final Hedef

Bu işin sonunda KVKK/gizlilik metinleri sadece doküman değil, software-readable compliance contract olur.
