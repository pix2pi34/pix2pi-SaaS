# 7-3 — Entitlement Runtime / Feature Gate

## Adim Amaci

Bu adim Pix2pi paket katalogunu gercek hak kontrol runtime'ina baglar.

7-3 sonunda:

- Plan bazli feature kontrolu yapilir.
- Tenant context zorunlu hale gelir.
- User context zorunlu hale gelir.
- Limit kontrolu yapilir.
- API/export/user/tenant/integration haklari kontrol edilebilir hale gelir.
- Deny sebepleri standart hale gelir.
- 7-4 Commercial Account / Subscription Runtime icin temel hazirlanir.

## 7-3.1 Entitlement Cekirdegi

### 7-3.1.1 Paket hakki kontrolu
Durum: IMPLEMENTED_OR_PRESENT

Bir tenant'in sahip oldugu plan uzerinden ilgili feature'in acik olup olmadigi kontrol edilir.

Kontrol sonucu:

- ALLOW
- DENY

Deny sebebi acik sekilde doner.

### 7-3.1.2 Tenant bazli feature flag
Durum: IMPLEMENTED_OR_PRESENT

Feature kontrolu tenant context olmadan calismaz.

Tenant id bos ise runtime karar motoru istegi reddeder.

### 7-3.1.3 Kullanici bazli entitlement
Durum: IMPLEMENTED_OR_PRESENT

User id bos ise runtime karar motoru istegi reddeder.

Bu sayede audit izi tenant + user seviyesinde tutulabilir.

### 7-3.1.4 API/gateway seviyesinde paket kontrolu
Durum: IMPLEMENTED_OR_PRESENT

API ve gateway katmani ileride bu runtime motorunu kullanarak:

- api_access_basic
- api_access_advanced
- webhook_access
- integration_catalog
- marketplace_discovery

gibi haklari kontrol edebilecektir.

### 7-3.1.5 Audit log ile entitlement izi
Durum: IMPLEMENTED_OR_PRESENT

Entitlement karar sonucu audit edilebilir alanlar uretir:

- tenant_id
- user_id
- plan_code
- feature_code
- limit_code
- decision
- reason_code
- reason_message

## 7-3.2 Limit Gate

### 7-3.2.1 Kullanici limiti
Durum: IMPLEMENTED_OR_PRESENT

Plan kullanici limiti asilirsa DENY doner.

### 7-3.2.2 Tenant limiti
Durum: IMPLEMENTED_OR_PRESENT

Plan tenant limiti asilirsa DENY doner.

### 7-3.2.3 API aylik istek limiti
Durum: IMPLEMENTED_OR_PRESENT

Plan API aylik istek limiti asilirsa DENY doner.

### 7-3.2.4 Export limiti
Durum: IMPLEMENTED_OR_PRESENT

Plan aylik export limiti asilirsa DENY doner.

### 7-3.2.5 Entegrasyon limiti
Durum: IMPLEMENTED_OR_PRESENT

Plan entegrasyon limiti asilirsa DENY doner.

## 7-3.3 Code Artifact

Durum: IMPLEMENTED_OR_PRESENT

Entitlement runtime Go modeli:

- internal/platform/commercial/entitlement/entitlement.go
- internal/platform/commercial/entitlement/entitlement_test.go

## 7-3.4 Config Artifact

Durum: IMPLEMENTED_OR_PRESENT

Entitlement runtime config dosyasi:

- configs/faz7/entitlement_feature_gate.v1.json

## 7-3.5 7-4 Gecis Hazirligi

Durum: IMPLEMENTED_OR_PRESENT

7-3 tamamlandiginda 7-4 icin asagidaki runtime temeller hazirdir:

- Plan kodu ile hak kontrolu
- Feature kodu ile gate kontrolu
- Limit kodu ile kota kontrolu
- Tenant/user context zorunlulugu
- Audit edilebilir karar modeli

## 7-3 Final Karari

- FAZ_7_3_DOC_STATUS=READY
- FAZ_7_3_CONFIG_STATUS=READY
- FAZ_7_3_CODE_STATUS=READY
- FAZ_7_3_TEST_REQUIRED=YES
- FAZ_7_3_REAL_IMPLEMENTATION_AUDIT_REQUIRED=YES
- FAZ_7_4_READY_CONDITION=FAZ_7_3_TEST_STATUS_PASS_AND_REAL_IMPLEMENTATION_STATUS_PASS
