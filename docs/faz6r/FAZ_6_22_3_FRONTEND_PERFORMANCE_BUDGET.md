# FAZ 6-R / 309 — FAZ 6-22.3 Frontend Performance Budget

## Amaç

Pix2pi WEB-L9 final release polish bloğunda frontend performance budget standardını kurar.

Bu adım canlı frontend deploy, build publish, bundle mutation, route mutation, CDN invalidation, image pipeline mutation, compression mutation veya provider mutation yapmaz. Sadece performance budget hedefleri, Core Web Vitals, JS/CSS/image budget, route-level budget, public landing / panel / workflow UI ayrımı, dry-run performance snapshot ve evidence üretir.

## Bağımlılık

- FAZ 6-22.2 Accessibility finalizasyon

## Required Controls

- accessibility_dependency_gate
- core_web_vitals_budget_policy
- route_level_budget_policy
- js_bundle_budget_policy
- css_budget_policy
- image_asset_budget_policy
- font_budget_policy
- third_party_script_budget_policy
- cache_budget_policy
- public_landing_budget_policy
- panel_runtime_budget_policy
- workflow_ui_budget_policy
- dry_run_performance_budget_runtime
- production_mutation_closed_policy
- manual_approval_policy
- evidence_capture_policy
- final_status_policy

## Performance Budget İlkeleri

1. Canlı frontend deploy bu adımda yapılmaz.
2. Build publish ve CDN invalidation kapalıdır.
3. Core Web Vitals hedefleri route bazlı tanımlanır.
4. Public landing, panel shell, approval inbox, workflow monitor ve reporting UI ayrı budget ile izlenir.
5. JS/CSS/image/font budget aşımı release blocker adayıdır.
6. Accessibility finalizasyon ile çelişen performans optimizasyonu uygulanamaz.
7. Third-party script budget kontrol edilmeden public release yapılmaz.
8. Manual approval olmadan bundle/build/CDN mutation yapılmaz.
9. Evidence olmadan visual regression seti adımına geçilmez.

## Final Gate

- DOC_STATUS=READY
- CONFIG_STATUS=READY
- BUDGET_STATUS=READY
- FIXTURE_STATUS=READY
- RUNTIME_STATUS=READY
- REAL_IMPLEMENTATION_STATUS=PASS
- FINAL_STATUS=PASS

