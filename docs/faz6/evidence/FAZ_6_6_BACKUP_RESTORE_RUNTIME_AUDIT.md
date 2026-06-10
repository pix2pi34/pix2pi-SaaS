# FAZ 6-6 Backup / Restore Runtime Audit Evidence

Generated At: 2026-05-01T14:45:39+03:00  
Host: vm12827.ovadns.com  
Repo: /root/pix2pi/pix2pi-SaaS  

Bu audit runtime ortaminda backup / restore / disaster recovery izlerini toplar. Destructive restore yapmaz.

FAZ_6_6_RUNTIME_AUDIT=STARTED ✅

---


## 6-6.1 Host / Kernel

```text
Linux vm12827.ovadns.com 5.15.0-176-generic #186-Ubuntu SMP Fri Mar 13 11:01:42 UTC 2026 x86_64 x86_64 x86_64 GNU/Linux
```

## 6-6.2 Disk Usage

```text
Filesystem                         Size  Used Avail Use% Mounted on
tmpfs                              1.6G  2.6M  1.6G   1% /run
/dev/mapper/ubuntu--vg-ubuntu--lv  194G   84G  103G  45% /
tmpfs                              7.9G     0  7.9G   0% /dev/shm
tmpfs                              5.0M     0  5.0M   0% /run/lock
/dev/sda2                          2.0G  260M  1.6G  15% /boot
/dev/sda1                          1.1G  6.1M  1.1G   1% /boot/efi
overlay                            194G   84G  103G  45% /var/lib/docker/overlay2/a8c3a18b0bd7e3de5d16d40100386d3ea08be31a9810e6f7c0888575e194319a/merged
overlay                            194G   84G  103G  45% /var/lib/docker/overlay2/d2932c2de6ce9849cf1091484ac56e35a51cc13c76e2ecfc9f0337e1a48f8bdd/merged
overlay                            194G   84G  103G  45% /var/lib/docker/overlay2/8e08d680875fd05f703a251bf86f471dff08b636dcf1c9f11386c42bd2c24c2a/merged
overlay                            194G   84G  103G  45% /var/lib/docker/overlay2/c432d53e3d3897c3ba88018f53ad40d87dd7841841c7bbf3eda5fd79be51e312/merged
overlay                            194G   84G  103G  45% /var/lib/docker/overlay2/5c7f998b4dfbd13c2a7746b255680a765350c04797323ec2f012f335d88f2a10/merged
overlay                            194G   84G  103G  45% /var/lib/docker/overlay2/8db4dd7c772b223317245d437f04d93b54e7dff83a28924b026aa4627dbf09c3/merged
overlay                            194G   84G  103G  45% /var/lib/docker/overlay2/0713c8fded3b70688d57dcd396c223c0547a1f773f4847a502a4d6b7246c5a62/merged
overlay                            194G   84G  103G  45% /var/lib/docker/overlay2/a8acca0ccd95879440af9d725b532fbb26c051fce5a1700f2481cc9ad33c4e15/merged
overlay                            194G   84G  103G  45% /var/lib/docker/overlay2/ad8c87cdb8b4f80befbcc3dd291ca4d726c951396bcdc55ff9b5cb279f918fc1/merged
overlay                            194G   84G  103G  45% /var/lib/docker/overlay2/03df9e174d4b9325cf011fbb9cc235042c975aa75040a3b00c4a88b6270db15d/merged
overlay                            194G   84G  103G  45% /var/lib/docker/overlay2/ec0df24be1f5a11d4a24faf42aa85bdcf0b6808a1e34a6f6dc73fb82a7fd426d/merged
overlay                            194G   84G  103G  45% /var/lib/docker/overlay2/df7635e5431a5d93c6dc51e99f5faac9068e89525f34d11b88abd011bee20604/merged
overlay                            194G   84G  103G  45% /var/lib/docker/overlay2/cbb651d2b94ebdbd40d0804976c0fe595932a653b969cf4bad29ca1bbb9a079c/merged
overlay                            194G   84G  103G  45% /var/lib/docker/overlay2/9f2858e2f2174c8b3375b3fca4a15fe528511e09b5fa301b98c83dc6d10ec113/merged
overlay                            194G   84G  103G  45% /var/lib/docker/overlay2/5ad97030659f8f15bcba1b3f2ab1258e09f777dfa94adcc129003791dd8b588a/merged
tmpfs                              1.6G  4.0K  1.6G   1% /run/user/0
```

## 6-6.3 Backup Directory Inventory

