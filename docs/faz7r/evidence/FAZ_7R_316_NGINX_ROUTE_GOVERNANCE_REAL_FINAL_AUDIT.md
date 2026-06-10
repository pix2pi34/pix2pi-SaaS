# FAZ 7-R / 316 NGINX ROUTE GOVERNANCE REAL FINAL AUDIT

- PASS_COUNT=47
- FAIL_COUNT=0
- WARN_COUNT=0
- FINAL_STATUS=PASS
- RUN_ID=nginx-governance-316-20260513_220729

## Active files
```
/etc/nginx/conf.d/00-pix2pi-edge-security-headers.conf
/etc/nginx/conf.d/00_pix2pi_log_format.conf
/etc/nginx/conf.d/00_pix2pi_market.conf
/etc/nginx/conf.d/00_pix2pi_panel.conf
/etc/nginx/conf.d/00_pix2pi_panel_public.conf
/etc/nginx/conf.d/00_pix2pi_pos.conf
/etc/nginx/conf.d/health.conf
/etc/nginx/conf.d/pix2pi_faz4d_static.conf
/etc/nginx/mime.types
/etc/nginx/modules-enabled/50-mod-http-geoip2.conf
/etc/nginx/modules-enabled/50-mod-http-image-filter.conf
/etc/nginx/modules-enabled/50-mod-http-xslt-filter.conf
/etc/nginx/modules-enabled/50-mod-mail.conf
/etc/nginx/modules-enabled/50-mod-stream.conf
/etc/nginx/modules-enabled/70-mod-stream-geoip2.conf
/etc/nginx/nginx.conf
/etc/nginx/snippets/pix2pi_319_347_onboarding_api_route.conf
/etc/nginx/snippets/pix2pi_320_merchant_dashboard_api_route.conf
/etc/nginx/snippets/pix2pi_321_user_role_rbac_api_route.conf
/etc/nginx/snippets/pix2pi_322_business_settings_api_route.conf
/etc/nginx/snippets/pix2pi_323_party_api_route.conf
/etc/nginx/snippets/pix2pi_324_product_stock_api_route.conf
/etc/nginx/snippets/pix2pi_325_sales_pos_management_api_route.conf
/etc/nginx/snippets/pix2pi_326_document_screen_api_route.conf
/etc/nginx/snippets/pix2pi_327_reports_api_route.conf
/etc/nginx/snippets/pix2pi_328_import_export_api_route.conf
/etc/nginx/snippets/pix2pi_331_pos_sale_api_route.conf
/etc/nginx/snippets/pix2pi_333_offline_pos_api_route.conf
/etc/nginx/snippets/pix2pi_334_pwa_mobile_route.conf
/etc/nginx/snippets/pix2pi_348_user_invite_api_route.conf
/etc/nginx/snippets/pix2pi_350_panel_access_api_route.conf
/etc/nginx/snippets/pix2pi_351_pos_access_api_route.conf
/etc/nginx/snippets/pix2pi_352_tenant_isolation_api_route.conf
/etc/nginx/snippets/pix2pi_353_user_permission_api_route.conf
/etc/nginx/snippets/pix2pi_355_first_real_usage_smoke_route.conf
/etc/nginx/snippets/pix2pi_357_customer_access_activation_api_route.conf
/etc/nginx/snippets/pix2pi_357_help_center_route.conf
/etc/nginx/snippets/pix2pi_edge_security_headers.conf
```
## Nginx before stderr
```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```
## Nginx after stderr
```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```
## Duplicate server names before
```json
{
  "entries": [
    {
      "file": "/etc/nginx/conf.d/pix2pi_faz4d_static.conf",
      "start": 0,
      "end": 221,
      "port": "80",
      "server_name": "pix2pi.com.tr",
      "block_hash": "75fae8f8953f"
    },
    {
      "file": "/etc/nginx/conf.d/pix2pi_faz4d_static.conf",
      "start": 0,
      "end": 221,
      "port": "80",
      "server_name": "www.pix2pi.com.tr",
      "block_hash": "75fae8f8953f"
    },
    {
      "file": "/etc/nginx/conf.d/pix2pi_faz4d_static.conf",
      "start": 223,
      "end": 4425,
      "port": "443",
      "server_name": "pix2pi.com.tr",
      "block_hash": "fdbf5e4eb537"
    },
    {
      "file": "/etc/nginx/conf.d/pix2pi_faz4d_static.conf",
      "start": 223,
      "end": 4425,
      "port": "443",
      "server_name": "www.pix2pi.com.tr",
      "block_hash": "fdbf5e4eb537"
    },
    {
      "file": "/etc/nginx/conf.d/00_pix2pi_panel_public.conf",
      "start": 39,
      "end": 2003,
      "port": "80",
      "server_name": "panel.pix2pi.com.tr",
      "block_hash": "53b9a0055ce3"
    },
    {
      "file": "/etc/nginx/conf.d/00_pix2pi_panel_public.conf",
      "start": 2005,
      "end": 4424,
      "port": "443",
      "server_name": "panel.pix2pi.com.tr",
      "block_hash": "1d450b63e70d"
    },
    {
      "file": "/etc/nginx/conf.d/00_pix2pi_market.conf",
      "start": 159,
      "end": 1007,
      "port": "80",
      "server_name": "market.pix2pi.com.tr",
      "block_hash": "c3b0d0b11e43"
    },
    {
      "file": "/etc/nginx/conf.d/00_pix2pi_pos.conf",
      "start": 36,
      "end": 1105,
      "port": "80",
      "server_name": "pos.pix2pi.com.tr",
      "block_hash": "bc825c931f7c"
    },
    {
      "file": "/etc/nginx/conf.d/00_pix2pi_pos.conf",
      "start": 1107,
      "end": 3633,
      "port": "443",
      "server_name": "pos.pix2pi.com.tr",
      "block_hash": "20f8d4bad21e"
    }
  ],
  "duplicates": {}
}
```
## Duplicate server names after
```json
{
  "entries": [
    {
      "file": "/etc/nginx/conf.d/pix2pi_faz4d_static.conf",
      "start": 0,
      "end": 221,
      "port": "80",
      "server_name": "pix2pi.com.tr",
      "block_hash": "75fae8f8953f"
    },
    {
      "file": "/etc/nginx/conf.d/pix2pi_faz4d_static.conf",
      "start": 0,
      "end": 221,
      "port": "80",
      "server_name": "www.pix2pi.com.tr",
      "block_hash": "75fae8f8953f"
    },
    {
      "file": "/etc/nginx/conf.d/pix2pi_faz4d_static.conf",
      "start": 223,
      "end": 4425,
      "port": "443",
      "server_name": "pix2pi.com.tr",
      "block_hash": "fdbf5e4eb537"
    },
    {
      "file": "/etc/nginx/conf.d/pix2pi_faz4d_static.conf",
      "start": 223,
      "end": 4425,
      "port": "443",
      "server_name": "www.pix2pi.com.tr",
      "block_hash": "fdbf5e4eb537"
    },
    {
      "file": "/etc/nginx/conf.d/00_pix2pi_panel_public.conf",
      "start": 39,
      "end": 2003,
      "port": "80",
      "server_name": "panel.pix2pi.com.tr",
      "block_hash": "53b9a0055ce3"
    },
    {
      "file": "/etc/nginx/conf.d/00_pix2pi_panel_public.conf",
      "start": 2005,
      "end": 4424,
      "port": "443",
      "server_name": "panel.pix2pi.com.tr",
      "block_hash": "1d450b63e70d"
    },
    {
      "file": "/etc/nginx/conf.d/00_pix2pi_market.conf",
      "start": 159,
      "end": 1007,
      "port": "80",
      "server_name": "market.pix2pi.com.tr",
      "block_hash": "c3b0d0b11e43"
    },
    {
      "file": "/etc/nginx/conf.d/00_pix2pi_pos.conf",
      "start": 36,
      "end": 1105,
      "port": "80",
      "server_name": "pos.pix2pi.com.tr",
      "block_hash": "bc825c931f7c"
    },
    {
      "file": "/etc/nginx/conf.d/00_pix2pi_pos.conf",
      "start": 1107,
      "end": 3633,
      "port": "443",
      "server_name": "pos.pix2pi.com.tr",
      "block_hash": "20f8d4bad21e"
    }
  ],
  "duplicates": {}
}
```
## Snippet report
```
=== snippet includes in active config ===
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:17:    include /etc/nginx/snippets/pix2pi_333_offline_pos_api_route.conf;
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:20:    include /etc/nginx/snippets/pix2pi_328_import_export_api_route.conf;
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:25:    include /etc/nginx/snippets/pix2pi_326_document_screen_api_route.conf;
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:29:    include /etc/nginx/snippets/pix2pi_322_business_settings_api_route.conf;
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:32:    include /etc/nginx/snippets/pix2pi_327_reports_api_route.conf;
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:35:    include /etc/nginx/snippets/pix2pi_320_merchant_dashboard_api_route.conf;
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:38:    include /etc/nginx/snippets/pix2pi_355_first_real_usage_smoke_route.conf;
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:40:    include /etc/nginx/snippets/pix2pi_325_sales_pos_management_api_route.conf;
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:44:    include /etc/nginx/snippets/pix2pi_331_pos_sale_api_route.conf;
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:47:    include /etc/nginx/snippets/pix2pi_324_product_stock_api_route.conf;
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:50:    include /etc/nginx/snippets/pix2pi_323_party_api_route.conf;
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:53:    include /etc/nginx/snippets/pix2pi_357_help_center_route.conf;
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:55:    include /etc/nginx/snippets/pix2pi_357_customer_access_activation_api_route.conf;
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:59:    include /etc/nginx/snippets/pix2pi_353_user_permission_api_route.conf;
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:63:    include /etc/nginx/snippets/pix2pi_352_tenant_isolation_api_route.conf;
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:67:    include /etc/nginx/snippets/pix2pi_351_pos_access_api_route.conf;
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:71:    include /etc/nginx/snippets/pix2pi_350_panel_access_api_route.conf;
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:76:    include /etc/nginx/snippets/pix2pi_321_user_role_rbac_api_route.conf;
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:80:    include /etc/nginx/snippets/pix2pi_348_user_invite_api_route.conf;
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:83:    include /etc/nginx/snippets/pix2pi_319_347_onboarding_api_route.conf;
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:155:        include /etc/nginx/snippets/pix2pi_edge_security_headers.conf;
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:162:        include /etc/nginx/snippets/pix2pi_edge_security_headers.conf;
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:168:        include /etc/nginx/snippets/pix2pi_edge_security_headers.conf;
/etc/nginx/conf.d/pix2pi_faz4d_static.conf:175:        include /etc/nginx/snippets/pix2pi_edge_security_headers.conf;
/etc/nginx/conf.d/00_pix2pi_panel_public.conf:4:    include /etc/nginx/snippets/pix2pi_328_import_export_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_panel_public.conf:9:    include /etc/nginx/snippets/pix2pi_326_document_screen_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_panel_public.conf:13:    include /etc/nginx/snippets/pix2pi_322_business_settings_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_panel_public.conf:16:    include /etc/nginx/snippets/pix2pi_327_reports_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_panel_public.conf:19:    include /etc/nginx/snippets/pix2pi_320_merchant_dashboard_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_panel_public.conf:22:    include /etc/nginx/snippets/pix2pi_355_first_real_usage_smoke_route.conf;
/etc/nginx/conf.d/00_pix2pi_panel_public.conf:24:    include /etc/nginx/snippets/pix2pi_325_sales_pos_management_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_panel_public.conf:28:    include /etc/nginx/snippets/pix2pi_324_product_stock_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_panel_public.conf:31:    include /etc/nginx/snippets/pix2pi_323_party_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_panel_public.conf:34:    include /etc/nginx/snippets/pix2pi_357_help_center_route.conf;
/etc/nginx/conf.d/00_pix2pi_panel_public.conf:36:    include /etc/nginx/snippets/pix2pi_357_customer_access_activation_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_panel_public.conf:40:    include /etc/nginx/snippets/pix2pi_353_user_permission_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_panel_public.conf:44:    include /etc/nginx/snippets/pix2pi_352_tenant_isolation_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_panel_public.conf:48:    include /etc/nginx/snippets/pix2pi_350_panel_access_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_panel_public.conf:53:    include /etc/nginx/snippets/pix2pi_321_user_role_rbac_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_panel_public.conf:57:    include /etc/nginx/snippets/pix2pi_348_user_invite_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_panel_public.conf:88:    include /etc/nginx/snippets/pix2pi_333_offline_pos_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_panel_public.conf:91:    include /etc/nginx/snippets/pix2pi_328_import_export_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_panel_public.conf:96:    include /etc/nginx/snippets/pix2pi_326_document_screen_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_panel_public.conf:100:    include /etc/nginx/snippets/pix2pi_322_business_settings_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_panel_public.conf:103:    include /etc/nginx/snippets/pix2pi_327_reports_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_panel_public.conf:106:    include /etc/nginx/snippets/pix2pi_320_merchant_dashboard_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_panel_public.conf:109:    include /etc/nginx/snippets/pix2pi_355_first_real_usage_smoke_route.conf;
/etc/nginx/conf.d/00_pix2pi_panel_public.conf:111:    include /etc/nginx/snippets/pix2pi_325_sales_pos_management_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_panel_public.conf:115:    include /etc/nginx/snippets/pix2pi_331_pos_sale_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_panel_public.conf:118:    include /etc/nginx/snippets/pix2pi_324_product_stock_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_panel_public.conf:121:    include /etc/nginx/snippets/pix2pi_323_party_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_panel_public.conf:124:    include /etc/nginx/snippets/pix2pi_357_help_center_route.conf;
/etc/nginx/conf.d/00_pix2pi_panel_public.conf:126:    include /etc/nginx/snippets/pix2pi_357_customer_access_activation_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_panel_public.conf:130:    include /etc/nginx/snippets/pix2pi_353_user_permission_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_panel_public.conf:134:    include /etc/nginx/snippets/pix2pi_352_tenant_isolation_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_panel_public.conf:138:    include /etc/nginx/snippets/pix2pi_351_pos_access_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_panel_public.conf:142:    include /etc/nginx/snippets/pix2pi_350_panel_access_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_panel_public.conf:147:    include /etc/nginx/snippets/pix2pi_321_user_role_rbac_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_panel_public.conf:151:    include /etc/nginx/snippets/pix2pi_348_user_invite_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_panel_public.conf:155:    include /etc/nginx/snippets/pix2pi_319_347_onboarding_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_pos.conf:4:    include /etc/nginx/snippets/pix2pi_334_pwa_mobile_route.conf;
/etc/nginx/conf.d/00_pix2pi_pos.conf:8:    include /etc/nginx/snippets/pix2pi_333_offline_pos_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_pos.conf:11:    include /etc/nginx/snippets/pix2pi_331_pos_sale_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_pos.conf:14:    include /etc/nginx/snippets/pix2pi_351_pos_access_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_pos.conf:44:    include /etc/nginx/snippets/pix2pi_334_pwa_mobile_route.conf;
/etc/nginx/conf.d/00_pix2pi_pos.conf:48:    include /etc/nginx/snippets/pix2pi_333_offline_pos_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_pos.conf:51:    include /etc/nginx/snippets/pix2pi_328_import_export_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_pos.conf:56:    include /etc/nginx/snippets/pix2pi_326_document_screen_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_pos.conf:60:    include /etc/nginx/snippets/pix2pi_322_business_settings_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_pos.conf:63:    include /etc/nginx/snippets/pix2pi_327_reports_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_pos.conf:66:    include /etc/nginx/snippets/pix2pi_320_merchant_dashboard_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_pos.conf:69:    include /etc/nginx/snippets/pix2pi_355_first_real_usage_smoke_route.conf;
/etc/nginx/conf.d/00_pix2pi_pos.conf:71:    include /etc/nginx/snippets/pix2pi_325_sales_pos_management_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_pos.conf:75:    include /etc/nginx/snippets/pix2pi_331_pos_sale_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_pos.conf:78:    include /etc/nginx/snippets/pix2pi_324_product_stock_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_pos.conf:81:    include /etc/nginx/snippets/pix2pi_323_party_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_pos.conf:84:    include /etc/nginx/snippets/pix2pi_357_help_center_route.conf;
/etc/nginx/conf.d/00_pix2pi_pos.conf:86:    include /etc/nginx/snippets/pix2pi_357_customer_access_activation_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_pos.conf:90:    include /etc/nginx/snippets/pix2pi_353_user_permission_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_pos.conf:94:    include /etc/nginx/snippets/pix2pi_352_tenant_isolation_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_pos.conf:98:    include /etc/nginx/snippets/pix2pi_351_pos_access_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_pos.conf:102:    include /etc/nginx/snippets/pix2pi_350_panel_access_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_pos.conf:107:    include /etc/nginx/snippets/pix2pi_321_user_role_rbac_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_pos.conf:111:    include /etc/nginx/snippets/pix2pi_348_user_invite_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_pos.conf:114:    include /etc/nginx/snippets/pix2pi_319_347_onboarding_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_panel.conf:6:    include /etc/nginx/snippets/pix2pi_328_import_export_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_panel.conf:11:    include /etc/nginx/snippets/pix2pi_326_document_screen_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_panel.conf:15:    include /etc/nginx/snippets/pix2pi_322_business_settings_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_panel.conf:18:    include /etc/nginx/snippets/pix2pi_327_reports_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_panel.conf:21:    include /etc/nginx/snippets/pix2pi_320_merchant_dashboard_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_panel.conf:24:    include /etc/nginx/snippets/pix2pi_355_first_real_usage_smoke_route.conf;
/etc/nginx/conf.d/00_pix2pi_panel.conf:26:    include /etc/nginx/snippets/pix2pi_325_sales_pos_management_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_panel.conf:30:    include /etc/nginx/snippets/pix2pi_324_product_stock_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_panel.conf:33:    include /etc/nginx/snippets/pix2pi_323_party_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_panel.conf:36:    include /etc/nginx/snippets/pix2pi_357_help_center_route.conf;
/etc/nginx/conf.d/00_pix2pi_panel.conf:38:    include /etc/nginx/snippets/pix2pi_357_customer_access_activation_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_panel.conf:42:    include /etc/nginx/snippets/pix2pi_353_user_permission_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_panel.conf:46:    include /etc/nginx/snippets/pix2pi_352_tenant_isolation_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_panel.conf:50:    include /etc/nginx/snippets/pix2pi_350_panel_access_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_panel.conf:55:    include /etc/nginx/snippets/pix2pi_321_user_role_rbac_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_panel.conf:59:    include /etc/nginx/snippets/pix2pi_348_user_invite_api_route.conf;
/etc/nginx/conf.d/00_pix2pi_panel.conf:63:    include /etc/nginx/snippets/pix2pi_319_347_onboarding_api_route.conf;

=== global nginx.conf snippet includes ===
```
## Exact location report
```json
{
  "servers": [
    {
      "file": "/etc/nginx/conf.d/pix2pi_faz4d_static.conf",
      "server_block_index": 1,
      "exact_locations": [],
      "duplicates": {}
    },
    {
      "file": "/etc/nginx/conf.d/pix2pi_faz4d_static.conf",
      "server_block_index": 2,
      "exact_locations": [
        "/faz4d/pilot-go-live",
        "/faz5",
        "/faz5/",
        "/faz5/pricing",
        "/faz5/pricing/",
        "/faz5/developer",
        "/faz5/developer/",
        "/",
        "/index.html"
      ],
      "duplicates": {}
    },
    {
      "file": "/etc/nginx/conf.d/00_pix2pi_panel_public.conf",
      "server_block_index": 1,
      "exact_locations": [
        "/health"
      ],
      "duplicates": {}
    },
    {
      "file": "/etc/nginx/conf.d/00_pix2pi_panel_public.conf",
      "server_block_index": 2,
      "exact_locations": [
        "/health"
      ],
      "duplicates": {}
    },
    {
      "file": "/etc/nginx/conf.d/00_pix2pi_market.conf",
      "server_block_index": 1,
      "exact_locations": [
        "/health"
      ],
      "duplicates": {}
    },
    {
      "file": "/etc/nginx/conf.d/00_pix2pi_pos.conf",
      "server_block_index": 1,
      "exact_locations": [
        "/health"
      ],
      "duplicates": {}
    },
    {
      "file": "/etc/nginx/conf.d/00_pix2pi_pos.conf",
      "server_block_index": 2,
      "exact_locations": [
        "/health"
      ],
      "duplicates": {}
    },
    {
      "file": "/etc/nginx/conf.d/health.conf",
      "server_block_index": 1,
      "exact_locations": [],
      "duplicates": {}
    },
    {
      "file": "/etc/nginx/conf.d/00_pix2pi_panel.conf",
      "server_block_index": 1,
      "exact_locations": [
        "/health"
      ],
      "duplicates": {}
    }
  ],
  "conflicts": []
}
```
## DB SELECT
```
nginx_audit_run=1
nginx_audit_events=7
nginx_audit_deny=0
```
## Rollback SELECT
```
rollback_audit=0
```
## Final SELECT
```
final_run=1
final_events=7
final_denies=0
```
## Check log
```
dependency PASS evidence: FAZ_7R_334_PWA_MOBILE_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_333_OFFLINE_POS_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_328_IMPORT_EXPORT_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_326_DOCUMENT_SCREEN_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_322_BUSINESS_SETTINGS_REAL_FINAL_AUDIT.md / OK ✅
dependency PASS evidence: FAZ_7R_350_PANEL_ACCESS_REAL_FINAL_AUDIT.md / OK ✅
Postgres connection detected: docker/pix2pi_pg/pix2pi / OK ✅
REAL_DB_MIGRATION_APPLIED / OK ✅
table exists: edge_governance.nginx_route_audit_events / OK ✅
table exists: edge_governance.nginx_route_audit_runs / OK ✅
table exists: edge_governance.nginx_route_map_entries / OK ✅
nginx config backup created / OK ✅
nginx -T before syntax dump / OK ✅
active nginx config inventory written / OK ✅
duplicate server_name cleanup status / OK ✅
nginx -T after cleanup syntax dump / OK ✅
conflicting server_name warning removed / OK ✅
nginx config test status / OK ✅
nginx reload status / OK ✅
snippet include not present in global nginx.conf / OK ✅
snippet includes present in active server configs / OK ✅
exact location conflict status / OK ✅
API_ROUTE_STATUS panel.pix2pi.com.tr/api/panel/settings/update HTTP 422 / OK ✅
API_ROUTE_STATUS panel.pix2pi.com.tr/api/panel/reports/generate HTTP 422 / OK ✅
API_ROUTE_STATUS panel.pix2pi.com.tr/api/panel/documents/create-from-sale HTTP 422 / OK ✅
API_ROUTE_STATUS panel.pix2pi.com.tr/api/panel/import-export/import-parties HTTP 422 / OK ✅
API_ROUTE_STATUS pos.pix2pi.com.tr/api/pos/offline/queue-sale HTTP 422 / OK ✅
STATIC_ROUTE_STATUS panel.pix2pi.com.tr/dashboard/ marker / OK ✅
STATIC_ROUTE_STATUS panel.pix2pi.com.tr/settings/ marker / OK ✅
STATIC_ROUTE_STATUS panel.pix2pi.com.tr/documents/ marker / OK ✅
STATIC_ROUTE_STATUS panel.pix2pi.com.tr/reports/ marker / OK ✅
STATIC_ROUTE_STATUS panel.pix2pi.com.tr/import-export/ marker / OK ✅
STATIC_ROUTE_STATUS pos.pix2pi.com.tr/offline-pos/ marker / OK ✅
STATIC_ROUTE_STATUS pos.pix2pi.com.tr/mobile-pos/ marker / OK ✅
PWA_MANIFEST_GOVERNANCE_STATUS exact route current manifest / OK ✅
PWA_SW_GOVERNANCE_STATUS exact route current sw / OK ✅
PWA_OFFLINE_GOVERNANCE_STATUS exact route current offline shell / OK ✅
NGINX_GOVERNANCE_DB_WRITE_STATUS / OK ✅
REAL_DB_SELECT_STATUS nginx_audit_run=1 / OK ✅
REAL_DB_SELECT_STATUS nginx_audit_events=7 / OK ✅
REAL_DB_SELECT_STATUS nginx_audit_deny=0 / OK ✅
ROLLBACK_STATUS simulated DB failure occurred / OK ✅
TRANSACTION_STATUS rollback no partial write / OK ✅
FINAL_GOVERNANCE_STATUS final_run=1 / OK ✅
FINAL_GOVERNANCE_STATUS final_events=7 / OK ✅
FINAL_GOVERNANCE_STATUS final_denies=0 / OK ✅
config semantic validation / OK ✅
```
