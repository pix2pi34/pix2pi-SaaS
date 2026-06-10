# FAZ 6-R / 313 — FAZ 6-22.5 Permission Regression Seti

## Amaç

Pix2pi WEB-L9 final release polish bloğunda permission regression set standardını kurar.

Bu adım canlı role/permission mutation, JWT claim mutation, route guard mutation, API policy mutation, frontend deploy, build publish veya provider mutation yapmaz. Sadece permission regression matrisi, role-route kontrolü, tenant isolation guard, UI/API alignment, negative permission case seti, dry-run permission snapshot ve evidence üretir.

## Bağımlılık

- FAZ 6-22.1 Responsive finalizasyon

## Required Controls

- responsive_dependency_gate
- permission_surface_inventory
- role_route_matrix_policy
- tenant_permission_isolation_policy
- super_admin_boundary_policy
- jwt_claim_permission_guard
- api_ui_permission_alignment_guard
- hidden_button_not_security_policy
- negative_permission_test_policy
- export_report_permission_policy
- approval_workflow_permission_policy
- accountant_portal_permission_policy
- dry_run_permission_regression_runtime
- production_mutation_closed_policy
- manual_approval_policy
- evidence_capture_policy
- final_status_policy

## Permission Regression İlkeleri

1. Canlı role/permission değişikliği bu adımda yapılmaz.
2. UI buton gizleme güvenlik sayılmaz; API guard zorunludur.
3. Tenant izolasyonu her permission testinde korunur.
4. JWT claim ve backend permission policy uyumu kontrol edilir.
5. Super-admin yetki sınırı explicit olarak test edilir.
6. Export/report/approval/accountant portal ayrı regression yüzeyidir.
7. Negative permission case olmadan PASS verilmez.
8. Manual approval olmadan permission/policy/build mutation yapılmaz.
9. Evidence olmadan release checklist UI adımına geçilmez.

## Final Gate

- DOC_STATUS=READY
- CONFIG_STATUS=READY
- SET_STATUS=READY
- FIXTURE_STATUS=READY
- RUNTIME_STATUS=READY
- REAL_IMPLEMENTATION_STATUS=PASS
- FINAL_STATUS=PASS

