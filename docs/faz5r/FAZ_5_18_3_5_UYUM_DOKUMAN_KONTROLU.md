# FAZ 5-R / 245 — FAZ 5-18.3.5 Uyum Doküman Kontrolü

## Amaç

Bu adım, FAZ 5-R Commercial / Public Launch Final Closure içinde KVKK, sözleşme, ticari kullanım şartları ve consent registry çıktılarının public launch öncesi tek bir kontrol kapısından geçirilmesini sağlar.

Bu çalışma canlı hukuk onayı değildir. Amaç, public launch öncesi doküman envanteri, versiyonlama, onay kapıları, public yayın kilidi ve gerçek müşteri veri toplama kilidini teknik olarak audit edilebilir hale getirmektir.

## Kapsam

Kontrol edilen ana dokümanlar:

1. Sözleşme seti
2. KVKK / gizlilik metinleri
3. Açık rıza metni
4. Ticari kullanım şartları
5. Consent registry policy
6. Log retention / imha politikası

## Kritik kurallar

- Tüm zorunlu dokümanlar versiyonlu olmalıdır.
- Hukukçu onayı olmadan sözleşme ve ticari şartlar public yayınlanamaz.
- KVKK danışmanı onayı olmadan KVKK, açık rıza, consent ve retention metinleri public yayınlanamaz.
- Founder go/no-go olmadan public publish açılamaz.
- Public launch allowed varsayılan olarak false kalır.
- Gerçek müşteri veri toplama varsayılan olarak false kalır.
- Internal readiness audit allowed true olabilir.

## Approval Gate Matrix

| Gate | Owner | Durum | Public etkisi |
|---|---|---:|---|
| legal_counsel_approval | legal | PENDING | Public publish blocker |
| kvkk_consultant_approval | kvkk | PENDING | Public publish blocker |
| founder_go_no_go | founder | PENDING | Public launch blocker |

## Çıkış kararı

Bu adım PASS olduğunda sistem şu seviyeye gelir:

- Doküman envanteri hazır
- Kontrol config'i hazır
- Go runtime kontrol paketi hazır
- Unit test hazır
- Audit script hazır
- Evidence üretilebilir
- Public publish hala kapalı
- Real customer collection hala kapalı

## Final policy

PUBLIC_PUBLISH_ALLOWED=false  
REAL_CUSTOMER_COLLECTION_ALLOWED=false  
INTERNAL_READINESS_AUDIT_ALLOWED=true  
NEXT_GATE=FAZ_5_18_4_1_SUPPORT_CHANNEL_SETUP
