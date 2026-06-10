# FAZ 6-R / 310 — FAZ 6-22.4 Visual Regression Seti

## Amaç

Pix2pi WEB-L9 final release polish bloğunda visual regression set standardını kurar.

Bu adım canlı screenshot baseline update, snapshot update, frontend deploy, build publish, route mutation, CDN invalidation veya provider mutation yapmaz. Sadece kritik route/component görsel test matrisi, viewport/theme/state kapsamı, visual diff threshold, accessibility/performance guard uyumu, dry-run visual regression snapshot ve evidence üretir.

## Bağımlılık

- FAZ 6-22.3 Frontend performance budget

## Required Controls

- frontend_performance_budget_dependency_gate
- baseline_inventory_policy
- viewport_matrix_policy
- theme_matrix_policy
- critical_route_screenshot_policy
- component_state_snapshot_policy
- visual_diff_threshold_policy
- accessibility_performance_alignment_guard
- deterministic_fixture_policy
- pii_secret_masking_policy
- screenshot_storage_policy
- approval_gate_policy
- dry_run_visual_regression_runtime
- production_mutation_closed_policy
- manual_approval_policy
- evidence_capture_policy
- final_status_policy

## Visual Regression İlkeleri

1. Baseline update bu adımda yapılmaz.
2. Snapshot update ve visual approval mutation kapalıdır.
3. Kritik route’lar viewport ve tema matrisiyle kontrol edilir.
4. Auth, panel shell, approval inbox, workflow monitor, reporting tables ve public landing kapsanır.
5. PII/secret mask uygulanmadan screenshot evidence üretilemez.
6. Accessibility ve performance budget ile çelişen visual fix uygulanamaz.
7. Visual diff threshold aşımı release blocker adayıdır.
8. Manual approval olmadan screenshot baseline veya build mutation yapılmaz.
9. Evidence olmadan final web closure adımına geçilmez.

## Final Gate

- DOC_STATUS=READY
- CONFIG_STATUS=READY
- SET_STATUS=READY
- FIXTURE_STATUS=READY
- RUNTIME_STATUS=READY
- REAL_IMPLEMENTATION_STATUS=PASS
- FINAL_STATUS=PASS