```text
===== ./backups =====
306M	./backups
./backups/faz4b_18_5R_stock_reservation_lifecycle_status_fix_20260428_083124/scripts/test_phase4b_stock_reservation.sh
./backups/faz4b_18_7R_stock_valuation_cost_scope_fix_20260428_084032/scripts/phase4b_stock_valuation.py
./backups/faz4b_18_7R_stock_valuation_cost_scope_fix_20260428_084032/scripts/phase4b_stock_valuation.sh
./backups/faz4b_18_7R_stock_valuation_cost_scope_fix_20260428_084032/scripts/test_phase4b_stock_valuation.sh
./backups/faz4b_19_1R_runtime_flow_history_unique_fix_20260428_234201/scripts/phase4b_runtime_flow_history.py
./backups/faz4b_19_1R_runtime_flow_history_unique_fix_20260428_234201/scripts/phase4b_runtime_flow_history.sh
./backups/faz4b_19_1R_runtime_flow_history_unique_fix_20260428_234201/scripts/test_phase4b_runtime_flow_history.sh
./backups/faz4b_19_4R_import_wizard_tenant_ref_fix_20260428_235215/scripts/phase4b_import_wizard_ui.py
./backups/faz4b_19_4R_import_wizard_tenant_ref_fix_20260428_235215/scripts/phase4b_import_wizard_ui.sh
./backups/faz4b_19_4R_import_wizard_tenant_ref_fix_20260428_235215/scripts/test_phase4b_import_wizard_ui.sh
./backups/faz4b_21_1_role_matrix_20260429_073345/scripts/phase4b_role_matrix.py
./backups/faz4b_21_1_role_matrix_20260429_073345/scripts/phase4b_role_matrix.sh
./backups/faz4b_21_1_role_matrix_20260429_073345/scripts/test_phase4b_role_matrix.sh
./backups/faz4b_21_1R_role_matrix_boundary_permission_fix_20260429_073537/scripts/phase4b_role_matrix.py
./backups/faz4b_21_1R_role_matrix_boundary_permission_fix_20260429_073537/scripts/phase4b_role_matrix.sh
./backups/faz4b_21_1R_role_matrix_boundary_permission_fix_20260429_073537/scripts/test_phase4b_role_matrix.sh
./backups/faz4b_21_2R_permission_guard_surface_fix_20260429_074545/scripts/phase4b_permission_guard.py
./backups/faz4b_21_2R_permission_guard_surface_fix_20260429_074545/scripts/phase4b_permission_guard.sh
./backups/faz4b_21_2R_permission_guard_surface_fix_20260429_074545/scripts/test_phase4b_permission_guard.sh
./backups/faz4b_21_3R_audit_event_counter_fix_20260429_075114/scripts/phase4b_audit_event_model.py
./backups/faz4b_21_3R_audit_event_counter_fix_20260429_075114/scripts/phase4b_audit_event_model.sh
./backups/faz4b_21_3R_audit_event_counter_fix_20260429_075114/scripts/test_phase4b_audit_event_model.sh
./backups/faz4b_21_5R_support_super_admin_boundary_ref_fix_20260429_080357/scripts/phase4b_support_super_admin_boundary.py
./backups/faz4b_21_5R_support_super_admin_boundary_ref_fix_20260429_080357/scripts/phase4b_support_super_admin_boundary.sh
./backups/faz4b_21_5R_support_super_admin_boundary_ref_fix_20260429_080357/scripts/test_phase4b_support_super_admin_boundary.sh
./backups/faz4b_22_8_observability_ops_console_final_closure_20260429_192428/scripts/phase4b_observability_ops_console_final_closure.py
./backups/faz4b_22_8_observability_ops_console_final_closure_20260429_192428/scripts/phase4b_observability_ops_console_final_closure.sh
./backups/faz4b_22_8_observability_ops_console_final_closure_20260429_192428/scripts/test_phase4b_observability_ops_console_final_closure.sh
./backups/faz5/20260501_111842_faz5_master_plan/faz5_master_plan.md
./backups/faz5/20260501_111842_faz5_master_plan/test_faz5_master_plan.sh
./backups/faz5/20260501_111905_faz5_master_plan/faz5_master_plan.md
./backups/faz5/20260501_111905_faz5_master_plan/test_faz5_master_plan.sh
./backups/faz5/20260501_112407_fix_5_2_test_script/test_5_2_packages_pricing_architecture.sh
./backups/fix_faz4b_16_1_uat_inventory_movement_20260430_061545/scripts/phase4b_pilot_uat_onboarding_baseline.py
./backups/fix_faz4b_16_1_uat_inventory_movement_20260430_061545/scripts/test_phase4b_pilot_uat_onboarding_baseline.sh
./backups/fix_faz4b_22_8_final_validator_20260429_192914/scripts/phase4b_observability_ops_console_final_closure.py
./backups/fix_faz4b_22_8_final_validator_20260429_192914/scripts/phase4b_observability_ops_console_final_closure.sh
./backups/fix_faz4b_22_8_final_validator_20260429_192914/scripts/test_phase4b_observability_ops_console_final_closure.sh
./backups/gateway_jwt_default_fix/20260418_091157/gateway_config.go
./backups/gw_ingress_scan/20260417_201007/nginx.conf
===== /root/pix2pi-restic-repo =====
727M	/root/pix2pi-restic-repo
/root/pix2pi-restic-repo/data/e5/e523eca3ac0afd408168dcda5af0009f4b297babd42bb2cc5211aa5fbcdd9714
/root/pix2pi-restic-repo/data/e5/e5cacb3e1f38030d21203ee62a9487d856388bd3a98365056b64cde1208f97ac
/root/pix2pi-restic-repo/data/e6/e68b5832ad9e498e5dcf99914cfa6b66081e4d083b8a6ed292cf68d5767532ce
/root/pix2pi-restic-repo/data/e6/e6943a94fbb3a0980d46769b4d6f57881916c3926ad413ab4e9c49f523cb059e
/root/pix2pi-restic-repo/data/e8/e86cb144b2e391697c5ddc18cf56b6b228fbf8b4868ff6146bf8cce961d7ad0c
/root/pix2pi-restic-repo/data/e8/e87c8567f66ad0feb1a1add594249db82c06d329289856c71a0f2848f9aad13f
/root/pix2pi-restic-repo/data/ea/ea27c572a628a62bcbb46fda842f53fbd06a0aab3339fc93aec463dbe03ff03f
/root/pix2pi-restic-repo/data/eb/eb357b0cc87b9f31fa3aff43ce93171a07a966793083f54d47ad105e78cb22eb
/root/pix2pi-restic-repo/data/ec/ecfcfcbf4d1dcebab3e03b5577ec0f5dbbb459459c8f5b9567bbd9d15e0bd15a
/root/pix2pi-restic-repo/data/ef/effaba7846377fcee2a91cf54d6563d62411fb797e3d25e5656b4f96501fa324
/root/pix2pi-restic-repo/data/f0/f0714c112f85ba54b76237399328ccc1664b8008f823dd95b40099ebb630bcca
/root/pix2pi-restic-repo/data/f0/f08a245dcc41e3c5cefbb1121f971ee76e1d6a53f915da74ea167e80d1759f25
/root/pix2pi-restic-repo/data/f1/f1bd6bb9e11bbd5265a373bb9129751a4d478686a8388b4714f8f5d6337991ce
/root/pix2pi-restic-repo/data/f1/f1fc38e798808a530396b4a49240e9b2cf1963b0fc9ac5d810cd7fb6d24da6ce
/root/pix2pi-restic-repo/data/f2/f2004f5cb1fa967208f19f5861a9d9bce110bac3ffd2df587a0392fdb4b75f9e
/root/pix2pi-restic-repo/data/f2/f23e21d341cbb3319fd232b93ee02d7a6c7c3d60d19754adda15e063e8385923
/root/pix2pi-restic-repo/data/f4/f4902adf4a7dbcbb5a46941c62756d09d83c88a78cbf0b0b4c7579b8a8fbb56b
/root/pix2pi-restic-repo/data/f5/f5a7f96d1f90a93019d96db1a3a3a322ac26b9187dbad097d5108e06bc675990
/root/pix2pi-restic-repo/data/f5/f5f5f849dd1b809a13d9666de946aed3e33b1152fff5374e92bfc8e17df1d37f
/root/pix2pi-restic-repo/data/f7/f71192e2ec4d196384b6866c60161942d7ef617583e917cb849b1acb8ecae9b8
/root/pix2pi-restic-repo/data/f8/f8f47344ce1b9cfa77d93f28bf1bf3078600b635677214ebeb65318f56a624dd
/root/pix2pi-restic-repo/data/f9/f93961aaf193582e4f11d29d81e3983140583f4fecfa5b56c144daa3ef590215
/root/pix2pi-restic-repo/data/f9/f97018a6a67eff9f4438c116b50d873528e001808b3bf201467d9f083bc2db20
/root/pix2pi-restic-repo/data/fa/fa677cf411c2aa4e2f187104c5f58fb716bd426a0d3b6cc46ace5e118ed9fe7b
/root/pix2pi-restic-repo/data/fb/fb65878399171b8e60c0c4d4f081a1e9c245eff173b18ae66a33f36fbdbc40a5
/root/pix2pi-restic-repo/data/fb/fbd1714bab6522380c872c181c7c9295ee20c4b37ea6184e2bf4fbe4c2a16dc0
/root/pix2pi-restic-repo/data/fd/fdfdf63750adad2f6d553290648afda797772709cbcd633249bfcdfb0d73ce85
/root/pix2pi-restic-repo/data/ff/ffcc93b2f750787324c0c4078dfb7519bcc498667aa5e969529de2e4e591deab
/root/pix2pi-restic-repo/index/74432d08d5623b4d26f0d7e12bafd7e8874a2f83447c5bfb5762a439f166cdfa
/root/pix2pi-restic-repo/keys/20361193492360369278ab8bbef52307476664becfaeabfff4a5abd119e33d24
/root/pix2pi-restic-repo/snapshots/057a5575f0ebcdaaeb7445e6edb4742eed18682e5047df821c820ce87e715639
/root/pix2pi-restic-repo/snapshots/0d571bae18b5606209d950c24d1ae2e2805630e3e702ad3977b45b18d7ad97b2
/root/pix2pi-restic-repo/snapshots/20489c0c675c54b1d8e232642ea17c912124057c6dc6df67a127f5d33d2debb7
/root/pix2pi-restic-repo/snapshots/5e13cb494ba19048d77ccc65bcdf4d422669c7dd987b7310514b013b0c24603e
/root/pix2pi-restic-repo/snapshots/6e134354c80cfe5777b747938afee78a7645ec5578b4e64e2a52dc03403aea4a
/root/pix2pi-restic-repo/snapshots/80db667ea6ecb456280af00a183b5753d321037814b5bd4be12052ffaff10915
/root/pix2pi-restic-repo/snapshots/8a995d8dc3b5316ef10a690048d5a8541221f4e32cdd5450d0911184595f334c
/root/pix2pi-restic-repo/snapshots/e29238955903ddfbc8bd5bfb785de91d1094d5a6ce680e537ee272e577e9e87e
/root/pix2pi-restic-repo/snapshots/ec99b1cdb73e7a3040a050658a5700aa172c50ea42a44a7dd050afea23308a20
/root/pix2pi-restic-repo/snapshots/fcc8cc40e24f22a01784ba9f0fec117baca91710015522d2fb37209761b0f79a
===== /root/pix2pi/pix2pi-SaaS/backups =====
306M	/root/pix2pi/pix2pi-SaaS/backups
/root/pix2pi/pix2pi-SaaS/backups/faz4b_18_5R_stock_reservation_lifecycle_status_fix_20260428_083124/scripts/test_phase4b_stock_reservation.sh
/root/pix2pi/pix2pi-SaaS/backups/faz4b_18_7R_stock_valuation_cost_scope_fix_20260428_084032/scripts/phase4b_stock_valuation.py
/root/pix2pi/pix2pi-SaaS/backups/faz4b_18_7R_stock_valuation_cost_scope_fix_20260428_084032/scripts/phase4b_stock_valuation.sh
/root/pix2pi/pix2pi-SaaS/backups/faz4b_18_7R_stock_valuation_cost_scope_fix_20260428_084032/scripts/test_phase4b_stock_valuation.sh
/root/pix2pi/pix2pi-SaaS/backups/faz4b_19_1R_runtime_flow_history_unique_fix_20260428_234201/scripts/phase4b_runtime_flow_history.py
/root/pix2pi/pix2pi-SaaS/backups/faz4b_19_1R_runtime_flow_history_unique_fix_20260428_234201/scripts/phase4b_runtime_flow_history.sh
/root/pix2pi/pix2pi-SaaS/backups/faz4b_19_1R_runtime_flow_history_unique_fix_20260428_234201/scripts/test_phase4b_runtime_flow_history.sh
/root/pix2pi/pix2pi-SaaS/backups/faz4b_19_4R_import_wizard_tenant_ref_fix_20260428_235215/scripts/phase4b_import_wizard_ui.py
/root/pix2pi/pix2pi-SaaS/backups/faz4b_19_4R_import_wizard_tenant_ref_fix_20260428_235215/scripts/phase4b_import_wizard_ui.sh
/root/pix2pi/pix2pi-SaaS/backups/faz4b_19_4R_import_wizard_tenant_ref_fix_20260428_235215/scripts/test_phase4b_import_wizard_ui.sh
/root/pix2pi/pix2pi-SaaS/backups/faz4b_21_1_role_matrix_20260429_073345/scripts/phase4b_role_matrix.py
/root/pix2pi/pix2pi-SaaS/backups/faz4b_21_1_role_matrix_20260429_073345/scripts/phase4b_role_matrix.sh
/root/pix2pi/pix2pi-SaaS/backups/faz4b_21_1_role_matrix_20260429_073345/scripts/test_phase4b_role_matrix.sh
/root/pix2pi/pix2pi-SaaS/backups/faz4b_21_1R_role_matrix_boundary_permission_fix_20260429_073537/scripts/phase4b_role_matrix.py
/root/pix2pi/pix2pi-SaaS/backups/faz4b_21_1R_role_matrix_boundary_permission_fix_20260429_073537/scripts/phase4b_role_matrix.sh
/root/pix2pi/pix2pi-SaaS/backups/faz4b_21_1R_role_matrix_boundary_permission_fix_20260429_073537/scripts/test_phase4b_role_matrix.sh
/root/pix2pi/pix2pi-SaaS/backups/faz4b_21_2R_permission_guard_surface_fix_20260429_074545/scripts/phase4b_permission_guard.py
/root/pix2pi/pix2pi-SaaS/backups/faz4b_21_2R_permission_guard_surface_fix_20260429_074545/scripts/phase4b_permission_guard.sh
/root/pix2pi/pix2pi-SaaS/backups/faz4b_21_2R_permission_guard_surface_fix_20260429_074545/scripts/test_phase4b_permission_guard.sh
/root/pix2pi/pix2pi-SaaS/backups/faz4b_21_3R_audit_event_counter_fix_20260429_075114/scripts/phase4b_audit_event_model.py
/root/pix2pi/pix2pi-SaaS/backups/faz4b_21_3R_audit_event_counter_fix_20260429_075114/scripts/phase4b_audit_event_model.sh
/root/pix2pi/pix2pi-SaaS/backups/faz4b_21_3R_audit_event_counter_fix_20260429_075114/scripts/test_phase4b_audit_event_model.sh
/root/pix2pi/pix2pi-SaaS/backups/faz4b_21_5R_support_super_admin_boundary_ref_fix_20260429_080357/scripts/phase4b_support_super_admin_boundary.py
/root/pix2pi/pix2pi-SaaS/backups/faz4b_21_5R_support_super_admin_boundary_ref_fix_20260429_080357/scripts/phase4b_support_super_admin_boundary.sh
/root/pix2pi/pix2pi-SaaS/backups/faz4b_21_5R_support_super_admin_boundary_ref_fix_20260429_080357/scripts/test_phase4b_support_super_admin_boundary.sh
/root/pix2pi/pix2pi-SaaS/backups/faz4b_22_8_observability_ops_console_final_closure_20260429_192428/scripts/phase4b_observability_ops_console_final_closure.py
/root/pix2pi/pix2pi-SaaS/backups/faz4b_22_8_observability_ops_console_final_closure_20260429_192428/scripts/phase4b_observability_ops_console_final_closure.sh
/root/pix2pi/pix2pi-SaaS/backups/faz4b_22_8_observability_ops_console_final_closure_20260429_192428/scripts/test_phase4b_observability_ops_console_final_closure.sh
/root/pix2pi/pix2pi-SaaS/backups/faz5/20260501_111842_faz5_master_plan/faz5_master_plan.md
/root/pix2pi/pix2pi-SaaS/backups/faz5/20260501_111842_faz5_master_plan/test_faz5_master_plan.sh
/root/pix2pi/pix2pi-SaaS/backups/faz5/20260501_111905_faz5_master_plan/faz5_master_plan.md
/root/pix2pi/pix2pi-SaaS/backups/faz5/20260501_111905_faz5_master_plan/test_faz5_master_plan.sh
/root/pix2pi/pix2pi-SaaS/backups/faz5/20260501_112407_fix_5_2_test_script/test_5_2_packages_pricing_architecture.sh
/root/pix2pi/pix2pi-SaaS/backups/fix_faz4b_16_1_uat_inventory_movement_20260430_061545/scripts/phase4b_pilot_uat_onboarding_baseline.py
/root/pix2pi/pix2pi-SaaS/backups/fix_faz4b_16_1_uat_inventory_movement_20260430_061545/scripts/test_phase4b_pilot_uat_onboarding_baseline.sh
/root/pix2pi/pix2pi-SaaS/backups/fix_faz4b_22_8_final_validator_20260429_192914/scripts/phase4b_observability_ops_console_final_closure.py
/root/pix2pi/pix2pi-SaaS/backups/fix_faz4b_22_8_final_validator_20260429_192914/scripts/phase4b_observability_ops_console_final_closure.sh
/root/pix2pi/pix2pi-SaaS/backups/fix_faz4b_22_8_final_validator_20260429_192914/scripts/test_phase4b_observability_ops_console_final_closure.sh
/root/pix2pi/pix2pi-SaaS/backups/gateway_jwt_default_fix/20260418_091157/gateway_config.go
/root/pix2pi/pix2pi-SaaS/backups/gw_ingress_scan/20260417_201007/nginx.conf
===== /var/backups =====
2.5M	/var/backups
/var/backups/alternatives.tar.2.gz
/var/backups/alternatives.tar.3.gz
/var/backups/alternatives.tar.4.gz
/var/backups/alternatives.tar.5.gz
/var/backups/alternatives.tar.6.gz
/var/backups/apt.extended_states.0
/var/backups/apt.extended_states.1.gz
/var/backups/apt.extended_states.2.gz
/var/backups/apt.extended_states.3.gz
/var/backups/apt.extended_states.4.gz
/var/backups/apt.extended_states.5.gz
/var/backups/apt.extended_states.6.gz
/var/backups/dpkg.arch.0
/var/backups/dpkg.arch.1.gz
/var/backups/dpkg.arch.2.gz
/var/backups/dpkg.arch.3.gz
/var/backups/dpkg.arch.4.gz
/var/backups/dpkg.arch.5.gz
/var/backups/dpkg.arch.6.gz
/var/backups/dpkg.diversions.0
/var/backups/dpkg.diversions.1.gz
/var/backups/dpkg.diversions.2.gz
/var/backups/dpkg.diversions.3.gz
/var/backups/dpkg.diversions.4.gz
/var/backups/dpkg.diversions.5.gz
/var/backups/dpkg.diversions.6.gz
/var/backups/dpkg.statoverride.0
/var/backups/dpkg.statoverride.1.gz
/var/backups/dpkg.statoverride.2.gz
/var/backups/dpkg.statoverride.3.gz
/var/backups/dpkg.statoverride.4.gz
/var/backups/dpkg.statoverride.5.gz
/var/backups/dpkg.statoverride.6.gz
/var/backups/dpkg.status.0
/var/backups/dpkg.status.1.gz
/var/backups/dpkg.status.2.gz
/var/backups/dpkg.status.3.gz
/var/backups/dpkg.status.4.gz
/var/backups/dpkg.status.5.gz
/var/backups/dpkg.status.6.gz
===== /var/log/pix2pi =====
1.5M	/var/log/pix2pi
/var/log/pix2pi/ops_notify.log-20260425.gz
/var/log/pix2pi/ops_notify.log-20260426.gz
/var/log/pix2pi/ops_notify.log-20260427.gz
/var/log/pix2pi/ops_notify.log-20260428.gz
/var/log/pix2pi/ops_notify.log-20260429.gz
/var/log/pix2pi/ops_notify.log-20260430.gz
/var/log/pix2pi/ops_notify.log-20260501
/var/log/pix2pi/ops_retention_cleanup.log
/var/log/pix2pi/ops_retention_probe.log
/var/log/pix2pi/ops_service_watch.log
/var/log/pix2pi/ops_service_watch.log-20260418.gz
/var/log/pix2pi/ops_service_watch.log-20260419.gz
/var/log/pix2pi/ops_service_watch.log-20260420.gz
/var/log/pix2pi/ops_service_watch.log-20260421.gz
/var/log/pix2pi/ops_service_watch.log-20260422.gz
/var/log/pix2pi/ops_service_watch.log-20260423.gz
/var/log/pix2pi/ops_service_watch.log-20260424.gz
/var/log/pix2pi/ops_service_watch.log-20260425.gz
/var/log/pix2pi/ops_service_watch.log-20260426.gz
/var/log/pix2pi/ops_service_watch.log-20260427.gz
/var/log/pix2pi/ops_service_watch.log-20260428.gz
/var/log/pix2pi/ops_service_watch.log-20260429.gz
/var/log/pix2pi/ops_service_watch.log-20260430.gz
/var/log/pix2pi/ops_service_watch.log-20260501
/var/log/pix2pi/panel-error.log
/var/log/pix2pi/panel.log
/var/log/pix2pi/plugin-runtime-error.log
/var/log/pix2pi/plugin-runtime.log
/var/log/pix2pi/publicapi-runtime-error.log
/var/log/pix2pi/publicapi-runtime.log
/var/log/pix2pi/realtime-runtime-error.log
/var/log/pix2pi/realtime-runtime.log
/var/log/pix2pi/runtime-topology-error.log
/var/log/pix2pi/runtime-topology.log
/var/log/pix2pi/service-registry-error.log
/var/log/pix2pi/service-registry.log
/var/log/pix2pi/webhook-runtime-error.log
/var/log/pix2pi/webhook-runtime.log
/var/log/pix2pi/workflow-runtime-error.log
/var/log/pix2pi/workflow-runtime.log
===== /var/log/pix2pi/archive =====
4.0K	/var/log/pix2pi/archive
```

