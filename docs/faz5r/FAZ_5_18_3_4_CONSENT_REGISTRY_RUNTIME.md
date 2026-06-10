# FAZ 5-18.3.4 — Consent Registry / Onay Kayıt Runtime

## Faz Bilgisi

- Faz: FAZ 5-R — Commercial / Public Launch Final Closure
- İş No: 244
- İş: Consent Registry / Onay Kayıt Runtime
- Durum: Runtime contract + Go implementation + test hazır
- Core Product Allowed: true
- Data Monetization Guarded: true
- Commercial Benefit Guarded: true
- Public Publish Allowed: false

## Amaç

Bu iş, Pix2pi Ticaret Operasyon Sistemi içinde müşteri/tenant/kullanıcı bazlı sözleşme kabulü, açık rıza, ticari elektronik ileti onayı, çerez tercihi ve veri destekli plan kabulünü yazılımın otomatik okuyacağı bir runtime modele bağlar.

## Kritik Kural

Sözleşme metni tek başına yeterli değildir. Yazılım, her tenant ve kullanıcı için onay durumunu runtime olarak okuyabilmelidir.

## Tutulacak Ana Kayıtlar

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
- correlation_id

## Consent Scope

- DATA_SUPPORTED_PLAN_TERMS
- PERSONAL_DATA_COMMERCIAL_RECOMMENDATION
- SPONSORED_OFFER_PERSONALIZATION
- ANONYMIZED_AGGREGATED_INSIGHT
- AI_DECISION_SUPPORT
- COMMERCIAL_ELECTRONIC_MESSAGE
- NON_ESSENTIAL_COOKIES

## Feature Gate Davranışı

Onay yoksa:

- veri destekli ücretsiz/indirimli plan açılmaz
- kişisel veri bazlı tedarik önerisi açılmaz
- sponsorlu teklif hedefleme açılmaz
- ticari elektronik ileti gönderilmez
- zorunlu olmayan çerezler çalışmaz
- data monetization pipeline block edilir
- kullanıcı veri kullanımı kısıtlı ücretli plana yönlendirilebilir

## Core Product Ayrımı

Core ERP/POS ürünü consent eksik diye otomatik kapanmaz. Sadece ilgili veri destekli ve pazarlama/ticari fayda özellikleri kapatılır.

## Audit Kuralı

Her onay, ret ve geri alma işlemi evidence_hash, document_version, tenant_id, user_id, ip_address ve channel bilgisiyle kayıt altına alınmalıdır.
