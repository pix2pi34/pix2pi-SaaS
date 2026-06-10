# FAZ 6-R / 291 — FAZ 6-21.6.4 Operasyonel İletişim Planı

## Amaç

Pix2pi DR / bölgesel kesinti / release incident durumlarında kullanılacak operasyonel iletişim planını tanımlar.

Bu adım gerçek SMS, e-posta, müşteri bildirimi, status page, telefon veya dış provider gönderimi yapmaz. Sadece record-only / dry-run iletişim karar modeli, stakeholder matrisi, mesaj şablonları, cadence, approval ve evidence standardı üretir.

## Bağımlılık

- FAZ 6-21.6.3 Bölgesel kesinti senaryosu

## Required Controls

- regional_outage_dependency_gate
- stakeholder_matrix
- severity_communication_mapping
- internal_update_policy
- customer_update_policy
- status_page_policy
- business_owner_approval_policy
- security_owner_approval_policy
- next_update_cadence_policy
- message_template_catalog
- channel_provider_closed_policy
- dry_run_communication_runtime
- evidence_capture_policy
- final_status_policy

## İletişim İlkeleri

1. P0/P1 olaylarda iletişim planı incident commander ile birlikte yürür.
2. Müşteri etkisi varsa customer-facing mesaj business owner approval olmadan gönderilmez.
3. Güvenlik etkisi varsa security owner approval gerekir.
4. Status page ve dış bildirim bu adımda açılmaz.
5. Tüm mesajlar record-only dry-run olarak üretilir.
6. Next update zamanı her mesajda bulunur.
7. İletişim kanalı, hedef kitle, severity ve owner açık olmalıdır.
8. Evidence olmadan DR rehearsal aşamasına geçilmez.

## Final Gate

- DOC_STATUS=READY
- CONFIG_STATUS=READY
- PLAN_STATUS=READY
- FIXTURE_STATUS=READY
- RUNTIME_STATUS=READY
- REAL_IMPLEMENTATION_STATUS=PASS
- FINAL_STATUS=PASS