## 6-6.4 Backup / Restore Scripts Inventory

```text
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf
./1_archive/root_sh/step_100_backup_run_api_gateway_script.sh
./1_archive/root_sh/step_102_backup_api_gateway_before_rewrite.sh
./1_archive/root_sh/step_105_backup_api_gateway_before_rate_limit.sh
./1_archive/root_sh/step_108_backup_api_gateway_before_tenant_middleware.sh
./1_archive/root_sh/step_111_backup_api_gateway_before_redis_rate_limit.sh
./1_archive/root_sh/step_116_backup_api_gateway_before_auth_route.sh
./1_archive/root_sh/step_11_backup_tenant_service_filter.sh
./1_archive/root_sh/step_126_backup_api_gateway_before_combined_gateway.sh
./1_archive/root_sh/step_130_backup_gateway_before_authz_layer.sh
./1_archive/root_sh/step_130_backup_nginx_before_rate_limit.sh
./1_archive/root_sh/step_136_backup_fail2ban_before_nginx_jail.sh
./1_archive/root_sh/step_13_backup_redis_tenant_namespace.sh
./1_archive/root_sh/step_16_backup_super_admin_policy.sh
./1_archive/root_sh/step_184_backup_panel_before_service_monitor.sh
./1_archive/root_sh/step_185_create_service_status_snapshot_script.sh
./1_archive/root_sh/step_19_backup_postgres_rls.sh
./1_archive/root_sh/step_1_backup_account_mapping.sh
./1_archive/root_sh/step_1_backup_accounts_import.sh
./1_archive/root_sh/step_1_backup_accounts_seed.sh
./1_archive/root_sh/step_1_backup_alis_faturasi_engine.sh
./1_archive/root_sh/step_1_backup_auto_rules.sh
./1_archive/root_sh/step_1_backup_balance_sheet.sh
./1_archive/root_sh/step_1_backup_banka_ekstre.sh
./1_archive/root_sh/step_1_backup_banka_engine.sh
./1_archive/root_sh/step_1_backup_bilanco_engine.sh
./1_archive/root_sh/step_1_backup_cari_ekstre.sh
./1_archive/root_sh/step_1_backup_cash_flow.sh
./1_archive/root_sh/step_1_backup_chart_intelligence.sh
./1_archive/root_sh/step_1_backup_commission_engine.sh
./1_archive/root_sh/step_1_backup_commission_rule_versioning.sh
./1_archive/root_sh/step_1_backup_current_account_engine.sh
./1_archive/root_sh/step_1_backup_financial_consistency.sh
./1_archive/root_sh/step_1_backup_financial_event_engine.sh
./1_archive/root_sh/step_1_backup_gelir_tablosu_engine.sh
./1_archive/root_sh/step_1_backup_general_ledger.sh
./1_archive/root_sh/step_1_backup_income_statement.sh
./1_archive/root_sh/step_1_backup_journal_builder.sh
./1_archive/root_sh/step_1_backup_journal_engine.sh
./1_archive/root_sh/step_1_backup_kasa_ekstre.sh
./1_archive/root_sh/step_1_backup_kasa_engine.sh
./1_archive/root_sh/step_1_backup_ledger_balance_engine.sh
./1_archive/root_sh/step_1_backup_ledger_engine.sh
./1_archive/root_sh/step_1_backup_ledger_posting_engine.sh
./1_archive/root_sh/step_1_backup_merchant_payout_engine.sh
./1_archive/root_sh/step_1_backup_mizan_engine.sh
./1_archive/root_sh/step_1_backup_multi_account_ledger.sh
./1_archive/root_sh/step_1_backup_payment_engine.sh
./1_archive/root_sh/step_1_backup_period_closing.sh
./1_archive/root_sh/step_1_backup_reconciliation_engine.sh
./1_archive/root_sh/step_1_backup_satis_fatura_engine.sh
./1_archive/root_sh/step_1_backup_settlement_engine.sh
./1_archive/root_sh/step_1_backup_tahsilat_odeme_engine.sh
./1_archive/root_sh/step_1_backup_tahsilat_odeme_v2.sh
./1_archive/root_sh/step_1_backup_tax_engine.sh
./1_archive/root_sh/step_1_backup_tenant_test.sh
./1_archive/root_sh/step_1_backup_trial_balance.sh
./1_archive/root_sh/step_1_backup_ufk_engine.sh
./1_archive/root_sh/step_1_backup_ufk_event_engine.sh
./1_archive/root_sh/step_1_backup_ufk_event_journal.sh
./1_archive/root_sh/step_1_backup_wallet_transfer_engine.sh
./1_archive/root_sh/step_205_fix_snapshot_process_bazli.sh
./1_archive/root_sh/step_230_snapshot_schema.sh
./1_archive/root_sh/step_231_snapshot_full.sh
./1_archive/root_sh/step_232_run_snapshot_flow.sh
./1_archive/root_sh/step_240_enable_rls_snapshots.sh
./1_archive/root_sh/step_241_test_rls_snapshots.sh
./1_archive/root_sh/step_246_grant_snapshot_sequence.sh
./1_archive/root_sh/step_277_fix_snapshot_frequency.sh
./1_archive/root_sh/step_279_find_snapshot_source.sh
./1_archive/root_sh/step_280_fix_snapshot_logging.sh
./1_archive/root_sh/step_281_logrotate_snapshot.sh
./1_archive/root_sh/step_283_disable_snapshot_logging.sh
./1_archive/root_sh/step_284_remove_snapshot_from_promtail.sh
./1_archive/root_sh/step_28_backup_audit_log_engine.sh
./1_archive/root_sh/step_298_cleanup_nginx_backup.sh
./1_archive/root_sh/step_319_backup_panel_before_rewrite.sh
./1_archive/root_sh/step_31_backup_export_isolation.sh
./1_archive/root_sh/step_324_backup_status_engine.sh
./1_archive/root_sh/step_327_backup_watchdog_before_fail_memory.sh
./1_archive/root_sh/step_34_backup_backup_isolation.sh
./1_archive/root_sh/step_355d_restore_clean.sh
./1_archive/root_sh/step_355e_find_last_buildable_watchdog_backup.sh
./1_archive/root_sh/step_35_prepare_backup_dirs.sh
./1_archive/root_sh/step_367_restore_clean_panel_engine.sh
./1_archive/root_sh/step_36_run_backup_isolation_test.sh
./1_archive/root_sh/step_37_backup_event_bus.sh
./1_archive/root_sh/step_3_backup_jwt_tenant.sh
./1_archive/root_sh/step_405_backup_kernel.sh
./1_archive/root_sh/step_40_backup_event_retry.sh
./1_archive/root_sh/step_417_backup_query_gateway.sh
./1_archive/root_sh/step_421_backup_kernel_safe.sh
./1_archive/root_sh/step_422_backup_gateway_db_init.sh
./1_archive/root_sh/step_42_backup_event_idempotency.sh
./1_archive/root_sh/step_44_backup_event_dlq.sh
./1_archive/root_sh/step_46_backup_event_store.sh
./1_archive/root_sh/step_49_backup_event_replay.sh
./1_archive/root_sh/step_51_backup_event_bus_store_integration.sh
./1_archive/root_sh/step_53_backup_journal_builder.sh
./1_archive/root_sh/step_56_backup_ledger_posting.sh
./1_archive/root_sh/step_58_backup_snapshot_engine.sh
./1_archive/root_sh/step_59_run_snapshot_engine_test.sh
./1_archive/root_sh/step_5_check_wallet_transfer_files.sh
./1_archive/root_sh/step_60_backup_real_redis_cache.sh
./1_archive/root_sh/step_63_backup_read_write_split.sh
./1_archive/root_sh/step_66_backup_reporting_store.sh
./1_archive/root_sh/step_69_backup_rate_limit.sh
./1_archive/root_sh/step_6_backup_jwt_middleware.sh
./1_archive/root_sh/step_6_run_wallet_transfer_engine.sh
./1_archive/root_sh/step_76_configure_production_firewall.sh
./1_archive/root_sh/step_84_backup_nginx_ssl_split.sh
./1_archive/root_sh/step_92_backup_nginx_before_redirect_fix.sh
./1_archive/root_sh/step_9_backup_tenant_event_pipeline.sh
./1_archive/root_sh/step_fix_1_backup_cari_service.sh
./1_archive/root_sh/step_fix_1_backup_cari_v2.sh
./1_archive/root_sh/step_fix_backup_banka_swift.sh
./1_archive/root_sh/step_fix_backup_cari_service_ekstre.sh
./1_archive/root_sh/step_fix_backup_kasa_parabirimi.sh
./1_archive/root_sh/step_fix_backup_satis_iskonto.sh
./1_archive/root_sql/step_230_create_snapshot_tables.sql
./1_archive/root_sql/step_240_enable_rls_snapshots.sql
./_backup_archive/005_phase2_mission_control.sql.bak_20260423_081245
./_backup_archive/005_phase2_mission_control.sql.bak_20260423_081410
./_backup_archive/005_phase2_mission_control.sql.bak_20260423_081608
./_backup_archive/009_phase2_webhooks.sql.bak_20260423_155635
./_backup_archive/4c_1_1b_2_marketplace_scope_guard_report.md.bak
./_backup_archive/4c_1_1c_real_pilot_business_info.md.bak
./_backup_archive/4c_1_1d_scope_freeze_final_decision.md.bak
./_backup_archive/4c_1_1e_real_business_confirmation.md.bak
./_backup_archive/4c_1_1e_real_business_confirmation_report.md.bak
./_backup_archive/4c_1_1_pilot_isletme_secimi.md.bak
./_backup_archive/4d_marketplace_integrations_phase_registry.md.bak
./_backup_archive/AppShell.tsx.bak_early_warning_20260424_233046
./_backup_archive/AppShell.tsx.bak_incident_audit_20260424_235550
./_backup_archive/AppShell.tsx.bak_jobs_queue_20260424_130156
./_backup_archive/AppShell.tsx.bak_mission_20260424_123649
./_backup_archive/AppShell.tsx.bak_notification_monitor_20260424_164932
./_backup_archive/AppShell.tsx.bak_plugin_monitor_20260424_145939
./_backup_archive/AppShell.tsx.bak_publicapi_monitor_20260424_151728
./_backup_archive/AppShell.tsx.bak_realtime_monitor_20260425_005438
./_backup_archive/AppShell.tsx.bak_runtime_topology_20260425_002216
./_backup_archive/AppShell.tsx.bak_webhook_monitor_20260424_135929
./_backup_archive/AppShell.tsx.bak_webhook_monitor_20260424_135950
./_backup_archive/AppShell.tsx.bak_workflow_monitor_20260424_142635
./_backup_archive/App.tsx.bak_early_warning_20260424_233046
./_backup_archive/App.tsx.bak_incident_audit_20260424_235550
./_backup_archive/App.tsx.bak_jobs_queue_20260424_130156
./_backup_archive/App.tsx.bak_mission_20260424_123649
./_backup_archive/App.tsx.bak_notification_monitor_20260424_164932
./_backup_archive/App.tsx.bak_plugin_monitor_20260424_145939
./_backup_archive/App.tsx.bak_publicapi_monitor_20260424_151728
./_backup_archive/App.tsx.bak_realtime_monitor_20260425_005438
./_backup_archive/App.tsx.bak_runtime_topology_20260425_002216
./_backup_archive/App.tsx.bak_webhook_monitor_20260424_135929
./_backup_archive/App.tsx.bak_webhook_monitor_20260424_135950
./_backup_archive/App.tsx.bak_workflow_monitor_20260424_142635
./_backup_archive/claim_store.go.bak_20260423_221143
./_backup_archive/claim_store_test.go.bak_20260423_221143
./_backup_archive/control_panel.go.bak_early_warning_runtime_proxy_20260424_232711
./_backup_archive/control_panel.go.bak_fix_20260424_120626
./_backup_archive/control_panel.go.bak_incident_audit_runtime_proxy_20260424_235140
./_backup_archive/control_panel.go.bak_jobs_runtime_proxy_20260424_125918
./_backup_archive/control_panel.go.bak_mission_proxy_20260424_123233
./_backup_archive/control_panel.go.bak_notification_runtime_proxy_20260424_164510
./_backup_archive/control_panel.go.bak_plugin_runtime_proxy_20260424_145657
./_backup_archive/control_panel.go.bak_publicapi_runtime_proxy_20260424_151410
./_backup_archive/control_panel.go.bak_realtime_runtime_proxy_20260425_005153
./_backup_archive/control_panel.go.bak_runtime_topology_proxy_20260425_001731
./_backup_archive/control_panel.go.bak_webhook_runtime_proxy_20260424_135702
./_backup_archive/control_panel.go.bak_workflow_runtime_proxy_20260424_142345
./_backup_archive/EarlyWarningPage.test.tsx.bak_database_multi_fix_20260424_233625
./_backup_archive/early_warning_runtime_main.go.bak_20260424_231928
./_backup_archive/early_warning_runtime_main_test.go.bak_20260424_231928
./_backup_archive/enqueue_store.go.bak_20260423_221143
./_backup_archive/IncidentAuditPage.test.tsx.bak_multi_match_fix_20260425_000033
./_backup_archive/IncidentAuditPage.test.tsx.bak_multi_match_fix_20260425_000101
./_backup_archive/IncidentAuditPage.test.tsx.bak_multi_match_fix_20260425_000113
./_backup_archive/IncidentAuditPage.test.tsx.bak_multi_match_fix_20260425_000131
./_backup_archive/incident_timeline_store.go.bak_20260423_212947
./_backup_archive/JobsQueuePage.test.tsx.bak_default_fix_20260424_130444
./_backup_archive/jobs_runtime_main.go.bak_20260424_125407
./_backup_archive/jobs_runtime_main_test.go.bak_20260424_125407
./_backup_archive/ops_console_smoke_main.go.bak_realtime_targets_20260425_012718
./_backup_archive/ops_console_smoke_main_test.go.bak_realtime_targets_20260425_012718
./_backup_archive/RealtimeMonitorPage.test.tsx.bak_multi_match_fix_20260425_010045
./_backup_archive/register_handler_test.go.bak_20260423_162528
./_backup_archive/register_service.go.bak_20260423_162022
./_backup_archive/register_service_test.go.bak_20260423_162022
./_backup_archive/runtime_integration_test.go.bak_20260423_213619
./_backup_archive/runtime_integration_test.go.bak_20260424_080635
./_backup_archive/runtime_integration_test.go.bak_20260424_093211
./_backup_archive/service-registry-api.ts.bak_auth_20260424_121253
./_backup_archive/ServiceRegistryPage.test.tsx.bak_20260424_114546
./_backup_archive/ServiceRegistryPage.test.tsx.bak_auth_20260424_121253
./_backup_archive/ServiceRegistryPage.test.tsx.bak_session_20260424_121356
./_backup_archive/ServiceRegistryPage.test.tsx.bak_tsfix_20260424_121654
./_backup_archive/ServiceRegistryPage.test.tsx.bak_vifn_20260424_121915
./_backup_archive/ServiceRegistryPage.tsx.bak_20260424_114546
./_backup_archive/ServiceRegistryPage.tsx.bak_auth_20260424_121253
./_backup_archive/status_panel_store.go.bak_20260423_212947
```

