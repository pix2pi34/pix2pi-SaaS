# FAZ 4-R — General Final Review / Closure

## Amaç

FAZ 4-R — Pilot / Import / UAT Final Closure kapsamındaki 180–241 arası tüm işlerin genel kapanışını yapar.

Bu kapanış adımı yeni özellik geliştirmez. Canlı provider açmaz. GİB, banka, POS, ödeme sağlayıcı, gerçek WebSocket/SSE, gerçek event publish/subscribe, gerçek push/email/SMS teslimatı veya workflow mutation yapmaz.

## Kapsam

- Öncelik 1 — DB-L7 Migration / Import final review
- Öncelik 2 — DB-L6 Reporting / Readmodel final review
- Öncelik 3 — LVL17 Pilot / UAT / Onboarding final review
- Öncelik 4 — WEB-L7 Workflow / Realtime UI final review
- FAZ 4-R HTML live publish doğrulaması
- Kısmi kalan iş kontrolü
- Yapılmayan iş kontrolü
- Fail kalan iş kontrolü
- Policy gate doğrulaması
- Final closure manifest
- Final audit evidence

## Kapanış Kabul Kuralı

FAZ 4-R kapanışı PASS sayılırsa:

- total_item_count = 62 olmalıdır.
- sealed_item_count = 62 olmalıdır.
- partial_item_count = 0 olmalıdır.
- pending_item_count = 0 olmalıdır.
- fail_item_count = 0 olmalıdır.
- required_fail_count = 0 olmalıdır.
- optional_warn_count = 0 olmalıdır.
- priority_1_status = SEALED olmalıdır.
- priority_2_status = SEALED olmalıdır.
- priority_3_status = SEALED olmalıdır.
- priority_4_status = SEALED olmalıdır.
- live_html_publish_status = PASS olmalıdır.
- live_html_ready = YES olmalıdır.
- required_live_html_count >= 5 olmalıdır.
- closed_policy_reference = CLOSED_POLICY_GATE_REFERENCE_ONLY olmalıdır.
- production_launch_status = CLOSED olmalıdır.
- live_external_provider_status = CLOSED olmalıdır.
- gib_live_status = CLOSED olmalıdır.
- bank_live_status = CLOSED olmalıdır.
- pos_live_status = CLOSED olmalıdır.
- payment_live_status = CLOSED olmalıdır.

## Final Sonuç

Bu adım PASS olursa:

- FAZ_4_R_GENERAL_FINAL_REVIEW_STATUS=PASS
- FAZ_4_R_FINAL_CLOSURE_STATUS=SEALED
- FAZ_4_R_PARTIAL_REMAINING=NO
- FAZ_4_R_PENDING_REMAINING=NO
- FAZ_4_R_FAIL_REMAINING=NO
- FAZ_4_R_READY_FOR_NEXT_PHASE=YES