## 6-6.5 Cron Backup / Retention Inventory

```text
===== /etc/cron.d =====
/etc/cron.d/pix2pi_ops_health:4:*/10 * * * * root /root/pix2pi/pix2pi-SaaS/scripts/check_ops_service_failures.sh
/etc/cron.d/pix2pi_ops_health:5:40 6 * * * root /root/pix2pi/pix2pi-SaaS/scripts/run_ops_health_daily.sh
/etc/cron.d/pix2pi_ops_retention:4:25 3 * * * root /root/pix2pi/pix2pi-SaaS/scripts/run_ops_retention_daily.sh
/etc/cron.d/pix2pi_reporting_service:1:* * * * * root /usr/local/bin/pix2pi_reporting_service_ensure.sh >> /tmp/pix2pi_reporting_service_watchdog.log 2>&1
/etc/cron.d/pix2pi-ops-health:4:40 6 * * * root /root/pix2pi/pix2pi-SaaS/scripts/run_ops_health_daily.sh
/etc/cron.d/pix2pi_service_status:1:* * * * * root /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1
/etc/cron.d/pix2pi_service_status:2:* * * * * root sleep 10; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1
/etc/cron.d/pix2pi_service_status:3:* * * * * root sleep 20; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1
/etc/cron.d/pix2pi_service_status:4:* * * * * root sleep 30; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1
/etc/cron.d/pix2pi_service_status:5:* * * * * root sleep 40; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1
/etc/cron.d/pix2pi_service_status:6:* * * * * root sleep 50; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1
===== crontab root =====
# For example, you can run a backup of all your user accounts
# 0 5 * * 1 tar -zcf /var/backups/home.tgz /home/
30 3 * * * /root/pix2pi/pix2pi-SaaS/scripts/cleanup/bak_archive.sh >> /root/pix2pi/pix2pi-SaaS/var/logs/bak_cleanup.log 2>&1
0 */6 * * * /root/pix2pi/restic_backup.sh >> /root/pix2pi/restic_backup.log 2>&1
* * * * * /opt/pix2pi/bin/pix2pi_early_warning.sh >/dev/null 2>&1
* * * * * /opt/pix2pi/bin/pix2pi_auto_heal.sh >/dev/null 2>&1
* * * * * /opt/pix2pi/bin/pix2pi_scale_hook.sh >/dev/null 2>&1
===== systemd timers =====
Sat 2026-05-02 00:00:00 +03 9h left            Fri 2026-05-01 00:00:01 +03 14h ago      dpkg-db-backup.timer           dpkg-db-backup.service
```

## 6-6.6 Backup / Retention Logs

```text
===== /var/log/pix2pi/ops_retention_cleanup.log =====
OK ✅ aday yok
===== BACKUP SILINECEK ADAYLAR =====
OK ✅ aday yok
INFO ▶ backup_aday_sayisi=0
OK ✅ archive aday yok
OK ✅ backup aday yok
OK ✅ step_57z_retention_cleanup_gecti
===== pix2pi ops retention end 2026-04-27 03:25:01 rc=0 =====
===== pix2pi ops retention start 2026-04-28 03:25:01 =====
===== STEP 57Z / OPS RETENTION CLEANUP =====
INFO ▶ BACKUP_BASE=/root/pix2pi/pix2pi-SaaS/backups
INFO ▶ ARCHIVE_RETENTION_DAYS=14
INFO ▶ BACKUP_RETENTION_DAYS=30
INFO ▶ protected skip -> /root/pix2pi/pix2pi-SaaS/backups/api-gateway
INFO ▶ protected skip -> /root/pix2pi/pix2pi-SaaS/backups/app
INFO ▶ protected skip -> /root/pix2pi/pix2pi-SaaS/backups/nginx
INFO ▶ protected skip -> /root/pix2pi/pix2pi-SaaS/backups/panel
INFO ▶ protected skip -> /root/pix2pi/pix2pi-SaaS/backups/scripts
OK ✅ aday yok
===== BACKUP SILINECEK ADAYLAR =====
OK ✅ aday yok
INFO ▶ backup_aday_sayisi=0
OK ✅ archive aday yok
OK ✅ backup aday yok
OK ✅ step_57z_retention_cleanup_gecti
===== pix2pi ops retention end 2026-04-28 03:25:01 rc=0 =====
===== pix2pi ops retention start 2026-04-29 03:25:01 =====
===== STEP 57Z / OPS RETENTION CLEANUP =====
INFO ▶ BACKUP_BASE=/root/pix2pi/pix2pi-SaaS/backups
INFO ▶ ARCHIVE_RETENTION_DAYS=14
INFO ▶ BACKUP_RETENTION_DAYS=30
INFO ▶ protected skip -> /root/pix2pi/pix2pi-SaaS/backups/api-gateway
INFO ▶ protected skip -> /root/pix2pi/pix2pi-SaaS/backups/app
INFO ▶ protected skip -> /root/pix2pi/pix2pi-SaaS/backups/nginx
INFO ▶ protected skip -> /root/pix2pi/pix2pi-SaaS/backups/panel
INFO ▶ protected skip -> /root/pix2pi/pix2pi-SaaS/backups/scripts
OK ✅ aday yok
===== BACKUP SILINECEK ADAYLAR =====
OK ✅ aday yok
INFO ▶ backup_aday_sayisi=0
OK ✅ archive aday yok
OK ✅ backup aday yok
OK ✅ step_57z_retention_cleanup_gecti
===== pix2pi ops retention end 2026-04-29 03:25:01 rc=0 =====
===== pix2pi ops retention start 2026-04-30 03:25:01 =====
===== STEP 57Z / OPS RETENTION CLEANUP =====
INFO ▶ BACKUP_BASE=/root/pix2pi/pix2pi-SaaS/backups
INFO ▶ ARCHIVE_RETENTION_DAYS=14
INFO ▶ BACKUP_RETENTION_DAYS=30
INFO ▶ protected skip -> /root/pix2pi/pix2pi-SaaS/backups/api-gateway
INFO ▶ protected skip -> /root/pix2pi/pix2pi-SaaS/backups/app
INFO ▶ protected skip -> /root/pix2pi/pix2pi-SaaS/backups/nginx
INFO ▶ protected skip -> /root/pix2pi/pix2pi-SaaS/backups/panel
INFO ▶ protected skip -> /root/pix2pi/pix2pi-SaaS/backups/scripts
OK ✅ aday yok
===== BACKUP SILINECEK ADAYLAR =====
OK ✅ aday yok
INFO ▶ backup_aday_sayisi=0
OK ✅ archive aday yok
OK ✅ backup aday yok
OK ✅ step_57z_retention_cleanup_gecti
===== pix2pi ops retention end 2026-04-30 03:25:01 rc=0 =====
===== pix2pi ops retention start 2026-05-01 03:25:01 =====
===== STEP 57Z / OPS RETENTION CLEANUP =====
INFO ▶ BACKUP_BASE=/root/pix2pi/pix2pi-SaaS/backups
INFO ▶ ARCHIVE_RETENTION_DAYS=14
INFO ▶ BACKUP_RETENTION_DAYS=30
INFO ▶ protected skip -> /root/pix2pi/pix2pi-SaaS/backups/api-gateway
INFO ▶ protected skip -> /root/pix2pi/pix2pi-SaaS/backups/app
INFO ▶ protected skip -> /root/pix2pi/pix2pi-SaaS/backups/nginx
INFO ▶ protected skip -> /root/pix2pi/pix2pi-SaaS/backups/panel
INFO ▶ protected skip -> /root/pix2pi/pix2pi-SaaS/backups/scripts
===== BACKUP SILINECEK ADAYLAR =====
OK ✅ aday yok
INFO ▶ backup_aday_sayisi=0
OK ✅ silindi -> /var/log/pix2pi/archive/20260415_081200
OK ✅ silindi -> /var/log/pix2pi/archive/57x_force_20260415_083136
OK ✅ backup aday yok
OK ✅ step_57z_retention_cleanup_gecti
===== pix2pi ops retention end 2026-05-01 03:25:01 rc=0 =====
WARN ⚠️ missing log: /var/log/pix2pi/backup.log
WARN ⚠️ missing log: /var/log/pix2pi/restore.log
===== /var/log/syslog =====
May  1 14:34:01 vm12827 CRON[478550]: (root) CMD (sleep 50; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:34:01 vm12827 CRON[478559]: (root) CMD (/usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:35:01 vm12827 CRON[483943]: (root) CMD (sleep 20; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:35:01 vm12827 CRON[483945]: (root) CMD (sleep 10; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:35:01 vm12827 CRON[483941]: (root) CMD (sleep 50; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:35:01 vm12827 CRON[483944]: (root) CMD (sleep 30; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:35:01 vm12827 CRON[483953]: (root) CMD (/usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:35:01 vm12827 CRON[483946]: (root) CMD (/opt/pix2pi/bin/pix2pi_scale_hook.sh >/dev/null 2>&1)
May  1 14:35:01 vm12827 CRON[483942]: (root) CMD (sleep 40; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:36:01 vm12827 CRON[528345]: (root) CMD (sleep 40; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:36:01 vm12827 CRON[528344]: (root) CMD (/usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:36:01 vm12827 CRON[528346]: (root) CMD (sleep 20; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:36:01 vm12827 CRON[528349]: (root) CMD (sleep 10; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:36:01 vm12827 CRON[528342]: (root) CMD (sleep 30; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:36:01 vm12827 CRON[528358]: (root) CMD (sleep 50; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:36:01 vm12827 CRON[528356]: (root) CMD (/opt/pix2pi/bin/pix2pi_scale_hook.sh >/dev/null 2>&1)
May  1 14:37:01 vm12827 CRON[541729]: (root) CMD (sleep 10; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:37:01 vm12827 CRON[541730]: (root) CMD (sleep 40; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:37:01 vm12827 CRON[541731]: (root) CMD (sleep 50; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:37:01 vm12827 CRON[541733]: (root) CMD (/usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:37:01 vm12827 CRON[541742]: (root) CMD (sleep 30; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:37:01 vm12827 CRON[541739]: (root) CMD (/opt/pix2pi/bin/pix2pi_scale_hook.sh >/dev/null 2>&1)
May  1 14:37:01 vm12827 CRON[541743]: (root) CMD (sleep 20; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:38:01 vm12827 CRON[542296]: (root) CMD (sleep 10; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:38:01 vm12827 CRON[542297]: (root) CMD (sleep 40; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:38:01 vm12827 CRON[542298]: (root) CMD (sleep 20; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:38:01 vm12827 CRON[542299]: (root) CMD (sleep 50; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:38:01 vm12827 CRON[542309]: (root) CMD (sleep 30; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:38:01 vm12827 CRON[542315]: (root) CMD (/usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:38:01 vm12827 CRON[542316]: (root) CMD (/opt/pix2pi/bin/pix2pi_scale_hook.sh >/dev/null 2>&1)
May  1 14:39:01 vm12827 CRON[542836]: (root) CMD (/usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:39:01 vm12827 CRON[542838]: (root) CMD (sleep 30; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:39:01 vm12827 CRON[542840]: (root) CMD (sleep 20; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:39:01 vm12827 CRON[542841]: (root) CMD (sleep 10; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:39:01 vm12827 CRON[542842]: (root) CMD (sleep 40; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:39:01 vm12827 CRON[542837]: (root) CMD (sleep 50; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:39:01 vm12827 CRON[542859]: (root) CMD (/opt/pix2pi/bin/pix2pi_scale_hook.sh >/dev/null 2>&1)
May  1 14:40:01 vm12827 CRON[576124]: (root) CMD (sleep 50; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:40:01 vm12827 CRON[576125]: (root) CMD (sleep 40; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:40:01 vm12827 CRON[576126]: (root) CMD (sleep 20; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:40:01 vm12827 CRON[576123]: (root) CMD (/root/pix2pi/pix2pi-SaaS/scripts/check_ops_service_failures.sh)
May  1 14:40:01 vm12827 CRON[576138]: (root) CMD (/usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:40:01 vm12827 CRON[576141]: (root) CMD (sleep 30; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:40:01 vm12827 CRON[576139]: (root) CMD (sleep 10; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:40:01 vm12827 CRON[576143]: (root) CMD (/opt/pix2pi/bin/pix2pi_scale_hook.sh >/dev/null 2>&1)
May  1 14:41:01 vm12827 CRON[617479]: (root) CMD (sleep 50; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:41:01 vm12827 CRON[617483]: (root) CMD (sleep 10; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:41:01 vm12827 CRON[617478]: (root) CMD (sleep 40; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:41:01 vm12827 CRON[617486]: (root) CMD (/opt/pix2pi/bin/pix2pi_scale_hook.sh >/dev/null 2>&1)
May  1 14:41:01 vm12827 CRON[617488]: (root) CMD (sleep 20; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:41:01 vm12827 CRON[617480]: (root) CMD (sleep 30; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:41:01 vm12827 CRON[617498]: (root) CMD (/usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:42:01 vm12827 CRON[629166]: (root) CMD (sleep 30; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:42:01 vm12827 CRON[629168]: (root) CMD (sleep 40; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:42:01 vm12827 CRON[629169]: (root) CMD (/usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:42:01 vm12827 CRON[629170]: (root) CMD (sleep 20; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:42:01 vm12827 CRON[629171]: (root) CMD (sleep 10; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:42:01 vm12827 CRON[629172]: (root) CMD (sleep 50; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:42:01 vm12827 CRON[629184]: (root) CMD (/opt/pix2pi/bin/pix2pi_scale_hook.sh >/dev/null 2>&1)
May  1 14:43:01 vm12827 CRON[629737]: (root) CMD (sleep 20; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:43:01 vm12827 CRON[629738]: (root) CMD (sleep 10; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:43:01 vm12827 CRON[629739]: (root) CMD (/usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:43:01 vm12827 CRON[629740]: (root) CMD (sleep 50; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:43:01 vm12827 CRON[629741]: (root) CMD (sleep 30; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:43:01 vm12827 CRON[629754]: (root) CMD (sleep 40; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:43:01 vm12827 CRON[629755]: (root) CMD (/opt/pix2pi/bin/pix2pi_scale_hook.sh >/dev/null 2>&1)
May  1 14:44:01 vm12827 CRON[630277]: (root) CMD (sleep 20; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:44:01 vm12827 CRON[630280]: (root) CMD (sleep 40; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:44:01 vm12827 CRON[630281]: (root) CMD (sleep 30; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:44:01 vm12827 CRON[630279]: (root) CMD (/usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:44:01 vm12827 CRON[630276]: (root) CMD (sleep 10; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:44:01 vm12827 CRON[630292]: (root) CMD (sleep 50; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:44:01 vm12827 CRON[630294]: (root) CMD (/opt/pix2pi/bin/pix2pi_scale_hook.sh >/dev/null 2>&1)
May  1 14:45:01 vm12827 CRON[630848]: (root) CMD (sleep 50; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:45:01 vm12827 CRON[630850]: (root) CMD (sleep 20; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:45:01 vm12827 CRON[630851]: (root) CMD (sleep 40; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:45:01 vm12827 CRON[630852]: (root) CMD (/usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:45:01 vm12827 CRON[630853]: (root) CMD (sleep 10; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:45:01 vm12827 CRON[630859]: (root) CMD (sleep 30; /usr/local/bin/pix2pi_service_snapshot.sh >/tmp/pix2pi_service_snapshot_cron.log 2>&1)
May  1 14:45:01 vm12827 CRON[630862]: (root) CMD (/opt/pix2pi/bin/pix2pi_scale_hook.sh >/dev/null 2>&1)
```

## 6-6.7 Restic Version

```text
restic 0.12.1 compiled with go1.18.1 on linux/amd64
```

## 6-6.8 Restic Repository Snapshot Probe

```text
WARN ⚠️ RESTIC_PASSWORD not set in current shell; snapshot probe skipped safely
```

## 6-6.9 Docker PostgreSQL Containers

```text
NAMES                     IMAGE                             STATUS                PORTS
pix2pi_pg_replica         postgres:16                       Up 9 days             0.0.0.0:5434->5432/tcp, [::]:5434->5432/tcp
pix2pi_pg                 postgres:16                       Up 3 days             0.0.0.0:5433->5432/tcp, [::]:5433->5432/tcp
```

## 6-6.10 PostgreSQL WAL / Archive Runtime Probe

```text
===== container: pix2pi_pg_replica =====
/var/run/postgresql:5432 - accepting connections
===== container: pix2pi_pg =====
/var/run/postgresql:5432 - accepting connections
```

## 6-6.11 Env Backup Secret Inventory

```text
===== .env =====
DB_HOST=localhost
DB_PORT=5433
DB_USER=pix2pi
DB_PASSWORD=***MASKED***
DB_NAME=pix2pi
DB_READ_DSN=postgres://user:pass@localhost:5433/dbname?sslmode=disable
DB_WRITE_DSN=postgres://pix2pi:pix2pi@127.0.0.1:5433/pix2pi?sslmode=disable
DB_DSN=postgres://pix2pi:pix2pi@127.0.0.1:5433/pix2pi?sslmode=disable
===== /etc/pix2pi/ports.env =====
PG_PORT=5433
===== /opt/pix2pi/orchestrator/env/common.env =====
DB_WRITE_DSN="host=localhost port=5433 user=pix2pi password=***MASKED*** dbname=pix2pi sslmode=disable"
DB_READ_DSN="host=localhost port=5433 user=pix2pi password=***MASKED*** dbname=pix2pi sslmode=disable"
```

## 6-6.12 Nginx / Systemd Config Backup Candidates

```text
===== nginx files =====
/etc/nginx/conf.d/00_pix2pi_log_format.conf
/etc/nginx/conf.d/health.conf
/etc/nginx/conf.d/pix2pi_edge_live.conf
/etc/nginx/conf.d/pix2pi_faz4d_static.conf
/etc/nginx/fastcgi.conf
/etc/nginx/fastcgi_params
/etc/nginx/koi-utf
/etc/nginx/koi-win
/etc/nginx/mime.types
/etc/nginx/nginx.conf
/etc/nginx/proxy_params
/etc/nginx/scgi_params
/etc/nginx/sites-available/default
/etc/nginx/sites-available/default.bak.2026-03-19-061610
/etc/nginx/sites-available/pix2pi
/etc/nginx/sites-available/pix2pi_api_gateway
/etc/nginx/sites-available/pix2pi.bak_20260304_115445
/etc/nginx/sites-available/pix2pi.bak_20260320_075537
/etc/nginx/sites-available/pix2pi.bak_20260320_080106
/etc/nginx/sites-available/pix2pi.bak_20260320_083246
/etc/nginx/sites-available/pix2pi.bak_20260320_083604
/etc/nginx/sites-available/pix2pi_http_redirect
/etc/nginx/sites-available/pix2pi_ssl
/etc/nginx/sites-available/pix2pi_ssl.bak_1773945801
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_214713
/etc/nginx/sites-available/pix2pi_ssl.bak_20260319_215025
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_080805
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_083931
/etc/nginx/sites-available/pix2pi_ssl.bak_20260320_084317
/etc/nginx/snippets/fastcgi-php.conf
/etc/nginx/snippets/pix2pi_api.conf.bak_2026-03-15
/etc/nginx/snippets/pix2pi_gateway_internal_block.conf
/etc/nginx/snippets/pix2pi_gateway_proxy_headers.conf
/etc/nginx/snippets/pix2pi_gateway_public.conf
/etc/nginx/snippets/pix2pi_watchdog.conf
/etc/nginx/snippets/snakeoil.conf
/etc/nginx/uwsgi_params
/etc/nginx/win-utf
===== systemd pix2pi files =====
/etc/systemd/system/pix2pi-accounting.service
/etc/systemd/system/pix2pi-accounting.service.bak
/etc/systemd/system/pix2pi-accounting.service.bak_20260413_225444
/etc/systemd/system/pix2pi-api-gateway.service
/etc/systemd/system/pix2pi-api-gateway.service.bak
/etc/systemd/system/pix2pi-auth.service
/etc/systemd/system/pix2pi-backup-retention.service
/etc/systemd/system/pix2pi-backup-retention.timer
/etc/systemd/system/pix2pi-backup.service
/etc/systemd/system/pix2pi-cleanup.service
/etc/systemd/system/pix2pi-cleanup.timer
/etc/systemd/system/pix2pi-daily-backup.service
/etc/systemd/system/pix2pi-daily-backup.timer
/etc/systemd/system/pix2pi-early-warning-runtime.service
/etc/systemd/system/pix2pi-hourly-snapshot.service
/etc/systemd/system/pix2pi-hourly-snapshot.timer
/etc/systemd/system/pix2pi-identity.service
/etc/systemd/system/pix2pi-identity.service.bak_20260304_163601
/etc/systemd/system/pix2pi-incident-audit-runtime.service
/etc/systemd/system/pix2pi-jobs-runtime.service
/etc/systemd/system/pix2pi-mission-control.service
/etc/systemd/system/pix2pi-mission-control.service.bak_20260424_122839
/etc/systemd/system/pix2pi-notification-runtime.service
/etc/systemd/system/pix2pi-panel.service
/etc/systemd/system/pix2pi-panel.service.bak_20260304_165847
/etc/systemd/system/pix2pi-plugin-runtime.service
/etc/systemd/system/pix2pi-publicapi-runtime.service
/etc/systemd/system/pix2pi-query-read-model.service
/etc/systemd/system/pix2pi-query-read-model.service.bak
/etc/systemd/system/pix2pi-realtime-runtime.service
/etc/systemd/system/pix2pi-runtime-topology.service
/etc/systemd/system/pix2pi-service-discovery.service
/etc/systemd/system/pix2pi-service-discovery.service.bak
/etc/systemd/system/pix2pi-service-registry.service
/etc/systemd/system/pix2pi-user-created-consumer.service
/etc/systemd/system/pix2pi-watchdog.service
/etc/systemd/system/pix2pi-webhook-runtime.service
/etc/systemd/system/pix2pi-workflow-runtime.service
```

## 6-6.13 Runtime Audit Interpretation

```text
6-6.1 Host inventory collected OK ✅
6-6.2 Disk usage collected OK ✅
6-6.3 Backup directory inventory collected OK ✅
6-6.4 Backup/restore scripts inventory collected OK ✅
6-6.5 Cron/timer backup inventory collected OK ✅
6-6.6 Backup/retention logs collected OK ✅
6-6.7 Restic version/snapshot probe collected OK ✅
6-6.8 PostgreSQL runtime backup/WAL probe collected OK ✅
6-6.9 Env backup secret inventory collected OK ✅
6-6.10 Nginx/systemd config backup candidates collected OK ✅
FAZ_6_6_RUNTIME_AUDIT=COMPLETE ✅
```
