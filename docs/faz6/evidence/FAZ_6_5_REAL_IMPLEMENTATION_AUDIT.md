# FAZ 6-5 Real Implementation Audit

Generated At: 2026-05-01T14:39:15+03:00  
Host: vm12827.ovadns.com  
Repo: /root/pix2pi/pix2pi-SaaS  

Bu audit, FAZ 6-5 Observability / Early Warning / SRE Dashboard maddelerinin sadece dokumanda mi kaldigini, yoksa kod/config/script icinde gercek karsiligi olup olmadigini kontrol eder.

---

## Scanned Files

```text
3010 /tmp/tmp.t8eNOCM7CV/files.txt

./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf
./1_archive/root_sh/create_erp_structure.sh
./1_archive/root_sh/step_100_backup_run_api_gateway_script.sh
./1_archive/root_sh/step_101_test_identity_gateway_ports.sh
./1_archive/root_sh/step_102_backup_api_gateway_before_rewrite.sh
./1_archive/root_sh/step_103_restart_api_gateway.sh
./1_archive/root_sh/step_104_test_gateway_identity_rewrite.sh
./1_archive/root_sh/step_105_backup_api_gateway_before_rate_limit.sh
./1_archive/root_sh/step_106_restart_api_gateway_after_rate_limit.sh
./1_archive/root_sh/step_107_test_api_gateway_rate_limit.sh
./1_archive/root_sh/step_108_backup_api_gateway_before_tenant_middleware.sh
./1_archive/root_sh/step_109_restart_api_gateway_after_tenant_middleware.sh
./1_archive/root_sh/step_10_run_tenant_event_pipeline_test.sh
./1_archive/root_sh/step_110_test_gateway_tenant_middleware.sh
./1_archive/root_sh/step_111_backup_api_gateway_before_redis_rate_limit.sh
./1_archive/root_sh/step_112a_install_redis_tools.sh
./1_archive/root_sh/step_112_check_redis_before_gateway_limit.sh
./1_archive/root_sh/step_113_add_go_redis_dependency.sh
./1_archive/root_sh/step_114_restart_api_gateway_after_redis_rate_limit.sh
./1_archive/root_sh/step_115_test_gateway_redis_rate_limit.sh
./1_archive/root_sh/step_116_backup_api_gateway_before_auth_route.sh
./1_archive/root_sh/step_117_check_auth_service_9002.sh
./1_archive/root_sh/step_11_backup_tenant_service_filter.sh
./1_archive/root_sh/step_121_create_auth_api_dir.sh
./1_archive/root_sh/step_122_run_auth_api.sh
./1_archive/root_sh/step_123_test_auth_api_local.sh
./1_archive/root_sh/step_124_test_auth_via_gateway.sh
./1_archive/root_sh/step_125_restart_gateway_after_auth_route.sh
./1_archive/root_sh/step_126_backup_api_gateway_before_combined_gateway.sh
./1_archive/root_sh/step_127_restart_combined_gateway.sh
./1_archive/root_sh/step_128_test_combined_gateway.sh
./1_archive/root_sh/step_129_test_scope_separation.sh
./1_archive/root_sh/step_12_run_tenant_service_filter_test.sh
./1_archive/root_sh/step_130_backup_gateway_before_authz_layer.sh
./1_archive/root_sh/step_130_backup_nginx_before_rate_limit.sh
./1_archive/root_sh/step_131_add_nginx_global_rate_limit.sh
./1_archive/root_sh/step_131_restart_gateway_after_bearer_tenant_match.sh
./1_archive/root_sh/step_132_enable_rate_limit_api_domain.sh
./1_archive/root_sh/step_132_test_gateway_bearer_tenant_match.sh
./1_archive/root_sh/step_133_reload_nginx_after_rate_limit.sh
./1_archive/root_sh/step_134_check_503_source.sh
./1_archive/root_sh/step_135_check_nginx_error_log.sh
./1_archive/root_sh/step_136_backup_fail2ban_before_nginx_jail.sh
./1_archive/root_sh/step_13_backup_redis_tenant_namespace.sh
./1_archive/root_sh/step_14_prepare_cache_dir.sh
./1_archive/root_sh/step_15_run_redis_tenant_namespace_test.sh
./1_archive/root_sh/step_160_install_nats_event_bus.sh
./1_archive/root_sh/step_161_check_nats_health.sh
./1_archive/root_sh/step_162_add_nats_go_client.sh
./1_archive/root_sh/step_163_prepare_nats_publisher_folder.sh
./1_archive/root_sh/step_164_prepare_nats_subscriber_folder.sh
./1_archive/root_sh/step_165_run_nats_subscriber.sh
./1_archive/root_sh/step_166_run_nats_publisher.sh
./1_archive/root_sh/step_16_backup_super_admin_policy.sh
./1_archive/root_sh/step_170_check_jetstream.sh
./1_archive/root_sh/step_171_run_nats_cli.sh
./1_archive/root_sh/step_172_create_jetstream_stream.sh
./1_archive/root_sh/step_173_check_jetstream_stream.sh
./1_archive/root_sh/step_174_create_sale_consumer.sh
./1_archive/root_sh/step_175_check_sale_consumer.sh
./1_archive/root_sh/step_17_prepare_security_dir.sh
./1_archive/root_sh/step_181_prepare_stock_service_folder.sh
./1_archive/root_sh/step_181_stok_servisi_klasor.sh
./1_archive/root_sh/step_182_run_stock_service.sh
./1_archive/root_sh/step_183_run_accounting_service.sh
./1_archive/root_sh/step_184_backup_panel_before_service_monitor.sh
./1_archive/root_sh/step_185_create_service_status_snapshot_script.sh
./1_archive/root_sh/step_186_rewrite_panel_with_service_monitor.sh
./1_archive/root_sh/step_187_create_service_status_cron.sh
./1_archive/root_sh/step_188_list_sh_files.sh
./1_archive/root_sh/step_188_prepare_cache_service_folder.sh
./1_archive/root_sh/step_188_verify_done_items.sh
./1_archive/root_sh/step_189_check_jetstream_streams.sh
./1_archive/root_sh/step_189_run_cache_service.sh
./1_archive/root_sh/step_18_run_super_admin_policy_test.sh
./1_archive/root_sh/step_190_reporting_subscriber_kur_ve_calistir.sh
./1_archive/root_sh/step_190_test_cache_service.sh
./1_archive/root_sh/step_191_prepare_idempotency_folder.sh
./1_archive/root_sh/step_191_reporting_service_arka_plan_panel.sh
```

## 6-5.1 Prometheus / metrics implementation izi

Pattern:

```text
prometheus|Prometheus|promhttp|/metrics|metrics|Metrics|Counter|Gauge|Histogram|Summary|Register|MustRegister
```

Match Count: 1866

```text
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:79:func (r *Registry) Register(name, address, source string) {
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:178:		registry.Register(req.Name, req.Address, "NATS")
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:233:		registry.Register(req.Name, req.Address, "HTTP")
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:303:func TestRegistryRegisterAndList(t *testing.T) {
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:306:	registry.Register("stock_service", "http://127.0.0.1:7001", "HTTP")
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:329:	registry.Register("accounting_service", "http://127.0.0.1:7002", "NATS")
./1_archive/root_sh/step_202_query_read_model_kur_ve_test_et.sh:58:type SaleSummary struct {
./1_archive/root_sh/step_202_query_read_model_kur_ve_test_et.sh:68:	Sales map[string]SaleSummary `json:"sales"`
./1_archive/root_sh/step_202_query_read_model_kur_ve_test_et.sh:73:		Sales: make(map[string]SaleSummary),
./1_archive/root_sh/step_202_query_read_model_kur_ve_test_et.sh:77:func (s *ReadStore) UpsertSale(sale SaleSummary) {
./1_archive/root_sh/step_202_query_read_model_kur_ve_test_et.sh:84:func (s *ReadStore) GetSale(orderID string) (SaleSummary, bool) {
./1_archive/root_sh/step_202_query_read_model_kur_ve_test_et.sh:91:func (s *ReadStore) ListSales() []SaleSummary {
./1_archive/root_sh/step_202_query_read_model_kur_ve_test_et.sh:95:	out := make([]SaleSummary, 0, len(s.Sales))
./1_archive/root_sh/step_202_query_read_model_kur_ve_test_et.sh:107:func (s *ReadStore) SearchSales(q string) []SaleSummary {
./1_archive/root_sh/step_202_query_read_model_kur_ve_test_et.sh:112:	out := make([]SaleSummary, 0)
./1_archive/root_sh/step_202_query_read_model_kur_ve_test_et.sh:157:		loaded.Sales = make(map[string]SaleSummary)
./1_archive/root_sh/step_202_query_read_model_kur_ve_test_et.sh:204:		store.UpsertSale(SaleSummary{
./1_archive/root_sh/step_202_query_read_model_kur_ve_test_et.sh:210:		store.UpsertSale(SaleSummary{
./1_archive/root_sh/step_202_query_read_model_kur_ve_test_et.sh:216:		store.UpsertSale(SaleSummary{
./1_archive/root_sh/step_202_query_read_model_kur_ve_test_et.sh:275:	store.UpsertSale(SaleSummary{
./1_archive/root_sh/step_202_query_read_model_kur_ve_test_et.sh:295:	store.UpsertSale(SaleSummary{
./1_archive/root_sh/step_202_query_read_model_kur_ve_test_et.sh:301:	store.UpsertSale(SaleSummary{
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:65:type SaleSummary struct {
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:75:	Sales map[string]SaleSummary `json:"sales"`
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:80:		Sales: make(map[string]SaleSummary),
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:84:func (s *ReadStore) UpsertSale(sale SaleSummary) {
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:92:func (s *ReadStore) GetSale(orderID string) (SaleSummary, bool) {
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:100:func (s *ReadStore) ListSales() []SaleSummary {
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:104:	out := make([]SaleSummary, 0, len(s.Sales))
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:116:func (s *ReadStore) SearchSales(q string) []SaleSummary {
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:121:	out := make([]SaleSummary, 0)
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:166:		loaded.Sales = make(map[string]SaleSummary)
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:213:		store.UpsertSale(SaleSummary{
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:219:		store.UpsertSale(SaleSummary{
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:225:		store.UpsertSale(SaleSummary{
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:249:		var req SaleSummary
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:316:	store.UpsertSale(SaleSummary{
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:336:	store.UpsertSale(SaleSummary{
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:342:	store.UpsertSale(SaleSummary{
./1_archive/root_sh/step_270_observability_stack.sh:7:mkdir -p $OBS/prometheus
./1_archive/root_sh/step_270_observability_stack.sh:18:  prometheus:
./1_archive/root_sh/step_270_observability_stack.sh:19:    image: prom/prometheus:latest
./1_archive/root_sh/step_270_observability_stack.sh:20:    container_name: pix2pi_prometheus
./1_archive/root_sh/step_270_observability_stack.sh:23:      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
./1_archive/root_sh/step_270_observability_stack.sh:69:      - prometheus
./1_archive/root_sh/step_270_observability_stack.sh:93:cat <<'YAMLEOF' > $OBS/prometheus/prometheus.yml
./1_archive/root_sh/step_270_observability_stack.sh:98:  - job_name: "prometheus"
./1_archive/root_sh/step_270_observability_stack.sh:100:      - targets: ["prometheus:9090"]
./1_archive/root_sh/step_270_observability_stack.sh:173:  - name: Prometheus
./1_archive/root_sh/step_270_observability_stack.sh:174:    type: prometheus
./1_archive/root_sh/step_270_observability_stack.sh:176:    url: http://prometheus:9090
./1_archive/root_sh/step_270_observability_stack.sh:212:        "type": "prometheus",
./1_archive/root_sh/step_270_observability_stack.sh:243:        "type": "prometheus",
./1_archive/root_sh/step_273_fix_promtail_positions.sh:42:  prometheus:
./1_archive/root_sh/step_273_fix_promtail_positions.sh:43:    image: prom/prometheus:latest
./1_archive/root_sh/step_273_fix_promtail_positions.sh:44:    container_name: pix2pi_prometheus
./1_archive/root_sh/step_273_fix_promtail_positions.sh:47:      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
./1_archive/root_sh/step_273_fix_promtail_positions.sh:94:      - prometheus
./1_archive/root_sh/step_408e_patch_gateway.sh:24:grep -q "query.RegisterRoutes" "$FILE" || sed -i '/fiber.New()/a\
./1_archive/root_sh/step_408e_patch_gateway.sh:25:    query.RegisterRoutes(app)\
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-5.1 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-5.2 Grafana / dashboard / datasource izi

Pattern:

```text
grafana|Grafana|dashboard|Dashboard|datasource|Datasource|panels|templating|prometheus.*datasource
```

Match Count: 2214

```text
./1_archive/root_sh/create_erp_structure.sh:31:mkdir -p $BASE/operations/dashboards
./1_archive/root_sh/step_270_observability_stack.sh:10:mkdir -p $OBS/grafana/provisioning/datasources
./1_archive/root_sh/step_270_observability_stack.sh:11:mkdir -p $OBS/grafana/provisioning/dashboards
./1_archive/root_sh/step_270_observability_stack.sh:12:mkdir -p $OBS/grafana/dashboards
./1_archive/root_sh/step_270_observability_stack.sh:30:    image: grafana/loki:2.9.8
./1_archive/root_sh/step_270_observability_stack.sh:42:    image: grafana/promtail:2.9.8
./1_archive/root_sh/step_270_observability_stack.sh:55:  grafana:
./1_archive/root_sh/step_270_observability_stack.sh:56:    image: grafana/grafana:latest
./1_archive/root_sh/step_270_observability_stack.sh:57:    container_name: pix2pi_grafana
./1_archive/root_sh/step_270_observability_stack.sh:64:      - ./grafana/provisioning:/etc/grafana/provisioning:ro
./1_archive/root_sh/step_270_observability_stack.sh:65:      - ./grafana/dashboards:/var/lib/grafana/dashboards:ro
./1_archive/root_sh/step_270_observability_stack.sh:169:cat <<'YAMLEOF' > $OBS/grafana/provisioning/datasources/datasources.yml
./1_archive/root_sh/step_270_observability_stack.sh:172:datasources:
./1_archive/root_sh/step_270_observability_stack.sh:185:cat <<'YAMLEOF' > $OBS/grafana/provisioning/dashboards/dashboards.yml
./1_archive/root_sh/step_270_observability_stack.sh:189:  - name: pix2pi-dashboards
./1_archive/root_sh/step_270_observability_stack.sh:196:      path: /var/lib/grafana/dashboards
./1_archive/root_sh/step_270_observability_stack.sh:199:cat <<'JSONEOF' > $OBS/grafana/dashboards/pix2pi-overview.json
./1_archive/root_sh/step_270_observability_stack.sh:209:  "panels": [
./1_archive/root_sh/step_270_observability_stack.sh:211:      "datasource": {
./1_archive/root_sh/step_270_observability_stack.sh:242:      "datasource": {
./1_archive/root_sh/step_270_observability_stack.sh:273:  "templating": {
./1_archive/root_sh/step_273_fix_promtail_positions.sh:54:    image: grafana/loki:2.9.8
./1_archive/root_sh/step_273_fix_promtail_positions.sh:66:    image: grafana/promtail:2.9.8
./1_archive/root_sh/step_273_fix_promtail_positions.sh:80:  grafana:
./1_archive/root_sh/step_273_fix_promtail_positions.sh:81:    image: grafana/grafana:latest
./1_archive/root_sh/step_273_fix_promtail_positions.sh:82:    container_name: pix2pi_grafana
./1_archive/root_sh/step_273_fix_promtail_positions.sh:89:      - ./grafana/provisioning:/etc/grafana/provisioning:ro
./1_archive/root_sh/step_273_fix_promtail_positions.sh:90:      - ./grafana/dashboards:/var/lib/grafana/dashboards:ro
./configs/faz5/revenue_metrics_policy_v1.json:132:  "dashboard_readiness": {
./configs/faz5/revenue_metrics_policy_v1.json:161:    "real_revenue_dashboard",
./configs/faz5/sales_demo_crm_policy_v1.json:138:    "runtime_sales_pipeline_dashboard",
./configs/faz5/support_sla_incident_policy_v1.json:192:    "runtime_incident_dashboard",
./deploy/observability/config/lvl11_delivery_catalog.yaml:3:  grafana_route:
./deploy/observability/config/lvl11_delivery_catalog.yaml:4:    id: grafana_primary
./deploy/observability/config/lvl11_delivery_catalog.yaml:5:    route: ops-grafana-route
./deploy/observability/config/lvl11_delivery_catalog.yaml:20:      - grafana_primary
./deploy/observability/config/lvl11_delivery_catalog.yaml:26:      - grafana_primary
./deploy/observability/docker-compose.yml:24:  grafana:
./deploy/observability/docker-compose.yml:25:    image: grafana/grafana:latest
./deploy/observability/docker-compose.yml:26:    container_name: pix2pi_grafana
./deploy/observability/docker-compose.yml:34:      - ./grafana/provisioning:/etc/grafana/provisioning:ro
./deploy/observability/docker-compose.yml:35:      - ./grafana/dashboards:/var/lib/grafana/dashboards:ro
./deploy/observability/docker-compose.yml:44:    image: grafana/loki:3.1.0
./deploy/observability/docker-compose.yml:57:    image: grafana/promtail:3.1.0
./deploy/observability/docker-compose.yml:71:    image: grafana/tempo:2.6.1
./deploy/observability/grafana/dashboards/docker-monitoring.json:7:      "type": "datasource",
./deploy/observability/grafana/dashboards/docker-monitoring.json:26:      "type": "grafana",
./deploy/observability/grafana/dashboards/docker-monitoring.json:27:      "id": "grafana",
./deploy/observability/grafana/dashboards/docker-monitoring.json:28:      "name": "Grafana",
./deploy/observability/grafana/dashboards/docker-monitoring.json:32:      "type": "datasource",
./deploy/observability/grafana/dashboards/docker-monitoring.json:39:  "title": "Docker + System Dashboard",
./deploy/observability/grafana/dashboards/docker-monitoring.json:40:  "description": "Simple Dashboard that display system metric (first line) and docker metric (line under). Dashboard compatible with Grafana 4 using alert functionality.",
./deploy/observability/grafana/dashboards/docker-monitoring.json:76:  "templating": {
./deploy/observability/grafana/dashboards/docker-monitoring.json:81:        "datasource": "${DS_PROMETHEUS}",
./deploy/observability/grafana/dashboards/docker-monitoring.json:104:        "datasource": null,
./deploy/observability/grafana/dashboards/docker-monitoring.json:199:        "datasource": "${DS_PROMETHEUS}",
./deploy/observability/grafana/dashboards/docker-monitoring.json:229:      "panels": [
./deploy/observability/grafana/dashboards/docker-monitoring.json:239:          "datasource": "${DS_PROMETHEUS}",
./deploy/observability/grafana/dashboards/docker-monitoring.json:320:          "datasource": "${DS_PROMETHEUS}",
./deploy/observability/grafana/dashboards/docker-monitoring.json:398:          "datasource": "${DS_PROMETHEUS}",
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-5.2 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-5.3.1 node_exporter izi

Pattern:

```text
node_exporter|node-exporter|9100|node_cpu|node_memory|node_filesystem
```

Match Count: 280

```text
./1_archive/root_sh/step_270_observability_stack.sh:74:  node_exporter:
./1_archive/root_sh/step_270_observability_stack.sh:75:    image: prom/node-exporter:latest
./1_archive/root_sh/step_270_observability_stack.sh:76:    container_name: pix2pi_node_exporter
./1_archive/root_sh/step_270_observability_stack.sh:84:      - "9100:9100"
./1_archive/root_sh/step_270_observability_stack.sh:102:  - job_name: "node_exporter"
./1_archive/root_sh/step_270_observability_stack.sh:104:      - targets: ["node_exporter:9100"]
./1_archive/root_sh/step_270_observability_stack.sh:234:          "expr": "rate(node_cpu_seconds_total{mode!=\"idle\"}[5m])",
./1_archive/root_sh/step_270_observability_stack.sh:259:          "expr": "node_memory_MemAvailable_bytes",
./1_archive/root_sh/step_273_fix_promtail_positions.sh:99:  node_exporter:
./1_archive/root_sh/step_273_fix_promtail_positions.sh:100:    image: prom/node-exporter:latest
./1_archive/root_sh/step_273_fix_promtail_positions.sh:101:    container_name: pix2pi_node_exporter
./1_archive/root_sh/step_273_fix_promtail_positions.sh:109:      - "9100:9100"
./deploy/observability/config/lvl11_signal_catalog.yaml:7:        metric: node_cpu_usage_percent
./deploy/observability/config/lvl11_signal_catalog.yaml:9:        metric: node_memory_usage_percent
./deploy/observability/docker-compose.yml:15:  node_exporter:
./deploy/observability/docker-compose.yml:16:    image: prom/node-exporter:latest
./deploy/observability/docker-compose.yml:17:    container_name: pix2pi_node_exporter
./deploy/observability/docker-compose.yml:20:      - "9100:9100"
./deploy/observability/grafana/dashboards/docker-monitoring.json:370:              "expr": "((node_memory_MemTotal{instance=~\"$server:.*\"} - node_memory_MemAvailable{instance=~\"$server:.*\"}) / node_memory_MemTotal{instance=~\"$server:.*\"}) * 100",
./deploy/observability/grafana/dashboards/docker-monitoring.json:448:              "expr": "min((node_filesystem_size{fstype=~\"xfs|ext4\",instance=~\"$server:.*\"} - node_filesystem_free{fstype=~\"xfs|ext4\",instance=~\"$server:.*\"} )/ node_filesystem_size{fstype=~\"xfs|ext4\",instance=~\"$server:.*\"})",
./deploy/observability/grafana/dashboards/docker-monitoring.json:527:              "expr": "node_load1{instance=~\"$server:.*\"} / count by(job, instance)(count by(job, instance, cpu)(node_cpu{instance=~\"$server:.*\"}))",
./deploy/observability/grafana/dashboards/docker-monitoring.json:830:              "expr": "node_load1{instance=~\"$server:.*\"} / count by(job, instance)(count by(job, instance, cpu)(node_cpu{instance=~\"$server:.*\"}))",
./deploy/observability/grafana/dashboards/docker-monitoring.json:952:              "expr": "node_filesystem_size{fstype=\"aufs\"} - node_filesystem_free{fstype=\"aufs\"}",
./deploy/observability/grafana/dashboards/docker-monitoring.json:1114:              "expr": "node_memory_Buffers",
./deploy/observability/grafana/dashboards/docker-monitoring.json:1117:              "legendFormat": "node_memory_Dirty",
./deploy/observability/grafana/dashboards/docker-monitoring.json:1122:              "expr": "node_memory_MemFree",
./deploy/observability/grafana/dashboards/docker-monitoring.json:1130:              "expr": "node_memory_MemAvailable",
./deploy/observability/grafana/dashboards/docker-monitoring.json:1138:              "expr": "node_memory_MemTotal - node_memory_MemAvailable",
./deploy/observability/grafana/dashboards/docker-monitoring.json:1146:              "expr": "node_memory_Inactive",
./deploy/observability/grafana/dashboards/docker-monitoring.json:1154:              "expr": "node_memory_KernelStack",
./deploy/observability/grafana/dashboards/docker-monitoring.json:1162:              "expr": "node_memory_Active",
./deploy/observability/grafana/dashboards/docker-monitoring.json:1170:              "expr": "node_memory_MemTotal - (node_memory_Active + node_memory_MemFree + node_memory_Inactive)",
./deploy/observability/grafana/dashboards/docker-monitoring.json:1178:              "expr": "node_memory_MemFree + node_memory_Inactive ",
./deploy/observability/grafana/dashboards/docker-monitoring.json:1194:              "expr": "node_memory_Inactive + node_memory_MemFree + node_memory_MemAvailable",
./deploy/observability/grafana/dashboards/node-exporter-full.json:316:          "expr": "100 * (1 - avg(rate(node_cpu_seconds_total{mode=\"idle\", instance=\"$node\"}[$__rate_interval])))",
./deploy/observability/grafana/dashboards/node-exporter-full.json:404:          "expr": "scalar(node_load1{instance=\"$node\",job=\"$job\"}) * 100 / count(count(node_cpu_seconds_total{instance=\"$node\",job=\"$job\"}) by (cpu))",
./deploy/observability/grafana/dashboards/node-exporter-full.json:483:          "expr": "((node_memory_MemTotal_bytes{instance=\"$node\", job=\"$job\"} - node_memory_MemFree_bytes{instance=\"$node\", job=\"$job\"}) / node_memory_MemTotal_bytes{instance=\"$node\", job=\"$job\"}) * 100",
./deploy/observability/grafana/dashboards/node-exporter-full.json:499:          "expr": "(1 - (node_memory_MemAvailable_bytes{instance=\"$node\", job=\"$job\"} / node_memory_MemTotal_bytes{instance=\"$node\", job=\"$job\"})) * 100",
./deploy/observability/grafana/dashboards/node-exporter-full.json:587:          "expr": "((node_memory_SwapTotal_bytes{instance=\"$node\",job=\"$job\"} - node_memory_SwapFree_bytes{instance=\"$node\",job=\"$job\"}) / (node_memory_SwapTotal_bytes{instance=\"$node\",job=\"$job\"})) * 100",
./deploy/observability/grafana/dashboards/node-exporter-full.json:673:          "expr": "100 - ((node_filesystem_avail_bytes{instance=\"$node\",job=\"$job\",mountpoint=\"/\",fstype!=\"rootfs\"} * 100) / node_filesystem_size_bytes{instance=\"$node\",job=\"$job\",mountpoint=\"/\",fstype!=\"rootfs\"})",
./deploy/observability/grafana/dashboards/node-exporter-full.json:756:          "expr": "count(count(node_cpu_seconds_total{instance=\"$node\",job=\"$job\"}) by (cpu))",
./deploy/observability/grafana/dashboards/node-exporter-full.json:926:          "expr": "node_filesystem_size_bytes{instance=\"$node\",job=\"$job\",mountpoint=\"/\",fstype!=\"rootfs\"}",
./deploy/observability/grafana/dashboards/node-exporter-full.json:1011:          "expr": "node_memory_MemTotal_bytes{instance=\"$node\",job=\"$job\"}",
./deploy/observability/grafana/dashboards/node-exporter-full.json:1094:          "expr": "node_memory_SwapTotal_bytes{instance=\"$node\",job=\"$job\"}",
./deploy/observability/grafana/dashboards/node-exporter-full.json:1328:          "expr": "sum(irate(node_cpu_seconds_total{instance=\"$node\",job=\"$job\", mode=\"system\"}[$__rate_interval])) / scalar(count(count(node_cpu_seconds_total{instance=\"$node\",job=\"$job\"}) by (cpu)))",
./deploy/observability/grafana/dashboards/node-exporter-full.json:1344:          "expr": "sum(irate(node_cpu_seconds_total{instance=\"$node\",job=\"$job\", mode=\"user\"}[$__rate_interval])) / scalar(count(count(node_cpu_seconds_total{instance=\"$node\",job=\"$job\"}) by (cpu)))",
./deploy/observability/grafana/dashboards/node-exporter-full.json:1359:          "expr": "sum(irate(node_cpu_seconds_total{instance=\"$node\",job=\"$job\", mode=\"iowait\"}[$__rate_interval])) / scalar(count(count(node_cpu_seconds_total{instance=\"$node\",job=\"$job\"}) by (cpu)))",
./deploy/observability/grafana/dashboards/node-exporter-full.json:1373:          "expr": "sum(irate(node_cpu_seconds_total{instance=\"$node\",job=\"$job\", mode=~\".*irq\"}[$__rate_interval])) / scalar(count(count(node_cpu_seconds_total{instance=\"$node\",job=\"$job\"}) by (cpu)))",
./deploy/observability/grafana/dashboards/node-exporter-full.json:1387:          "expr": "sum(irate(node_cpu_seconds_total{instance=\"$node\",job=\"$job\",  mode!='idle',mode!='user',mode!='system',mode!='iowait',mode!='irq',mode!='softirq'}[$__rate_interval])) / scalar(count(count(node_cpu_seconds_total{instance=\"$node\",job=\"$job\"}) by (cpu)))",
./deploy/observability/grafana/dashboards/node-exporter-full.json:1401:          "expr": "sum(irate(node_cpu_seconds_total{instance=\"$node\",job=\"$job\", mode=\"idle\"}[$__rate_interval])) / scalar(count(count(node_cpu_seconds_total{instance=\"$node\",job=\"$job\"}) by (cpu)))",
./deploy/observability/grafana/dashboards/node-exporter-full.json:1870:          "expr": "node_memory_MemTotal_bytes{instance=\"$node\",job=\"$job\"}",
./deploy/observability/grafana/dashboards/node-exporter-full.json:1883:          "expr": "node_memory_MemTotal_bytes{instance=\"$node\",job=\"$job\"} - node_memory_MemFree_bytes{instance=\"$node\",job=\"$job\"} - (node_memory_Cached_bytes{instance=\"$node\",job=\"$job\"} + node_memory_Buffers_bytes{instance=\"$node\",job=\"$job\"} + node_memory_SReclaimable_bytes{instance=\"$node\",job=\"$job\"})",
./deploy/observability/grafana/dashboards/node-exporter-full.json:1896:          "expr": "node_memory_Cached_bytes{instance=\"$node\",job=\"$job\"} + node_memory_Buffers_bytes{instance=\"$node\",job=\"$job\"} + node_memory_SReclaimable_bytes{instance=\"$node\",job=\"$job\"}",
./deploy/observability/grafana/dashboards/node-exporter-full.json:1908:          "expr": "node_memory_MemFree_bytes{instance=\"$node\",job=\"$job\"}",
./deploy/observability/grafana/dashboards/node-exporter-full.json:1920:          "expr": "(node_memory_SwapTotal_bytes{instance=\"$node\",job=\"$job\"} - node_memory_SwapFree_bytes{instance=\"$node\",job=\"$job\"})",
./deploy/observability/grafana/dashboards/node-exporter-full.json:2488:          "expr": "100 - ((node_filesystem_avail_bytes{instance=\"$node\",job=\"$job\",device!~'rootfs'} * 100) / node_filesystem_size_bytes{instance=\"$node\",job=\"$job\",device!~'rootfs'})",
./deploy/observability/grafana/dashboards/node-exporter-full.json:2728:              "expr": "sum(irate(node_cpu_seconds_total{instance=\"$node\",job=\"$job\", mode=\"system\"}[$__rate_interval])) / scalar(count(count(node_cpu_seconds_total{instance=\"$node\",job=\"$job\"}) by (cpu)))",
./deploy/observability/grafana/dashboards/node-exporter-full.json:2743:              "expr": "sum(irate(node_cpu_seconds_total{instance=\"$node\",job=\"$job\", mode=\"user\"}[$__rate_interval])) / scalar(count(count(node_cpu_seconds_total{instance=\"$node\",job=\"$job\"}) by (cpu)))",
./deploy/observability/grafana/dashboards/node-exporter-full.json:2757:              "expr": "sum(irate(node_cpu_seconds_total{instance=\"$node\",job=\"$job\", mode=\"nice\"}[$__rate_interval])) / scalar(count(count(node_cpu_seconds_total{instance=\"$node\",job=\"$job\"}) by (cpu)))",
./deploy/observability/grafana/dashboards/node-exporter-full.json:2771:              "expr": "sum by(instance) (irate(node_cpu_seconds_total{instance=\"$node\",job=\"$job\", mode=\"iowait\"}[$__rate_interval])) / scalar(count(count(node_cpu_seconds_total{instance=\"$node\",job=\"$job\"}) by (cpu)))",
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-5.3.1 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-5.3.2 cAdvisor izi

Pattern:

```text
cadvisor|cAdvisor|container_cpu|container_memory|8080.*metrics|8080:8080
```

Match Count: 52

```text
./deploy/observability/grafana/dashboards/docker-monitoring.json:649:            "{id=\"/\",instance=\"cadvisor:8080\",job=\"prometheus\"}": "#BA43A9"
./deploy/observability/grafana/dashboards/docker-monitoring.json:682:              "expr": "sum(rate(container_cpu_system_seconds_total[1m]))",
./deploy/observability/grafana/dashboards/docker-monitoring.json:690:              "expr": "sum(rate(container_cpu_system_seconds_total{name=~\".+\"}[1m]))",
./deploy/observability/grafana/dashboards/docker-monitoring.json:699:              "expr": "sum(rate(container_cpu_system_seconds_total{id=\"/\"}[1m]))",
./deploy/observability/grafana/dashboards/docker-monitoring.json:719:              "expr": "sum(rate(container_cpu_system_seconds_total{name=~\".+\"}[1m])) + sum(rate(container_cpu_system_seconds_total{id=\"/\"}[1m])) + sum(rate(process_cpu_seconds_total[1m]))",
./deploy/observability/grafana/dashboards/docker-monitoring.json:1074:              "expr": "container_memory_rss{name=~\".+\"}",
./deploy/observability/grafana/dashboards/docker-monitoring.json:1082:              "expr": "sum(container_memory_rss{name=~\".+\"})",
./deploy/observability/grafana/dashboards/docker-monitoring.json:1090:              "expr": "container_memory_usage_bytes{name=~\".+\"}",
./deploy/observability/grafana/dashboards/docker-monitoring.json:1098:              "expr": "container_memory_rss{id=\"/\"}",
./deploy/observability/grafana/dashboards/docker-monitoring.json:1106:              "expr": "sum(container_memory_rss)",
./deploy/observability/grafana/dashboards/docker-monitoring.json:1186:              "expr": "container_memory_rss{name=~\".+\"}",
./deploy/observability/grafana/dashboards/docker-monitoring.json:1385:              "expr": "sum(rate(container_cpu_usage_seconds_total{name=~\".+\"}[$interval])) by (name) * 100",
./deploy/observability/grafana/dashboards/docker-monitoring.json:1647:              "expr": "sum(container_memory_rss{name=~\".+\"}) by (name)",
./deploy/observability/grafana/dashboards/docker-monitoring.json:1655:              "expr": "container_memory_usage_bytes{name=~\".+\"}",
./deploy/observability/grafana/dashboards/docker-monitoring.json:1835:              "expr": "container_memory_rss{name=~\".+\"}",
./deploy/observability/grafana/dashboards/docker-monitoring.json:1843:              "expr": "container_memory_usage_bytes{name=~\".+\"}",
./deploy/observability/grafana/dashboards/docker-monitoring.json:1851:              "expr": "sum(container_memory_cache{name=~\".+\"}) by (name)",
./deploy/observability/prometheus/prometheus.yml:14:  - job_name: "cadvisor"
./deploy/observability/prometheus/prometheus.yml:17:      - targets: ["pix2pi_cadvisor:8080"]
./deploy/observability/prometheus.yml:13:  - job_name: "cadvisor"
./deploy/observability/prometheus.yml:15:      - targets: ["pix2pi_cadvisor:8080"]
./grafana/dashboards/docker-monitoring.json:649:            "{id=\"/\",instance=\"cadvisor:8080\",job=\"prometheus\"}": "#BA43A9"
./grafana/dashboards/docker-monitoring.json:682:              "expr": "sum(rate(container_cpu_system_seconds_total[1m]))",
./grafana/dashboards/docker-monitoring.json:690:              "expr": "sum(rate(container_cpu_system_seconds_total{name=~\".+\"}[1m]))",
./grafana/dashboards/docker-monitoring.json:699:              "expr": "sum(rate(container_cpu_system_seconds_total{id=\"/\"}[1m]))",
./grafana/dashboards/docker-monitoring.json:719:              "expr": "sum(rate(container_cpu_system_seconds_total{name=~\".+\"}[1m])) + sum(rate(container_cpu_system_seconds_total{id=\"/\"}[1m])) + sum(rate(process_cpu_seconds_total[1m]))",
./grafana/dashboards/docker-monitoring.json:1074:              "expr": "container_memory_rss{name=~\".+\"}",
./grafana/dashboards/docker-monitoring.json:1082:              "expr": "sum(container_memory_rss{name=~\".+\"})",
./grafana/dashboards/docker-monitoring.json:1090:              "expr": "container_memory_usage_bytes{name=~\".+\"}",
./grafana/dashboards/docker-monitoring.json:1098:              "expr": "container_memory_rss{id=\"/\"}",
./grafana/dashboards/docker-monitoring.json:1106:              "expr": "sum(container_memory_rss)",
./grafana/dashboards/docker-monitoring.json:1186:              "expr": "container_memory_rss{name=~\".+\"}",
./grafana/dashboards/docker-monitoring.json:1385:              "expr": "sum(rate(container_cpu_usage_seconds_total{name=~\".+\"}[$interval])) by (name) * 100",
./grafana/dashboards/docker-monitoring.json:1647:              "expr": "sum(container_memory_rss{name=~\".+\"}) by (name)",
./grafana/dashboards/docker-monitoring.json:1655:              "expr": "container_memory_usage_bytes{name=~\".+\"}",
./grafana/dashboards/docker-monitoring.json:1835:              "expr": "container_memory_rss{name=~\".+\"}",
./grafana/dashboards/docker-monitoring.json:1843:              "expr": "container_memory_usage_bytes{name=~\".+\"}",
./grafana/dashboards/docker-monitoring.json:1851:              "expr": "sum(container_memory_cache{name=~\".+\"}) by (name)",
./scripts/audit_faz6_5_observability_runtime.sh:53:  write_cmd_block "6-5.2 Observability Docker Containers" bash -lc "docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}' | grep -Ei 'prometheus|grafana|node|cadvisor|loki|alert|exporter|nats|postgres|redis|NAME' || true"
./scripts/audit_faz6_5_observability_runtime.sh:59:  write_cmd_block "6-5.3 Observability Systemd Services" bash -lc "systemctl list-units --type=service --all | grep -Ei 'prometheus|grafana|node|cadvisor|loki|alert|exporter|pix2pi|mission|registry|gateway' || true"
./scripts/audit_faz6_5_observability_runtime.sh:78:write_cmd_block "6-5.9 cAdvisor Metrics Probe" bash -lc "curl -fsS --max-time 3 http://127.0.0.1:8080/metrics 2>/dev/null | head -n 20 || echo 'WARN ⚠️ cAdvisor metrics unavailable'"
./scripts/audit_faz6_5_observability_runtime.sh:124:  echo "6-5.9 cAdvisor probe collected OK ✅"
./scripts/audit_faz6_5_real_implementation.sh:167:write_check "6-5.3.2" "cAdvisor izi" "cadvisor|cAdvisor|container_cpu|container_memory|8080.*metrics|8080:8080" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
./scripts/pilot/run_4c_2a_runtime_baseline_gap_scan.sh:119:CADVISOR_HTTP="$(curl_status http://127.0.0.1:8080/metrics)"
./scripts/pilot/run_4c_2b_critical_runtime_gap_classification.sh:156:  add_info "cAdvisor metrics 200."
./scripts/pilot/run_4c_2b_critical_runtime_gap_classification.sh:158:  add_warning "cAdvisor metrics 200 donmedi."
./scripts/pilot/run_4c_2d_runtime_endpoint_validation.sh:186:  add_warning "cAdvisor /metrics 200 donmedi. Sonuc: $CADVISOR_METRICS_HTTP"
./scripts/pilot/run_4c_2d_runtime_endpoint_validation.sh:188:  add_info "cAdvisor metrics 200."
./scripts/pilot/run_4c_2d_runtime_endpoint_validation.sh:266:| cAdvisor | $CADVISOR_PORT | $CADVISOR_PORT_STATUS |
./scripts/pilot/run_4c_2d_runtime_endpoint_validation.sh:282:| cAdvisor /metrics | $CADVISOR_METRICS_HTTP |
./scripts/test_faz6_5_observability_sre_dashboard.sh:102:check_grep "6-5 runtime cadvisor probe var" "$RUNTIME_EVIDENCE_FILE" "6-5.9 cAdvisor Metrics Probe"
./scripts/test_faz6_5_observability_sre_dashboard.sh:113:check_grep "6-5.3.2 cAdvisor real audit evidence var" "$REAL_EVIDENCE_FILE" "6-5.3.2 cAdvisor"
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-5.3.2 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-5.4 Early warning / alert rule izi

Pattern:

```text
alert:|Alertmanager|alertmanager|ALERT|warning|critical|threshold|for:|severity|expr:|cpu|memory|disk|latency|backlog|DLQ|5xx
```

Match Count: 2129

```text
./1_archive/root_sh/step_197_reporting_unknown_kaynaagini_bul_ve_duzelt.sh:115:    if "all_critical_services_up" in data:
./1_archive/root_sh/step_197_reporting_unknown_kaynaagini_bul_ve_duzelt.sh:123:        data["all_critical_services_up"] = hepsi
./1_archive/root_sh/step_270_observability_stack.sh:122:      store: inmemory
./1_archive/root_sh/step_270_observability_stack.sh:135:  alertmanager_url: http://localhost:9093
./1_archive/root_sh/step_270_observability_stack.sh:234:          "expr": "rate(node_cpu_seconds_total{mode!=\"idle\"}[5m])",
./1_archive/root_sh/step_270_observability_stack.sh:259:          "expr": "node_memory_MemAvailable_bytes",
./1_archive/root_sh/step_276_reduce_log_noise.sh:28:  - job_name: critical_system_logs
./1_archive/root_sh/step_282_fix_promtail_paths.sh:47:echo "OK ✅ wildcard kaldirildi (critical fix)"
./1_archive/root_sh/step_320_rewrite_panel_index.sh:22:      --critical:#b91c1c;
./1_archive/root_sh/step_320_rewrite_panel_index.sh:118:      color:var(--critical);
./1_archive/root_sh/step_320_rewrite_panel_index.sh:171:      color:var(--critical);
./1_archive/root_sh/step_327_backup_watchdog_before_fail_memory.sh:6:DST="$HOME/pix2pi/pix2pi-SaaS/.backups/service_watchdog_main.go.before_fail_memory_${TS}.bak"
./1_archive/root_sh/step_334_add_global_health_engine.sh:14:	CriticalServices []string `json:"critical_services"`
./1_archive/root_sh/step_334_add_global_health_engine.sh:22:	criticalList := []string{"api_gateway","identity","nats","redis"}
./1_archive/root_sh/step_334_add_global_health_engine.sh:24:	var criticalDown []string
./1_archive/root_sh/step_334_add_global_health_engine.sh:43:		for _, c := range criticalList {
./1_archive/root_sh/step_334_add_global_health_engine.sh:45:				criticalDown = append(criticalDown, s.Name)
./1_archive/root_sh/step_334_add_global_health_engine.sh:58:	if len(criticalDown) > 0 || risk == "HIGH" {
./1_archive/root_sh/step_334_add_global_health_engine.sh:68:		CriticalServices: criticalDown,
./1_archive/root_sh/step_353_rewrite_monitor_v2.sh:38:      --critical:#991b1b;
./1_archive/root_sh/step_353_rewrite_monitor_v2.sh:39:      --critical-bg:#fef2f2;
./1_archive/root_sh/step_353_rewrite_monitor_v2.sh:101:    .banner.critical{
./1_archive/root_sh/step_353_rewrite_monitor_v2.sh:102:      background:var(--critical-bg);
./1_archive/root_sh/step_353_rewrite_monitor_v2.sh:103:      color:var(--critical);
./1_archive/root_sh/step_353_rewrite_monitor_v2.sh:277:      <div id="globalBanner" class="banner critical">Yukleniyor...</div>
./1_archive/root_sh/step_353_rewrite_monitor_v2.sh:350:        banner.className = "banner critical";
./1_archive/root_sh/step_353_rewrite_monitor_v2.sh:356:        banner.className = "banner critical";
./1_archive/root_sh/step_353_rewrite_monitor_v2.sh:361:      banner.className = "banner critical";
./1_archive/root_sh/step_357_rewrite_monitor_clean.sh:31:      --critical:#991b1b;
./1_archive/root_sh/step_357_rewrite_monitor_clean.sh:32:      --critical-bg:#fef2f2;
./1_archive/root_sh/step_357_rewrite_monitor_clean.sh:84:    .banner.critical{
./1_archive/root_sh/step_357_rewrite_monitor_clean.sh:85:      background:var(--critical-bg);
./1_archive/root_sh/step_357_rewrite_monitor_clean.sh:86:      color:var(--critical);
./1_archive/root_sh/step_357_rewrite_monitor_clean.sh:146:      background:var(--critical-bg);
./1_archive/root_sh/step_357_rewrite_monitor_clean.sh:147:      color:var(--critical);
./1_archive/root_sh/step_357_rewrite_monitor_clean.sh:188:      <div id="overallBanner" class="banner critical">Kritik: Veri bekleniyor</div>
./1_archive/root_sh/step_357_rewrite_monitor_clean.sh:261:          cls: "banner critical",
./1_archive/root_sh/step_357_rewrite_monitor_clean.sh:274:        cls: "banner critical",
./1_archive/root_sh/step_357_rewrite_monitor_clean.sh:339:        bannerBox.className = "banner critical";
./1_archive/root_sh/step_360_rewrite_monitor_hardening.sh:114:    .banner.critical{
./1_archive/root_sh/step_360_rewrite_monitor_hardening.sh:336:        return { cls: "critical", text: "Kritik: Bazi servisler ayakta degil" };
./1_archive/root_sh/step_360_rewrite_monitor_hardening.sh:344:        return { cls: "critical", text: "Kritik: Bazi servisler ayakta degil" };
./1_archive/root_sh/step_360_rewrite_monitor_hardening.sh:427:        banner.className = "banner critical";
./1_archive/root_sh/step_371_add_early_warning_collector.sh:8:SCRIPT_PATH="$BIN_DIR/pix2pi_early_warning.sh"
./1_archive/root_sh/step_371_add_early_warning_collector.sh:47:  SEVERITY="critical"
./1_archive/root_sh/step_371_add_early_warning_collector.sh:49:  SEVERITY="warning"
./1_archive/root_sh/step_371_add_early_warning_collector.sh:57:  --arg severity "$SEVERITY" \
./1_archive/root_sh/step_371_add_early_warning_collector.sh:67:    severity: $severity,
./1_archive/root_sh/step_371_add_early_warning_collector.sh:78:printf "[%s] severity=%s global_status=%s running=%s stopped=%s degraded=%s planned=%s stopped_names=%s degraded_names=%s\n" \
./1_archive/root_sh/step_371_add_early_warning_collector.sh:90:echo "OK ✅ early warning guncellendi"
./1_archive/root_sh/step_372_test_early_warning_collector.sh:11:echo "2. severity cekiliyor..."
./1_archive/root_sh/step_372_test_early_warning_collector.sh:12:jq -r '.severity' /opt/pix2pi/runtime/watchdog_alerts.json
./1_archive/root_sh/step_373_add_early_warning_cron.sh:6:CRON_LINE='* * * * * /opt/pix2pi/bin/pix2pi_early_warning.sh >/dev/null 2>&1'
./1_archive/root_sh/step_373_add_early_warning_cron.sh:16:if grep -Fq "/opt/pix2pi/bin/pix2pi_early_warning.sh" "$TMP_CRON"; then
./1_archive/root_sh/step_374_add_auto_heal_engine.sh:15:ALERT_JSON="/opt/pix2pi/runtime/watchdog_alerts.json"
./1_archive/root_sh/step_374_add_auto_heal_engine.sh:26:if [ ! -f "$ALERT_JSON" ]; then
./1_archive/root_sh/step_374_add_auto_heal_engine.sh:31:SEVERITY="$(jq -r '.severity' "$ALERT_JSON")"
./1_archive/root_sh/step_374_add_auto_heal_engine.sh:32:STOPPED="$(jq -r '.stopped_names' "$ALERT_JSON")"
./1_archive/root_sh/step_374_add_auto_heal_engine.sh:34:if [ "$SEVERITY" != "critical" ]; then
./1_archive/root_sh/step_376_prepare_heal_state.sh:10:ALERT_DIR="$STATE_DIR/alerts"
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-5.4 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-5.5 Service health / mission control izi

Pattern:

```text
/health|healthz|Health|MissionControl|mission-control|service-registry|ServiceRegistry|health.*summary|summary.*health
```

Match Count: 835

```text
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:57:    location = /health {
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:61:        proxy_pass http://pix2pi_api_upstream/health;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:116:    location = /health {
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:120:        proxy_pass http://pix2pi_auth_upstream/health;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:57:    location = /health {
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:61:        proxy_pass http://pix2pi_api_upstream/health;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:116:    location = /health {
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:120:        proxy_pass http://pix2pi_auth_upstream/health;
./1_archive/root_sh/step_101_test_identity_gateway_ports.sh:5:curl -s http://127.0.0.1:9001/health || true
./1_archive/root_sh/step_101_test_identity_gateway_ports.sh:9:curl -s http://127.0.0.1:9010/health || true
./1_archive/root_sh/step_104_test_gateway_identity_rewrite.sh:5:curl -s http://127.0.0.1:9010/health
./1_archive/root_sh/step_104_test_gateway_identity_rewrite.sh:9:curl -s http://127.0.0.1:9001/health || true
./1_archive/root_sh/step_104_test_gateway_identity_rewrite.sh:13:curl -s http://127.0.0.1:9010/api/identity/health || true
./1_archive/root_sh/step_104_test_gateway_identity_rewrite.sh:17:curl -s https://api.pix2pi.com.tr/api/identity/health || true
./1_archive/root_sh/step_107_test_api_gateway_rate_limit.sh:4:URL="https://api.pix2pi.com.tr/api/identity/health"
./1_archive/root_sh/step_110_test_gateway_tenant_middleware.sh:4:URL="https://api.pix2pi.com.tr/api/identity/health"
./1_archive/root_sh/step_115_test_gateway_redis_rate_limit.sh:4:URL="https://api.pix2pi.com.tr/api/identity/health"
./1_archive/root_sh/step_117_check_auth_service_9002.sh:5:curl -s -i http://127.0.0.1:9002/health || true
./1_archive/root_sh/step_123_test_auth_api_local.sh:4:curl -i http://127.0.0.1:9002/health
./1_archive/root_sh/step_124_test_auth_via_gateway.sh:4:curl -i -H "X-Tenant-ID: tenant-auth-test" https://api.pix2pi.com.tr/api/auth/health
./1_archive/root_sh/step_128_test_combined_gateway.sh:5:curl -s -i https://api.pix2pi.com.tr/api/identity/health
./1_archive/root_sh/step_128_test_combined_gateway.sh:10:curl -s -i -H "X-Tenant-ID: tenant-combined-identity" https://api.pix2pi.com.tr/api/identity/health
./1_archive/root_sh/step_128_test_combined_gateway.sh:15:curl -s -i https://api.pix2pi.com.tr/api/auth/health
./1_archive/root_sh/step_128_test_combined_gateway.sh:20:curl -s -i -H "X-Tenant-ID: tenant-combined-auth" https://api.pix2pi.com.tr/api/auth/health
./1_archive/root_sh/step_129_test_scope_separation.sh:5:curl -s -i -H "X-Tenant-ID: tenant-scope-001" https://api.pix2pi.com.tr/api/auth/health
./1_archive/root_sh/step_129_test_scope_separation.sh:10:curl -s -i -H "X-Tenant-ID: tenant-scope-001" https://api.pix2pi.com.tr/api/identity/health
./1_archive/root_sh/step_132_test_gateway_bearer_tenant_match.sh:4:URL_IDENTITY="https://api.pix2pi.com.tr/api/identity/health"
./1_archive/root_sh/step_132_test_gateway_bearer_tenant_match.sh:5:URL_AUTH="https://api.pix2pi.com.tr/api/auth/health"
./1_archive/root_sh/step_134_check_503_source.sh:9:curl -i http://127.0.0.1:9010/health || true
./1_archive/root_sh/step_134_check_503_source.sh:13:curl -i http://127.0.0.1:9002/health || true
./1_archive/root_sh/step_134_check_503_source.sh:17:curl -i http://127.0.0.1:9001/health || true
./1_archive/root_sh/step_134_check_503_source.sh:21:curl -i -H "X-Tenant-ID: tenant-debug-001" https://api.pix2pi.com.tr/api/auth/health || true
./1_archive/root_sh/step_134_check_503_source.sh:25:curl -i -H "X-Tenant-ID: tenant-debug-001" https://api.pix2pi.com.tr/api/identity/health || true
./1_archive/root_sh/step_161_check_nats_health.sh:9:curl -s http://127.0.0.1:8222/healthz || true
./1_archive/root_sh/step_185_create_service_status_snapshot_script.sh:56:API_GATEWAY=$(durum_http_text "api_gateway" "http://127.0.0.1:9010/health" "Pix2pi API Gateway OK")
./1_archive/root_sh/step_185_create_service_status_snapshot_script.sh:57:IDENTITY=$(durum_http_json "identity" "http://127.0.0.1:9001/health" "\"service\":\"identity\"")
./1_archive/root_sh/step_185_create_service_status_snapshot_script.sh:58:AUTH=$(durum_http_json "auth" "http://127.0.0.1:9002/health" "\"service\":\"auth\"")
./1_archive/root_sh/step_186_rewrite_panel_with_service_monitor.sh:44:      <li><a href="/health">Panel Health</a></li>
./1_archive/root_sh/step_186_rewrite_panel_with_service_monitor.sh:45:      <li><a href="/api/health">API Health</a></li>
./1_archive/root_sh/step_190_test_cache_service.sh:5:curl -s http://127.0.0.1:9011/health
./1_archive/root_sh/step_193_panel_dosyasini_bul_patch_et.sh:33:    -e "Panel Health" \
./1_archive/root_sh/step_199_fix_panel_reporting_service.sh:68:      <li><a href="/health">Panel Health</a></li>
./1_archive/root_sh/step_199_fix_panel_reporting_service.sh:69:      <li><a href="/api/health">API Health</a></li>
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:206:	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:448:curl -s http://127.0.0.1:8090/health
./1_archive/root_sh/step_202_query_read_model_kur_ve_test_et.sh:189:	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
./1_archive/root_sh/step_202_query_read_model_kur_ve_test_et.sh:425:echo "11) Health testi..."
./1_archive/root_sh/step_202_query_read_model_kur_ve_test_et.sh:426:curl -s http://127.0.0.1:8091/health
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:198:	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
./1_archive/root_sh/step_204_panel_service_discovery_query_read_model_ekle.sh:75:      <li><a href="/health">Panel Health</a></li>
./1_archive/root_sh/step_204_panel_service_discovery_query_read_model_ekle.sh:76:      <li><a href="/api/health">API Health</a></li>
./1_archive/root_sh/step_272_test_observability_stack.sh:5:curl -s http://127.0.0.1:9090/-/healthy
./1_archive/root_sh/step_272_test_observability_stack.sh:15:curl -s http://127.0.0.1:3001/api/health
./1_archive/root_sh/step_290_monitor_core.sh:20:	HealthURL string `json:"health_url"`
./1_archive/root_sh/step_290_monitor_core.sh:45:	if s.HealthURL != "" {
./1_archive/root_sh/step_290_monitor_core.sh:47:		resp, err := c.Client.Get(s.HealthURL)
./1_archive/root_sh/step_290_monitor_core.sh:166:func TestCheck_HealthRunning(t *testing.T) {
./1_archive/root_sh/step_290_monitor_core.sh:168:	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
./1_archive/root_sh/step_290_monitor_core.sh:191:		HealthURL: "http://127.0.0.1:18091/health",
./1_archive/root_sh/step_291_watchdog_service.sh:14:    "health_url": "http://127.0.0.1:8080/health"
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-5.5 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-5.6.1 DB observability signal izi

Pattern:

```text
DB.*Stats|Stats\(\)|pg_isready|pg_stat|slow.*query|connection.*pool|SetMaxOpenConns|DB_HEALTH|database.*health
```

Match Count: 309

```text
./1_archive/root_sh/step_22_check_postgres_rls_env.sh:32:if command -v pg_isready >/dev/null 2>&1; then
./1_archive/root_sh/step_22_check_postgres_rls_env.sh:37:  pg_isready -h "$DB_HOST_VAL" -p "$DB_PORT_VAL" || true
./1_archive/root_sh/step_22_check_postgres_rls_env.sh:39:  echo "pg_isready yok"
./1_archive/root_sh/step_23_check_postgres_runtime.sh:32:if command -v pg_isready >/dev/null 2>&1; then
./1_archive/root_sh/step_23_check_postgres_runtime.sh:37:  pg_isready -h "$DB_HOST_VAL" -p "$DB_PORT_VAL" || true
./1_archive/root_sh/step_23_check_postgres_runtime.sh:39:  echo "pg_isready yok"
./1_archive/root_sh/step_24_start_postgres_runtime.sh:43:if command -v pg_isready >/dev/null 2>&1; then
./1_archive/root_sh/step_24_start_postgres_runtime.sh:48:  pg_isready -h "$DB_HOST_VAL" -p "$DB_PORT_VAL" || true
./1_archive/root_sh/step_24_start_postgres_runtime.sh:50:  echo "pg_isready yok"
./1_archive/root_sh/step_44c_replica_fix.sh:92:docker exec "$PRIMARY_CONTAINER" psql -U "$PRIMARY_DB_USER" -d "$PRIMARY_DB_NAME" -c "SELECT application_name, client_addr, state, sync_state FROM pg_stat_replication;"
./1_archive/root_sh/step_44c_replica_fix.sh:93:echo "OK ✅ pg_stat_replication kontrol bitti"
./cmd/early-warning-runtime/early_warning_runtime_main.go:163:	db.SetMaxOpenConns(5)
./cmd/early-warning-runtime/early_warning_runtime_main.go:441:		Message:     "database healthy",
./cmd/incident-audit-runtime/incident_audit_runtime_main.go:148:	db.SetMaxOpenConns(5)
./cmd/jobs-runtime/jobs_runtime_main.go:119:	db.SetMaxOpenConns(5)
./cmd/notification-runtime/notification_runtime_main.go:128:	db.SetMaxOpenConns(5)
./cmd/plugin-runtime/plugin_runtime_main.go:119:	db.SetMaxOpenConns(5)
./cmd/publicapi-runtime/publicapi_runtime_main.go:126:	db.SetMaxOpenConns(5)
./cmd/realtime-runtime/realtime_runtime_main.go:108:	db.SetMaxOpenConns(5)
./cmd/runtime-topology/runtime_topology_main.go:192:	db.SetMaxOpenConns(5)
./cmd/runtime-topology/runtime_topology_main.go:295:		Message:   "database healthy",
./cmd/user-created-consumer/user_created_consumer_main.go:176:	db.SetMaxOpenConns(5)
./cmd/webhook-runtime/webhook_runtime_main.go:125:	db.SetMaxOpenConns(5)
./cmd/workflow-runtime/workflow_runtime_main.go:140:	db.SetMaxOpenConns(5)
./internal/platform/db/postgres.go:37:	db.SetMaxOpenConns(25)
./internal/platform/monitor/database_pressure_early_warning_service.go:14:	ErrDatabasePressureNegativeSlowQueryRatio = errors.New("monitor: database slow query ratio cannot be negative")
./internal/platform/monitor/database_pressure_early_warning_service.go:20:	DatabasePressureMetricSlowQueryRatioPct  = "db_slow_query_ratio_pct"
./internal/platform/monitor/database_pressure_early_warning_service.go:143:		"database slow query ratio pressure detected",
./internal/platform/monitor/database_pressure_runtime_bridge_service.go:14:	ErrDatabaseRuntimeNegativeSlowQueryRatio = errors.New("monitor: database runtime slow query ratio cannot be negative")
./scripts/audit_faz6_2_db_l8_readiness.sh:123:    echo "## 6-2.7 pg_isready Container Probe"
./scripts/audit_faz6_2_db_l8_readiness.sh:133:        docker exec "$c" pg_isready 2>&1 || true
./scripts/audit_faz6_2_real_implementation.sh:170:write_check "6-2.3.1" "Connection pool SetMaxOpenConns" "SetMaxOpenConns" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
./scripts/audit_faz6_2_real_implementation.sh:182:write_check "6-2.4.3" "slow query / pg_stat_statements izi var mi" "log_min_duration_statement|pg_stat_statements|slow[ _-]?query|auto_explain" "optional" || OPTIONAL_WARN=$((OPTIONAL_WARN + 1))
./scripts/audit_faz6_2_real_implementation.sh:188:write_check "6-2.7" "DB observability metric / health izi" "pg_isready|db.*health|DB.*Health|Prometheus|prometheus|sql.DBStats|Stats\\(\\)" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
./scripts/audit_faz6_5_real_implementation.sh:173:write_check "6-5.6.1" "DB observability signal izi" "DB.*Stats|Stats\\(\\)|pg_isready|pg_stat|slow.*query|connection.*pool|SetMaxOpenConns|DB_HEALTH|database.*health" "required" || REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
./scripts/phase4_db_final_closure_gate.sh:295:  FINAL_TOTAL_CONNECTIONS="$(run_sql "select count(*)::text from pg_stat_activity where datname=current_database();")"
./scripts/phase4_db_final_closure_gate.sh:296:  FINAL_IDLE_TX_COUNT="$(run_sql "select count(*)::text from pg_stat_activity where datname=current_database() and state='idle in transaction';")"
./scripts/phase4_db_final_closure_gate.sh:297:  FINAL_LONG_QUERY_60S="$(run_sql "select count(*)::text from pg_stat_activity where datname=current_database() and state='active' and now() - query_start > interval '60 seconds';")"
./scripts/phase4_db_final_closure_gate.sh:299:  FINAL_DEADLOCK_COUNT="$(run_sql "select deadlocks::text from pg_stat_database where datname=current_database();")"
./scripts/phase4_db_final_closure_gate.sh:301:  FINAL_PG_STAT_EXTENSION="$(run_sql "select exists(select 1 from pg_extension where extname='pg_stat_statements');")"
./scripts/phase4_db_final_closure_gate.sh:324:if [ "$FINAL_PG_STAT_EXTENSION" != "t" ]; then fail "final pg_stat_statements extension aktif degil"; fi
./scripts/phase4_db_health_baseline.sh:244:  PG_STAT_EXTENSION="$(run_sql "select exists(select 1 from pg_extension where extname='pg_stat_statements');")"
./scripts/phase4_db_health_baseline.sh:246:  TOTAL_CONNECTIONS="$(run_sql "select count(*)::text from pg_stat_activity where datname=current_database();")"
./scripts/phase4_db_health_baseline.sh:247:  ACTIVE_CONNECTIONS="$(run_sql "select count(*)::text from pg_stat_activity where datname=current_database() and state='active';")"
./scripts/phase4_db_health_baseline.sh:248:  IDLE_CONNECTIONS="$(run_sql "select count(*)::text from pg_stat_activity where datname=current_database() and state='idle';")"
./scripts/phase4_db_health_baseline.sh:249:  IDLE_TX_CONNECTIONS="$(run_sql "select count(*)::text from pg_stat_activity where datname=current_database() and state='idle in transaction';")"
./scripts/phase4_db_health_baseline.sh:250:  DISABLED_CONNECTIONS="$(run_sql "select count(*)::text from pg_stat_activity where datname=current_database() and state='disabled';")"
./scripts/phase4_db_health_baseline.sh:256:  LONG_RUNNING_ACTIVE_QUERIES_60S="$(run_sql "select count(*)::text from pg_stat_activity where datname=current_database() and state='active' and now() - query_start > interval '${LONG_QUERY_WARN_SECONDS} seconds';")"
./scripts/phase4_db_health_baseline.sh:257:  MAX_ACTIVE_QUERY_AGE_SECONDS="$(run_sql "select coalesce(floor(max(extract(epoch from now() - query_start)))::bigint,0)::text from pg_stat_activity where datname=current_database() and state='active' and query_start is not null;")"
./scripts/phase4_db_health_baseline.sh:258:  MAX_XACT_AGE_SECONDS="$(run_sql "select coalesce(floor(max(extract(epoch from now() - xact_start)))::bigint,0)::text from pg_stat_activity where datname=current_database() and xact_start is not null;")"
./scripts/phase4_db_health_baseline.sh:259:  MAX_IDLE_TX_AGE_SECONDS="$(run_sql "select coalesce(floor(max(extract(epoch from now() - xact_start)))::bigint,0)::text from pg_stat_activity where datname=current_database() and state='idle in transaction' and xact_start is not null;")"
./scripts/phase4_db_health_baseline.sh:266:  DEADLOCK_COUNT="$(run_sql "select deadlocks::text from pg_stat_database where datname=current_database();")"
./scripts/phase4_db_health_baseline.sh:268:  REPLICATION_CLIENT_COUNT="$(run_sql "select count(*)::text from pg_stat_replication;")"
./scripts/phase4_db_health_baseline.sh:272:  STATS_RESET="$(run_sql "select coalesce(stats_reset::text,'NULL') from pg_stat_database where datname=current_database();")"
./scripts/phase4_db_health_baseline.sh:311:  fail "pg_stat_statements extension aktif degil"
./scripts/phase4_db_health_baseline.sh:325:from pg_stat_activity
./scripts/phase4_db_health_baseline.sh:367:DB_HEALTH_RISK_SCORE=0
./scripts/phase4_db_health_baseline.sh:370:  DB_HEALTH_RISK_SCORE=$((DB_HEALTH_RISK_SCORE + 2))
./scripts/phase4_db_health_baseline.sh:375:  DB_HEALTH_RISK_SCORE=$((DB_HEALTH_RISK_SCORE + 2))
./scripts/phase4_db_health_baseline.sh:380:  DB_HEALTH_RISK_SCORE=$((DB_HEALTH_RISK_SCORE + 2))
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-5.6.1 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-5.6.2 Event bus observability signal izi

Pattern:

```text
NATS|JetStream|backlog|pending|DLQ|retry|consumer.*lag|AckFloor|NumPending|event.*metric|publish.*count|consume.*count
```

Match Count: 725

```text
./1_archive/root_sh/step_160_install_nats_event_bus.sh:8:cat <<'NATSYML' > deploy/nats/docker-compose.yml
./1_archive/root_sh/step_160_install_nats_event_bus.sh:26:NATSYML
./1_archive/root_sh/step_160_install_nats_event_bus.sh:32:echo "OK ✅ NATS Event Bus kuruldu"
./1_archive/root_sh/step_161_check_nats_health.sh:4:echo "=== NATS 4222 ==="
./1_archive/root_sh/step_161_check_nats_health.sh:8:echo "=== NATS MONITOR 8222 ==="
./1_archive/root_sh/step_161_check_nats_health.sh:13:echo "OK ✅ NATS health kontrol bitti"
./1_archive/root_sh/step_162_add_nats_go_client.sh:8:echo "OK ✅ Go NATS client eklendi"
./1_archive/root_sh/step_170_check_jetstream.sh:4:echo "=== NATS JetStream kontrol ==="
./1_archive/root_sh/step_170_check_jetstream.sh:9:echo "OK ✅ JetStream kontrol bitti"
./1_archive/root_sh/step_174_create_sale_consumer.sh:15:  --max-pending 1000 \
./1_archive/root_sh/step_185_create_service_status_snapshot_script.sh:61:NATS=$(durum_docker "nats" "pix2pi_nats")
./1_archive/root_sh/step_185_create_service_status_snapshot_script.sh:84:  $NATS,
./1_archive/root_sh/step_189_check_jetstream_streams.sh:16:echo "OK ✅ JetStream stream kontrolu bitti"
./1_archive/root_sh/step_190_reporting_subscriber_kur_ve_calistir.sh:46:		log.Fatalf("NATS baglanti hatasi: %v", err)
./1_archive/root_sh/step_190_reporting_subscriber_kur_ve_calistir.sh:50:	js, err := nc.JetStream()
./1_archive/root_sh/step_190_reporting_subscriber_kur_ve_calistir.sh:52:		log.Fatalf("JetStream erisim hatasi: %v", err)
./1_archive/root_sh/step_190_reporting_subscriber_kur_ve_calistir.sh:102:		log.Fatal("HATA: hicbir JetStream subject'ine baglanilamadi")
./1_archive/root_sh/step_191_reporting_service_arka_plan_panel.sh:63:		log.Fatalf("NATS baglanti hatasi: %v", err)
./1_archive/root_sh/step_191_reporting_service_arka_plan_panel.sh:67:	js, err := nc.JetStream()
./1_archive/root_sh/step_191_reporting_service_arka_plan_panel.sh:69:		log.Fatalf("JetStream erisim hatasi: %v", err)
./1_archive/root_sh/step_194_test_retry.sh:8:echo "OK ✅ retry test bitti"
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:155:	natsURL := os.Getenv("NATS_URL")
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:164:		log.Fatalf("NATS baglanti hatasi: %v", err)
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:178:		registry.Register(req.Name, req.Address, "NATS")
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:179:		log.Printf("OK ✅ NATS register | name=%s | address=%s", req.Name, req.Address)
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:182:		log.Fatalf("NATS register subscribe hatasi: %v", err)
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:195:		ok := registry.Heartbeat(req.Name, "NATS")
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:197:			log.Printf("OK ✅ NATS heartbeat | name=%s", req.Name)
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:203:		log.Fatalf("NATS heartbeat subscribe hatasi: %v", err)
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:329:	registry.Register("accounting_service", "http://127.0.0.1:7002", "NATS")
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:330:	ok := registry.Heartbeat("accounting_service", "NATS")
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:335:	yok := registry.Heartbeat("olmayan_servis", "NATS")
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:469:echo "14) NATS register testi..."
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:472:echo "OK ✅ NATS register testi gecti"
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:475:echo "15) NATS heartbeat testi..."
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:478:echo "OK ✅ NATS heartbeat testi gecti"
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:492:echo "OK ✅ HTTP + NATS birlikte calisiyor"
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:465:	natsURL := os.Getenv("NATS_URL")
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:477:		log.Fatalf("NATS baglanti hatasi: %v", err)
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:481:	js, err := nc.JetStream()
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:483:		log.Fatalf("JetStream erisim hatasi: %v", err)
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:608:echo "12) Event entegrasyon testi icin NATS publish yapiliyor..."
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:611:echo "OK ✅ NATS publish gecti"
./1_archive/root_sh/step_392_production_hardening.sh:50:can_retry() {
./1_archive/root_sh/step_392_production_hardening.sh:72:    echo "svc=$svc action=blocked reason=max_retry"
./1_archive/root_sh/step_392_production_hardening.sh:76:  if ! can_retry "$svc"; then
./1_archive/root_sh/step_40_backup_event_retry.sh:9:  backups/app/manual/playground_main.go.event_retry.bak 2>/dev/null || true
./1_archive/root_sh/step_40_backup_event_retry.sh:12:  backups/app/manual/event_message.go.event_retry.bak 2>/dev/null || true
./1_archive/root_sh/step_40_backup_event_retry.sh:15:  backups/app/manual/event_bus_service.go.event_retry.bak 2>/dev/null || true
./1_archive/root_sh/step_40_backup_event_retry.sh:17:echo "OK ✅ event retry yedegi alindi"
./1_archive/root_sh/step_41_run_event_retry_test.sh:8:echo "OK ✅ event retry test calistirma bitti"
./1_archive/root_sh/step_45d0_event_recon.sh:11:  echo "===== 1) NATS / EVENT DOSYALARI ====="
./1_archive/root_sh/step_45d0_event_recon.sh:23:  echo "===== 3) NATS IMPORT ARAMA ====="
./1_archive/root_sh/step_46i_consumer_recon.sh:18:  echo "==== 2) NATS CONNECT ===="
./1_archive/root_sh/step_46i_consumer_recon.sh:19:  grep -Rni "nats.Connect\|nats.NewConn\|DefaultURL\|NATS_URL" cmd internal || true
./1_archive/root_sh/step_56a_finance_recon.sh:18:  echo "==== 3) NATS / SUBSCRIBE / PUBLISH ===="
./1_archive/root_sh/step_56a_finance_recon.sh:19:  grep -RInE 'nats|Subscribe|QueueSubscribe|Publish|JetStream|user.created|sale.created|pix2pi\.' ~/pix2pi/pix2pi-SaaS/cmd ~/pix2pi/pix2pi-SaaS/internal || true
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:725:        "@humanwhocodes/retry": "^0.4.0"
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:755:    "node_modules/@humanwhocodes/retry": {
./.backup/lvl8_6_route_structure_20260420_222229/package-lock.json:757:      "resolved": "https://registry.npmjs.org/@humanwhocodes/retry/-/retry-0.4.3.tgz",
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-5.6.2 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-5.6.3 Gateway observability signal izi

Pattern:

```text
gateway|Gateway|request_id|X-Request-ID|latency|duration|status_code|5xx|4xx|rate.*limit|upstream|proxy
```

Match Count: 2475

```text
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:3:upstream pix2pi_api_upstream {
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:8:upstream pix2pi_panel_upstream {
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:13:upstream pix2pi_auth_upstream {
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:18:upstream pix2pi_pos_upstream {
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:60:        include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_proxy_common.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:61:        proxy_pass http://pix2pi_api_upstream/health;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:66:        include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_proxy_common.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:67:        proxy_pass http://pix2pi_api_upstream;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:92:        include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_proxy_common.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:93:        proxy_pass http://pix2pi_panel_upstream;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:119:        include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_proxy_common.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:120:        proxy_pass http://pix2pi_auth_upstream/health;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:125:        include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_proxy_common.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:126:        proxy_pass http://pix2pi_auth_upstream;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:151:        include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_proxy_common.conf;
./${BACKUP_DIR}/file_backup/etc/nginx/conf.d/pix2pi_edge_live.conf:152:        proxy_pass http://pix2pi_pos_upstream;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:3:upstream pix2pi_api_upstream {
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:8:upstream pix2pi_panel_upstream {
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:13:upstream pix2pi_auth_upstream {
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:18:upstream pix2pi_pos_upstream {
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:60:        include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_proxy_common.conf;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:61:        proxy_pass http://pix2pi_api_upstream/health;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:66:        include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_proxy_common.conf;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:67:        proxy_pass http://pix2pi_api_upstream;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:92:        include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_proxy_common.conf;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:93:        proxy_pass http://pix2pi_panel_upstream;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:119:        include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_proxy_common.conf;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:120:        proxy_pass http://pix2pi_auth_upstream/health;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:125:        include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_proxy_common.conf;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:126:        proxy_pass http://pix2pi_auth_upstream;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:151:        include /root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/includes/pix2pi_proxy_common.conf;
./${BACKUP_DIR}/file_backup/root/pix2pi/pix2pi-SaaS/deploy/edge/nginx/generated/pix2pi_edge.conf:152:        proxy_pass http://pix2pi_pos_upstream;
./1_archive/root_sh/step_100_backup_run_api_gateway_script.sh:6:cp ~/pix2pi/pix2pi-SaaS/step_99_run_api_gateway.sh \
./1_archive/root_sh/step_100_backup_run_api_gateway_script.sh:7:  ~/pix2pi/pix2pi-SaaS/backups/scripts/step_99_run_api_gateway.sh.bak
./1_archive/root_sh/step_100_backup_run_api_gateway_script.sh:9:echo "OK ✅ api gateway run script yedegi alindi"
./1_archive/root_sh/step_101_test_identity_gateway_ports.sh:12:echo "OK ✅ identity ve gateway port testi bitti"
./1_archive/root_sh/step_102_backup_api_gateway_before_rewrite.sh:4:mkdir -p ~/pix2pi/pix2pi-SaaS/backups/api-gateway
./1_archive/root_sh/step_102_backup_api_gateway_before_rewrite.sh:6:cp ~/pix2pi/pix2pi-SaaS/cmd/api-gateway/api_gateway_main.go \
./1_archive/root_sh/step_102_backup_api_gateway_before_rewrite.sh:7:  ~/pix2pi/pix2pi-SaaS/backups/api-gateway/api_gateway_main.go.before_rewrite.bak
./1_archive/root_sh/step_102_backup_api_gateway_before_rewrite.sh:9:echo "OK ✅ api gateway dosya yedegi alindi"
./1_archive/root_sh/step_103_restart_api_gateway.sh:4:pkill -f api_gateway_main || true
./1_archive/root_sh/step_103_restart_api_gateway.sh:8:nohup go run cmd/api-gateway/api_gateway_main.go >/tmp/pix2pi_api_gateway.log 2>&1 &
./1_archive/root_sh/step_103_restart_api_gateway.sh:12:cat /tmp/pix2pi_api_gateway.log || true
./1_archive/root_sh/step_103_restart_api_gateway.sh:14:echo "OK ✅ api gateway restart bitti"
./1_archive/root_sh/step_104_test_gateway_identity_rewrite.sh:20:echo "OK ✅ gateway identity rewrite test bitti"
./1_archive/root_sh/step_105_backup_api_gateway_before_rate_limit.sh:4:mkdir -p ~/pix2pi/pix2pi-SaaS/backups/api-gateway
./1_archive/root_sh/step_105_backup_api_gateway_before_rate_limit.sh:6:cp ~/pix2pi/pix2pi-SaaS/cmd/api-gateway/api_gateway_main.go \
./1_archive/root_sh/step_105_backup_api_gateway_before_rate_limit.sh:7:  ~/pix2pi/pix2pi-SaaS/backups/api-gateway/api_gateway_main.go.before_rate_limit.bak
./1_archive/root_sh/step_105_backup_api_gateway_before_rate_limit.sh:9:echo "OK ✅ api gateway rate limit oncesi yedek alindi"
./1_archive/root_sh/step_106_restart_api_gateway_after_rate_limit.sh:4:pkill -f api_gateway_main || true
./1_archive/root_sh/step_106_restart_api_gateway_after_rate_limit.sh:8:nohup go run cmd/api-gateway/api_gateway_main.go >/tmp/pix2pi_api_gateway.log 2>&1 &
./1_archive/root_sh/step_106_restart_api_gateway_after_rate_limit.sh:12:cat /tmp/pix2pi_api_gateway.log || true
./1_archive/root_sh/step_106_restart_api_gateway_after_rate_limit.sh:14:echo "OK ✅ api gateway rate limitli restart bitti"
./1_archive/root_sh/step_107_test_api_gateway_rate_limit.sh:23:echo "OK ✅ api gateway rate limit test bitti"
./1_archive/root_sh/step_108_backup_api_gateway_before_tenant_middleware.sh:4:mkdir -p ~/pix2pi/pix2pi-SaaS/backups/api-gateway
./1_archive/root_sh/step_108_backup_api_gateway_before_tenant_middleware.sh:6:cp ~/pix2pi/pix2pi-SaaS/cmd/api-gateway/api_gateway_main.go \
./1_archive/root_sh/step_108_backup_api_gateway_before_tenant_middleware.sh:7:  ~/pix2pi/pix2pi-SaaS/backups/api-gateway/api_gateway_main.go.before_tenant_middleware.bak
./1_archive/root_sh/step_108_backup_api_gateway_before_tenant_middleware.sh:9:echo "OK ✅ tenant middleware oncesi api gateway yedegi alindi"
./1_archive/root_sh/step_109_restart_api_gateway_after_tenant_middleware.sh:4:pkill -f api_gateway_main || true
./1_archive/root_sh/step_109_restart_api_gateway_after_tenant_middleware.sh:8:nohup go run cmd/api-gateway/api_gateway_main.go >/tmp/pix2pi_api_gateway.log 2>&1 &
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-5.6.3 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-5.7 Tenant-level observability izi

Pattern:

```text
tenant_id|tenant_uuid|TenantID|TenantUUID|tenant.*metric|metric.*tenant|tenant.*latency|tenant.*error|tenant.*request
```

Match Count: 5727

```text
./1_archive/root_sh/step_210_audit_full.sh:30:	if entry.TenantID == "" {
./1_archive/root_sh/step_210_audit_full.sh:79:		TenantID: "tenant-1",
./1_archive/root_sh/step_210_audit_full.sh:97:		TenantID: "tenant-1",
./1_archive/root_sh/step_21_run_postgres_rls_test.sh:25:SET app.tenant_id = 'tenant-001';
./1_archive/root_sh/step_21_run_postgres_rls_test.sh:32:SET app.tenant_id = 'tenant-002';
./1_archive/root_sh/step_230_snapshot_schema.sh:9:    tenant_id TEXT NOT NULL,
./1_archive/root_sh/step_230_snapshot_schema.sh:18:ON snapshots (tenant_id, aggregate_type, aggregate_id);
./1_archive/root_sh/step_231_snapshot_full.sh:28:	TenantID    string    `json:"tenant_id"`
./1_archive/root_sh/step_231_snapshot_full.sh:33:func (r *Repository) UpsertStockSaleSnapshot(tenantID string, saleID string, amount int) error {
./1_archive/root_sh/step_231_snapshot_full.sh:37:		TenantID:    tenantID,
./1_archive/root_sh/step_231_snapshot_full.sh:48:		INSERT INTO snapshots (tenant_id, aggregate_type, aggregate_id, version, state, updated_at)
./1_archive/root_sh/step_231_snapshot_full.sh:50:		ON CONFLICT (tenant_id, aggregate_type, aggregate_id)
./1_archive/root_sh/step_231_snapshot_full.sh:65:func (r *Repository) GetSnapshot(tenantID string, aggregateType string, aggregateID string) (string, int, error) {
./1_archive/root_sh/step_231_snapshot_full.sh:72:		WHERE tenant_id = $1 AND aggregate_type = $2 AND aggregate_id = $3
./1_archive/root_sh/step_231_snapshot_full.sh:108:	_, err = db.Exec(`DELETE FROM snapshots WHERE tenant_id = 'tenant-test'`)
./1_archive/root_sh/step_232_run_snapshot_flow.sh:14:-d '{"subject":"pix2pi.sale.created","data":"{\"event\":\"sale.created\",\"sale_id\":\"S-SNAP-1\",\"tenant_id\":\"tenant-001\",\"amount\":1300}"}'
./1_archive/root_sh/step_232_run_snapshot_flow.sh:18:PGPASSWORD=***MASKED***
./1_archive/root_sh/step_240_enable_rls_snapshots.sh:14:USING (tenant_id = current_setting('app.current_tenant', true))
./1_archive/root_sh/step_240_enable_rls_snapshots.sh:15:WITH CHECK (tenant_id = current_setting('app.current_tenant', true));
./1_archive/root_sh/step_241_test_rls_snapshots.sh:8:SELECT tenant_id, aggregate_type, aggregate_id, version
./1_archive/root_sh/step_241_test_rls_snapshots.sh:19:SELECT tenant_id, aggregate_type, aggregate_id, version
./1_archive/root_sh/step_241_test_rls_snapshots.sh:30:INSERT INTO snapshots (tenant_id, aggregate_type, aggregate_id, version, state, updated_at)
./1_archive/root_sh/step_243_test_rls_real.sh:8:SELECT tenant_id, aggregate_id FROM snapshots;
./1_archive/root_sh/step_243_test_rls_real.sh:17:SELECT tenant_id, aggregate_id FROM snapshots;
./1_archive/root_sh/step_243_test_rls_real.sh:26:INSERT INTO snapshots (tenant_id, aggregate_type, aggregate_id, version, state, updated_at)
./1_archive/root_sh/step_250_tenant_isolation_verification.sh:8:SELECT string_agg(tenant_id || ':' || aggregate_id, ',')
./1_archive/root_sh/step_250_tenant_isolation_verification.sh:33:SELECT string_agg(tenant_id || ':' || aggregate_id, ',')
./1_archive/root_sh/step_250_tenant_isolation_verification.sh:59:INSERT INTO snapshots (tenant_id, aggregate_type, aggregate_id, version, state, updated_at)
./1_archive/root_sh/step_250_tenant_isolation_verification.sh:86:INSERT INTO snapshots (tenant_id, aggregate_type, aggregate_id, version, state, updated_at)
./1_archive/root_sh/step_250_tenant_isolation_verification.sh:88:ON CONFLICT (tenant_id, aggregate_type, aggregate_id)
./1_archive/root_sh/step_251_fix_verification.sh:9:INSERT INTO snapshots (tenant_id, aggregate_type, aggregate_id, version, state, updated_at)
./1_archive/root_sh/step_260_audit_schema.sh:9:    tenant_id TEXT NOT NULL,
./1_archive/root_sh/step_260_audit_schema.sh:21:ON audit_logs (tenant_id, created_at DESC);
./1_archive/root_sh/step_261_audit_full.sh:25:	TenantID   string
./1_archive/root_sh/step_261_audit_full.sh:43:			tenant_id,
./1_archive/root_sh/step_261_audit_full.sh:54:		rec.TenantID,
./1_archive/root_sh/step_261_audit_full.sh:95:		TenantID:   "tenant-audit-test",
./1_archive/root_sh/step_261_audit_full.sh:115:		WHERE tenant_id = 'tenant-audit-test'
./1_archive/root_sh/step_262_run_audit_flow.sh:14:-d '{"subject":"pix2pi.sale.created","data":"{\"event\":\"sale.created\",\"sale_id\":\"S-AUDIT-REAL-1\",\"tenant_id\":\"tenant-001\",\"amount\":1700}"}'
./1_archive/root_sh/step_262_run_audit_flow.sh:18:PGPASSWORD=***MASKED***
./1_archive/root_sh/step_408_fix_api_gateway_nethttp_full.sh:37:const tenantKey contextKey = "tenant_id"
./1_archive/root_sh/step_408_fix_api_gateway_nethttp_full.sh:48:	TenantID string
./1_archive/root_sh/step_408_fix_api_gateway_nethttp_full.sh:65:func (rl *RedisRateLimiter) Allow(tenantID string, scope string) (bool, int64, error) {
./1_archive/root_sh/step_408_fix_api_gateway_nethttp_full.sh:90:			TenantID: "tenant-001",
./1_archive/root_sh/step_408_fix_api_gateway_nethttp_full.sh:94:			TenantID: "tenant-002",
./1_archive/root_sh/step_408_fix_api_gateway_nethttp_full.sh:98:			TenantID: "",
./1_archive/root_sh/step_408_fix_api_gateway_nethttp_full.sh:168:		ctx := context.WithValue(r.Context(), tenantKey, tokenInfo.TenantID)
./1_archive/root_sh/step_408_fix_api_gateway_nethttp_full.sh:187:			ctx := context.WithValue(r.Context(), tenantKey, requestTenant)
./1_archive/root_sh/step_408_fix_api_gateway_nethttp_full.sh:206:			_, _ = w.Write([]byte("token tenant ve request tenant uyusmuyor"))
./1_archive/root_sh/step_417_fix_api_gateway_main.sh:26:const tenantKey contextKey = "tenant_id"
./1_archive/root_sh/step_417_fix_api_gateway_main.sh:37:	TenantID string
./1_archive/root_sh/step_417_fix_api_gateway_main.sh:54:func (rl *RedisRateLimiter) Allow(tenantID string, scope string) (bool, int64, error) {
./1_archive/root_sh/step_417_fix_api_gateway_main.sh:79:			TenantID: "tenant-001",
./1_archive/root_sh/step_417_fix_api_gateway_main.sh:83:			TenantID: "tenant-002",
./1_archive/root_sh/step_417_fix_api_gateway_main.sh:87:			TenantID: "",
./1_archive/root_sh/step_417_fix_api_gateway_main.sh:157:		ctx := context.WithValue(r.Context(), tenantKey, tokenInfo.TenantID)
./1_archive/root_sh/step_417_fix_api_gateway_main.sh:176:			ctx := context.WithValue(r.Context(), tenantKey, requestTenant)
./1_archive/root_sh/step_417_fix_api_gateway_main.sh:195:			_, _ = w.Write([]byte("token tenant ve request tenant uyusmuyor"))
./1_archive/root_sql/step_200_create_event_store_table.sql:7:    tenant_id TEXT,
./1_archive/root_sql/step_203_create_journal_tables.sql:4:    tenant_id TEXT,
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-5.7 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-5.8.1 request_id / correlation_id trace izi

Pattern:

```text
request_id|RequestID|X-Request-ID|correlation_id|CorrelationID|causation_id|CausationID|trace_id|TraceID
```

Match Count: 497

```text
./cmd/api-gateway/api_gateway_main.go:36:	RequestID     string            `json:"request_id"`
./cmd/api-gateway/api_gateway_main.go:37:	CorrelationID string            `json:"correlation_id"`
./cmd/api-gateway/api_gateway_main.go:70:	RequestID     string      `json:"request_id"`
./cmd/api-gateway/api_gateway_main.go:71:	CorrelationID string      `json:"correlation_id"`
./cmd/api-gateway/api_gateway_main.go:537:			"request_id":     requestIDFromContext(r.Context()),
./cmd/api-gateway/api_gateway_main.go:538:			"correlation_id": correlationIDFromContext(r.Context()),
./cmd/api-gateway/api_gateway_main.go:563:			"request_id":        requestIDFromContext(r.Context()),
./cmd/api-gateway/api_gateway_main.go:564:			"correlation_id":    correlationIDFromContext(r.Context()),
./cmd/api-gateway/api_gateway_main.go:582:			"request_id":     requestIDFromContext(r.Context()),
./cmd/api-gateway/api_gateway_main.go:583:			"correlation_id": correlationIDFromContext(r.Context()),
./cmd/api-gateway/api_gateway_main.go:603:			"request_id":     requestIDFromContext(r.Context()),
./cmd/api-gateway/api_gateway_main.go:604:			"correlation_id": correlationIDFromContext(r.Context()),
./cmd/api-gateway/api_gateway_main.go:616:			"request_id":     requestIDFromContext(r.Context()),
./cmd/api-gateway/api_gateway_main.go:617:			"correlation_id": correlationIDFromContext(r.Context()),
./cmd/api-gateway/api_gateway_main.go:633:			RequestID:     requestIDFromContext(r.Context()),
./cmd/api-gateway/api_gateway_main.go:634:			CorrelationID: correlationIDFromContext(r.Context()),
./cmd/api-gateway/api_gateway_main.go:662:			RequestID:     requestIDFromContext(r.Context()),
./cmd/api-gateway/api_gateway_main.go:663:			CorrelationID: correlationIDFromContext(r.Context()),
./cmd/api-gateway/api_gateway_main.go:676:			RequestID:     requestIDFromContext(r.Context()),
./cmd/api-gateway/api_gateway_main.go:677:			CorrelationID: correlationIDFromContext(r.Context()),
./cmd/api-gateway/api_gateway_main.go:688:			"request_id":     requestIDFromContext(r.Context()),
./cmd/api-gateway/api_gateway_main.go:689:			"correlation_id": correlationIDFromContext(r.Context()),
./cmd/api-gateway/api_gateway_main.go:713:			"request_id":     requestIDFromContext(r.Context()),
./cmd/api-gateway/api_gateway_main.go:714:			"correlation_id": correlationIDFromContext(r.Context()),
./cmd/api-gateway/api_gateway_main.go:779:			"request_id":     requestIDFromContext(r.Context()),
./cmd/api-gateway/api_gateway_main.go:780:			"correlation_id": correlationIDFromContext(r.Context()),
./cmd/api-gateway/api_gateway_main.go:829:			"request_id":     requestIDFromContext(r.Context()),
./cmd/api-gateway/api_gateway_main.go:830:			"correlation_id": correlationIDFromContext(r.Context()),
./cmd/api-gateway/api_gateway_main_test.go:30:	RequestID     string `json:"request_id"`
./cmd/api-gateway/api_gateway_main_test.go:31:	CorrelationID string `json:"correlation_id"`
./cmd/api-gateway/api_gateway_main_test.go:56:	RequestID     string                `json:"request_id"`
./cmd/api-gateway/api_gateway_main_test.go:57:	CorrelationID string                `json:"correlation_id"`
./cmd/api-gateway/api_gateway_main_test.go:173:	if rr.Header().Get("X-Request-ID") == "" {
./cmd/api-gateway/api_gateway_main_test.go:174:		t.Fatalf("response header X-Request-ID bos olmamali")
./cmd/api-gateway/api_gateway_main_test.go:204:	req.Header.Set("X-Request-ID", "req-manuel-001")
./cmd/api-gateway/api_gateway_main_test.go:210:	if rr.Header().Get("X-Request-ID") != "req-manuel-001" {
./cmd/api-gateway/api_gateway_main_test.go:211:		t.Fatalf("response X-Request-ID beklenen req-manuel-001")
./cmd/api-gateway/api_gateway_main_test.go:247:	if rr.Header().Get("X-Request-ID") == "" {
./cmd/api-gateway/api_gateway_main_test.go:305:	if body.RequestID == "" || body.CorrelationID == "" {
./cmd/api-gateway/api_gateway_main_test.go:565:	if body.RequestID == "" || body.CorrelationID == "" {
./cmd/api-gateway/api_gateway_main_test.go:692:	if body.RequestID == "" || body.CorrelationID == "" {
./cmd/api-gateway/api_gateway_main_test.go:762:	ctx = context.WithValue(ctx, gatewayRequestIDKey, requestID)
./cmd/api-gateway/api_gateway_main_test.go:763:	ctx = context.WithValue(ctx, gatewayCorrelationIDKey, correlationID)
./cmd/api-gateway/erp_runtime_mount_test.go:34:		RequestID: req.RequestID,
./cmd/api-gateway/erp_runtime_mount_test.go:54:		RequestID: "req-gateway-erp-runtime",
./cmd/api-gateway/erp_runtime_mount_test.go:73:		CorrelationID:  "corr-gateway-erp-runtime",
./cmd/api-gateway/erp_runtime_protected_endpoint_smoke_test.go:50:	apiReq.RequestID = "req-gw-protected-" + unique
./cmd/api-gateway/erp_runtime_protected_endpoint_smoke_test.go:61:	apiReq.CorrelationID = "corr-gw-protected-" + unique
./cmd/api-gateway/erp_runtime_protected_endpoint_smoke_test.go:71:	req.Header.Set("X-Request-ID", apiReq.RequestID)
./cmd/api-gateway/erp_runtime_protected_endpoint_smoke_test.go:131:	req.Header.Set("X-Request-ID", "req-missing-bearer")
./cmd/api-gateway/erp_runtime_protected_endpoint_smoke_test.go:161:	req.Header.Set("X-Request-ID", "req-tenant-mismatch")
./cmd/api-gateway/erp_runtime_protected_endpoint_smoke_test.go:186:	req.Header.Set("X-Request-ID", "req-wrong-method")
./cmd/api-gateway/erp_runtime_service_factory_test.go:83:	req.RequestID = "req-gateway-factory-" + unique
./cmd/api-gateway/erp_runtime_service_factory_test.go:86:	req.CorrelationID = "corr-gateway-factory-" + unique
./cmd/api-gateway/gateway_middleware.go:33:	gatewayRequestIDKey     gatewayContextKey = "gateway_request_id"
./cmd/api-gateway/gateway_middleware.go:34:	gatewayCorrelationIDKey gatewayContextKey = "gateway_correlation_id"
./cmd/api-gateway/gateway_middleware.go:119:	ctx = context.WithValue(ctx, gatewayRequestIDKey, requestID)
./cmd/api-gateway/gateway_middleware.go:120:	ctx = context.WithValue(ctx, gatewayCorrelationIDKey, correlationID)
./cmd/api-gateway/gateway_middleware.go:125:	val, _ := ctx.Value(gatewayRequestIDKey).(string)
./cmd/api-gateway/gateway_middleware.go:130:	val, _ := ctx.Value(gatewayCorrelationIDKey).(string)
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-5.8.1 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-5.8.2 log standard / structured logging izi

Pattern:

```text
logger|Logger|log\.Printf|zap|zerolog|logrus|slog|service_name|duration_ms|error_code|audit
```

Match Count: 817

```text
./1_archive/root_sh/create_erp_structure.sh:14:mkdir -p $BASE/core/audit
./1_archive/root_sh/step_190_reporting_subscriber_kur_ve_calistir.sh:75:				log.Printf("PARSE HATA | subject=%s | err=%v", msg.Subject, err)
./1_archive/root_sh/step_190_reporting_subscriber_kur_ve_calistir.sh:77:					log.Printf("ACK HATA | subject=%s | err=%v", msg.Subject, ackErr)
./1_archive/root_sh/step_190_reporting_subscriber_kur_ve_calistir.sh:85:				log.Printf("ACK HATA | subject=%s | err=%v", msg.Subject, ackErr)
./1_archive/root_sh/step_190_reporting_subscriber_kur_ve_calistir.sh:93:			log.Printf("SKIP | subject=%s | err=%v", subject, err)
./1_archive/root_sh/step_191_reporting_service_arka_plan_panel.sh:76:			log.Printf("PARSE HATA | subject=%s | err=%v", msg.Subject, err)
./1_archive/root_sh/step_191_reporting_service_arka_plan_panel.sh:78:				log.Printf("ACK HATA | subject=%s | err=%v", msg.Subject, ackErr)
./1_archive/root_sh/step_191_reporting_service_arka_plan_panel.sh:86:			log.Printf("ACK HATA | subject=%s | err=%v", msg.Subject, ackErr)
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:171:			log.Printf("register parse hatasi: %v", err)
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:175:			log.Printf("register eksik alan")
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:179:		log.Printf("OK ✅ NATS register | name=%s | address=%s", req.Name, req.Address)
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:188:			log.Printf("heartbeat parse hatasi: %v", err)
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:192:			log.Printf("heartbeat name bos")
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:197:			log.Printf("OK ✅ NATS heartbeat | name=%s", req.Name)
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:199:			log.Printf("UYARI ⚠ heartbeat geldi ama servis yok | name=%s", req.Name)
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:287:	log.Printf("OK ✅ hybrid service_discovery started | port=%s | nats=%s", port, natsURL)
./1_archive/root_sh/step_202_query_read_model_kur_ve_test_et.sh:185:			log.Printf("UYARI ⚠ read model dosya yukleme hatasi: %v", err)
./1_archive/root_sh/step_202_query_read_model_kur_ve_test_et.sh:259:	log.Printf("OK ✅ query_read_model started | port=%s | file=%s", port, dataPath)
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:194:			log.Printf("UYARI ⚠ read model dosya yukleme hatasi: %v", err)
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:300:	log.Printf("OK ✅ query_read_model started | port=%s | file=%s", port, dataPath)
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:490:			log.Printf("PARSE HATA | subject=%s | err=%v", msg.Subject, err)
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:495:		log.Printf("REPORT EVENT | subject=%s | type=%s", msg.Subject, e.Type)
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:499:				log.Printf("QUERY READ MODEL PUSH HATA | order_id=%s | err=%v", sale.OrderID, err)
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:501:				log.Printf("OK ✅ query_read_model upsert | order_id=%s", sale.OrderID)
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:506:			log.Printf("ACK HATA | subject=%s | err=%v", msg.Subject, err)
./1_archive/root_sh/step_210_audit_full.sh:6:mkdir -p $BASE/internal/platform/audit
./1_archive/root_sh/step_210_audit_full.sh:9:cat <<'GOEOF' > $BASE/internal/platform/audit/audit_engine.go
./1_archive/root_sh/step_210_audit_full.sh:10:package audit
./1_archive/root_sh/step_210_audit_full.sh:64:cat <<'GOEOF' > $BASE/internal/platform/audit/audit_engine_test.go
./1_archive/root_sh/step_210_audit_full.sh:65:package audit
./1_archive/root_sh/step_210_audit_full.sh:112:go test ./internal/platform/audit -v
./1_archive/root_sh/step_210_audit_full.sh:114:echo "OK ✅ audit FULL tamam"
./1_archive/root_sh/step_210_prepare_audit_folder.sh:4:mkdir -p ~/pix2pi/pix2pi-SaaS/internal/platform/audit
./1_archive/root_sh/step_210_prepare_audit_folder.sh:6:echo "OK ✅ audit klasoru hazir"
./1_archive/root_sh/step_211_test_audit_engine.sh:6:go test ./internal/platform/audit -v
./1_archive/root_sh/step_211_test_audit_engine.sh:8:echo "OK ✅ audit test bitti"
./1_archive/root_sh/step_260_audit_schema.sh:6:cat <<'SQLEOF' > step_260_create_audit_tables.sql
./1_archive/root_sh/step_260_audit_schema.sh:7:CREATE TABLE IF NOT EXISTS audit_logs (
./1_archive/root_sh/step_260_audit_schema.sh:20:CREATE INDEX IF NOT EXISTS idx_audit_logs_tenant_created
./1_archive/root_sh/step_260_audit_schema.sh:21:ON audit_logs (tenant_id, created_at DESC);
./1_archive/root_sh/step_260_audit_schema.sh:23:CREATE INDEX IF NOT EXISTS idx_audit_logs_action
./1_archive/root_sh/step_260_audit_schema.sh:24:ON audit_logs (action);
./1_archive/root_sh/step_260_audit_schema.sh:26:CREATE INDEX IF NOT EXISTS idx_audit_logs_entity
./1_archive/root_sh/step_260_audit_schema.sh:27:ON audit_logs (entity_type, entity_id);
./1_archive/root_sh/step_260_audit_schema.sh:30:PGPASSWORD=***MASKED***
./1_archive/root_sh/step_260_audit_schema.sh:32:echo "OK ✅ audit schema hazir"
./1_archive/root_sh/step_261_audit_full.sh:6:mkdir -p $BASE/internal/platform/auditlog
./1_archive/root_sh/step_261_audit_full.sh:8:cat <<'GOEOF' > $BASE/internal/platform/auditlog/auditlog.go
./1_archive/root_sh/step_261_audit_full.sh:9:package auditlog
./1_archive/root_sh/step_261_audit_full.sh:42:		INSERT INTO audit_logs (
./1_archive/root_sh/step_261_audit_full.sh:68:cat <<'GOEOF' > $BASE/internal/platform/auditlog/auditlog_test.go
./1_archive/root_sh/step_261_audit_full.sh:69:package auditlog
./1_archive/root_sh/step_261_audit_full.sh:95:		TenantID:   "tenant-audit-test",
./1_archive/root_sh/step_261_audit_full.sh:108:		t.Fatalf("audit write hatasi: %v", err)
./1_archive/root_sh/step_261_audit_full.sh:114:		FROM audit_logs
./1_archive/root_sh/step_261_audit_full.sh:115:		WHERE tenant_id = 'tenant-audit-test'
./1_archive/root_sh/step_261_audit_full.sh:120:		t.Fatalf("audit read hatasi: %v", err)
./1_archive/root_sh/step_261_audit_full.sh:124:		t.Fatalf("audit kaydi bulunamadi")
./1_archive/root_sh/step_261_audit_full.sh:130:PIX2PI_DB_TEST=1 go test ./internal/platform/auditlog -v
./1_archive/root_sh/step_261_audit_full.sh:132:echo "OK ✅ audit log engine hazir"
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-5.8.2 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-5.9 SRE dashboard / ops panel izi

Pattern:

```text
SRE|sre|ops.*dashboard|dashboard.*ops|mission.*control|service.*status|incident|runbook|alarm|alert
```

Match Count: 1030

```text
./1_archive/root_sh/step_185_create_service_status_snapshot_script.sh:8:DOSYA="/opt/pix2pi/nginx/service_status.json"
./1_archive/root_sh/step_185_create_service_status_snapshot_script.sh:90:echo "OK ✅ service status json guncellendi"
./1_archive/root_sh/step_186_rewrite_panel_with_service_monitor.sh:58:        const res = await fetch("/service_status.json?_=" + Date.now());
./1_archive/root_sh/step_187_create_service_status_cron.sh:4:cat <<'CRON' > /etc/cron.d/pix2pi_service_status
./1_archive/root_sh/step_187_create_service_status_cron.sh:13:chmod 644 /etc/cron.d/pix2pi_service_status
./1_archive/root_sh/step_187_create_service_status_cron.sh:16:echo "OK ✅ service status cron aktif"
./1_archive/root_sh/step_188_verify_done_items.sh:136:if [ -f "/etc/cron.d/pix2pi_service_status" ]; then
./1_archive/root_sh/step_191_reporting_service_arka_plan_panel.sh:14:status_script="/usr/local/bin/pix2pi_reporting_service_status.sh"
./1_archive/root_sh/step_191_reporting_service_arka_plan_panel.sh:251:        data["services"]["reporting_service"] = reporting_status
./1_archive/root_sh/step_191_reporting_service_arka_plan_panel.sh:253:        data["reporting_service"] = reporting_status
./1_archive/root_sh/step_192_reporting_service_panelde_goster.sh:145:echo "6) En guncel service status json dosyasi bulunuyor..."
./1_archive/root_sh/step_192_reporting_service_panelde_goster.sh:170:  echo "UYARI ⚠ service status json bulunamadi"
./1_archive/root_sh/step_195_panel_veri_kaynagini_bul_ve_reporting_ekle.sh:28:  "fetch|xmlhttprequest|service|json|api|monitor|status|health|script src|server monitor" \
./1_archive/root_sh/step_195_panel_veri_kaynagini_bul_ve_reporting_ekle.sh:41:echo "6) reporting_service status json dosyasina zorla yaziliyor..."
./1_archive/root_sh/step_195_panel_veri_kaynagini_bul_ve_reporting_ekle.sh:63:  echo "UYARI ⚠ service status json bulunamadi"
./1_archive/root_sh/step_196_reporting_service_ayaga_kaldir_ve_kalici_yap.sh:11:status_script="/usr/local/bin/pix2pi_reporting_service_status.sh"
./1_archive/root_sh/step_196_reporting_service_ayaga_kaldir_ve_kalici_yap.sh:127:status_script="/usr/local/bin/pix2pi_reporting_service_status.sh"
./1_archive/root_sh/step_197_reporting_unknown_kaynaagini_bul_ve_duzelt.sh:38:echo "6) En guncel service status json bulunuyor..."
./1_archive/root_sh/step_197_reporting_unknown_kaynaagini_bul_ve_duzelt.sh:76:echo "8) reporting_service status mapping snapshot scriptine ekleniyor..."
./1_archive/root_sh/step_197_reporting_unknown_kaynaagini_bul_ve_duzelt.sh:84:if /usr/local/bin/pix2pi_reporting_service_status.sh >/dev/null 2>&1; then
./1_archive/root_sh/step_197_reporting_unknown_kaynaagini_bul_ve_duzelt.sh:113:    data["services"]["reporting_service"] = reporting_status
./1_archive/root_sh/step_197_reporting_unknown_kaynaagini_bul_ve_duzelt.sh:167:echo "OK ✅ servis calisiyor mu: /usr/local/bin/pix2pi_reporting_service_status.sh"
./1_archive/root_sh/step_198_reporting_service_json_sabitle.sh:8:json_dosya="/opt/pix2pi/nginx/service_status.json"
./1_archive/root_sh/step_198_reporting_service_json_sabitle.sh:10:status_script="/usr/local/bin/pix2pi_reporting_service_status.sh"
./1_archive/root_sh/step_198_reporting_service_json_sabitle.sh:34:cp "$json_dosya" "$yedek_dizini/service_status.json.$zaman.bak"
./1_archive/root_sh/step_198_reporting_service_json_sabitle.sh:48:echo "4) service_status.json dogrudan guncelleniyor..."
./1_archive/root_sh/step_198_reporting_service_json_sabitle.sh:73:data["services"]["reporting_service"]["durum"] = reporting_status
./1_archive/root_sh/step_198_reporting_service_json_sabitle.sh:99:sabit_json_dosya="/opt/pix2pi/nginx/service_status.json"
./1_archive/root_sh/step_198_reporting_service_json_sabitle.sh:101:if /usr/local/bin/pix2pi_reporting_service_status.sh >/dev/null 2>&1; then
./1_archive/root_sh/step_198_reporting_service_json_sabitle.sh:125:data["services"]["reporting_service"]["durum"] = reporting_status
./1_archive/root_sh/step_199_fix_panel_reporting_service.sh:99:        const res = await fetch("/service_status.json?_=" + Date.now());
./1_archive/root_sh/step_201_hybrid_service_discovery_kur.sh:15:status_script="/usr/local/bin/pix2pi_service_discovery_status.sh"
./1_archive/root_sh/step_203_reporting_to_query_read_model_bagla.sh:25:reporting_status="/usr/local/bin/pix2pi_reporting_service_status.sh"
./1_archive/root_sh/step_204_panel_service_discovery_query_read_model_ekle.sh:9:json_dosya="/opt/pix2pi/nginx/service_status.json"
./1_archive/root_sh/step_204_panel_service_discovery_query_read_model_ekle.sh:12:service_discovery_status="/usr/local/bin/pix2pi_service_discovery_status.sh"
./1_archive/root_sh/step_204_panel_service_discovery_query_read_model_ekle.sh:14:reporting_status="/usr/local/bin/pix2pi_reporting_service_status.sh"
./1_archive/root_sh/step_204_panel_service_discovery_query_read_model_ekle.sh:19:for f in "$panel_dosya" "$json_dosya" "$snapshot_script" "$service_discovery_status" "$query_read_model_status"; do
./1_archive/root_sh/step_204_panel_service_discovery_query_read_model_ekle.sh:30:cp "$json_dosya" "$yedek_klasor/service_status.json.$zaman.bak"
./1_archive/root_sh/step_204_panel_service_discovery_query_read_model_ekle.sh:106:        const res = await fetch("/service_status.json?_=" + Date.now());
./1_archive/root_sh/step_204_panel_service_discovery_query_read_model_ekle.sh:176:service_discovery_status_value="STOPPED"
./1_archive/root_sh/step_204_panel_service_discovery_query_read_model_ekle.sh:180:if [ -x /usr/local/bin/pix2pi_service_discovery_status.sh ] && /usr/local/bin/pix2pi_service_discovery_status.sh >/dev/null 2>&1; then
./1_archive/root_sh/step_204_panel_service_discovery_query_read_model_ekle.sh:181:  service_discovery_status_value="RUNNING"
./1_archive/root_sh/step_204_panel_service_discovery_query_read_model_ekle.sh:188:if [ -x /usr/local/bin/pix2pi_reporting_service_status.sh ] && /usr/local/bin/pix2pi_reporting_service_status.sh >/dev/null 2>&1; then
./1_archive/root_sh/step_204_panel_service_discovery_query_read_model_ekle.sh:192:sabit_json_dosya="/opt/pix2pi/nginx/service_status.json"
./1_archive/root_sh/step_204_panel_service_discovery_query_read_model_ekle.sh:194:  python3 - "$sabit_json_dosya" "$reporting_status_value" "$service_discovery_status_value" "$query_read_model_status_value" <<'PYEOF'
./1_archive/root_sh/step_204_panel_service_discovery_query_read_model_ekle.sh:201:service_discovery_status = sys.argv[3]
./1_archive/root_sh/step_204_panel_service_discovery_query_read_model_ekle.sh:226:data["services"]["reporting_service"]["durum"] = reporting_status
./1_archive/root_sh/step_204_panel_service_discovery_query_read_model_ekle.sh:227:data["services"]["service_discovery"]["durum"] = service_discovery_status
./1_archive/root_sh/step_204_panel_service_discovery_query_read_model_ekle.sh:228:data["services"]["query_read_model"]["durum"] = query_read_model_status
./1_archive/root_sh/step_204_panel_service_discovery_query_read_model_ekle.sh:253:echo "5) service_status.json dogrudan guncelleniyor..."
./1_archive/root_sh/step_204_panel_service_discovery_query_read_model_ekle.sh:261:if "$service_discovery_status" >/dev/null 2>&1; then
./1_archive/root_sh/step_204_panel_service_discovery_query_read_model_ekle.sh:275:service_discovery_status = sys.argv[3]
./1_archive/root_sh/step_204_panel_service_discovery_query_read_model_ekle.sh:297:data["services"]["reporting_service"]["durum"] = reporting_status
./1_archive/root_sh/step_204_panel_service_discovery_query_read_model_ekle.sh:298:data["services"]["service_discovery"]["durum"] = service_discovery_status
./1_archive/root_sh/step_204_panel_service_discovery_query_read_model_ekle.sh:299:data["services"]["query_read_model"]["durum"] = query_read_model_status
./1_archive/root_sh/step_205_fix_snapshot_process_bazli.sh:7:json_dosya="/opt/pix2pi/nginx/service_status.json"
./1_archive/root_sh/step_205_fix_snapshot_process_bazli.sh:29:json_dosya="/opt/pix2pi/nginx/service_status.json"
./1_archive/root_sh/step_205_fix_snapshot_process_bazli.sh:109:echo "OK ✅ service status json guncellendi"
./1_archive/root_sh/step_22_check_postgres_rls_env.sh:31:echo "=== 5 PG ISREADY KONTROL ==="
./1_archive/root_sh/step_22_check_postgres_rls_env.sh:32:if command -v pg_isready >/dev/null 2>&1; then
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-5.9 STATUS=IMPLEMENTED_OR_PRESENT ✅

## 6-5.10 Observability test / audit script izi

Pattern:

```text
observability|prometheus|grafana|metrics|health.*probe|runtime.*audit|real.*implementation.*audit
```

Match Count: 1347

```text
./1_archive/root_sh/step_270_observability_stack.sh:5:OBS=$BASE/infra/observability
./1_archive/root_sh/step_270_observability_stack.sh:7:mkdir -p $OBS/prometheus
./1_archive/root_sh/step_270_observability_stack.sh:10:mkdir -p $OBS/grafana/provisioning/datasources
./1_archive/root_sh/step_270_observability_stack.sh:11:mkdir -p $OBS/grafana/provisioning/dashboards
./1_archive/root_sh/step_270_observability_stack.sh:12:mkdir -p $OBS/grafana/dashboards
./1_archive/root_sh/step_270_observability_stack.sh:18:  prometheus:
./1_archive/root_sh/step_270_observability_stack.sh:19:    image: prom/prometheus:latest
./1_archive/root_sh/step_270_observability_stack.sh:20:    container_name: pix2pi_prometheus
./1_archive/root_sh/step_270_observability_stack.sh:23:      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
./1_archive/root_sh/step_270_observability_stack.sh:27:      - pix2pi_observability
./1_archive/root_sh/step_270_observability_stack.sh:30:    image: grafana/loki:2.9.8
./1_archive/root_sh/step_270_observability_stack.sh:39:      - pix2pi_observability
./1_archive/root_sh/step_270_observability_stack.sh:42:    image: grafana/promtail:2.9.8
./1_archive/root_sh/step_270_observability_stack.sh:53:      - pix2pi_observability
./1_archive/root_sh/step_270_observability_stack.sh:55:  grafana:
./1_archive/root_sh/step_270_observability_stack.sh:56:    image: grafana/grafana:latest
./1_archive/root_sh/step_270_observability_stack.sh:57:    container_name: pix2pi_grafana
./1_archive/root_sh/step_270_observability_stack.sh:64:      - ./grafana/provisioning:/etc/grafana/provisioning:ro
./1_archive/root_sh/step_270_observability_stack.sh:65:      - ./grafana/dashboards:/var/lib/grafana/dashboards:ro
./1_archive/root_sh/step_270_observability_stack.sh:69:      - prometheus
./1_archive/root_sh/step_270_observability_stack.sh:72:      - pix2pi_observability
./1_archive/root_sh/step_270_observability_stack.sh:86:      - pix2pi_observability
./1_archive/root_sh/step_270_observability_stack.sh:89:  pix2pi_observability:
./1_archive/root_sh/step_270_observability_stack.sh:93:cat <<'YAMLEOF' > $OBS/prometheus/prometheus.yml
./1_archive/root_sh/step_270_observability_stack.sh:98:  - job_name: "prometheus"
./1_archive/root_sh/step_270_observability_stack.sh:100:      - targets: ["prometheus:9090"]
./1_archive/root_sh/step_270_observability_stack.sh:169:cat <<'YAMLEOF' > $OBS/grafana/provisioning/datasources/datasources.yml
./1_archive/root_sh/step_270_observability_stack.sh:174:    type: prometheus
./1_archive/root_sh/step_270_observability_stack.sh:176:    url: http://prometheus:9090
./1_archive/root_sh/step_270_observability_stack.sh:185:cat <<'YAMLEOF' > $OBS/grafana/provisioning/dashboards/dashboards.yml
./1_archive/root_sh/step_270_observability_stack.sh:196:      path: /var/lib/grafana/dashboards
./1_archive/root_sh/step_270_observability_stack.sh:199:cat <<'JSONEOF' > $OBS/grafana/dashboards/pix2pi-overview.json
./1_archive/root_sh/step_270_observability_stack.sh:212:        "type": "prometheus",
./1_archive/root_sh/step_270_observability_stack.sh:243:        "type": "prometheus",
./1_archive/root_sh/step_270_observability_stack.sh:285:echo "OK ✅ observability dosyalari hazir"
./1_archive/root_sh/step_271_run_observability_stack.sh:4:cd ~/pix2pi/pix2pi-SaaS/infra/observability
./1_archive/root_sh/step_271_run_observability_stack.sh:13:echo "OK ✅ observability stack ayakta"
./1_archive/root_sh/step_272_test_observability_stack.sh:23:echo "OK ✅ observability test bitti"
./1_archive/root_sh/step_273_fix_promtail_positions.sh:5:OBS=$BASE/infra/observability
./1_archive/root_sh/step_273_fix_promtail_positions.sh:42:  prometheus:
./1_archive/root_sh/step_273_fix_promtail_positions.sh:43:    image: prom/prometheus:latest
./1_archive/root_sh/step_273_fix_promtail_positions.sh:44:    container_name: pix2pi_prometheus
./1_archive/root_sh/step_273_fix_promtail_positions.sh:47:      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
./1_archive/root_sh/step_273_fix_promtail_positions.sh:51:      - pix2pi_observability
./1_archive/root_sh/step_273_fix_promtail_positions.sh:54:    image: grafana/loki:2.9.8
./1_archive/root_sh/step_273_fix_promtail_positions.sh:63:      - pix2pi_observability
./1_archive/root_sh/step_273_fix_promtail_positions.sh:66:    image: grafana/promtail:2.9.8
./1_archive/root_sh/step_273_fix_promtail_positions.sh:78:      - pix2pi_observability
./1_archive/root_sh/step_273_fix_promtail_positions.sh:80:  grafana:
./1_archive/root_sh/step_273_fix_promtail_positions.sh:81:    image: grafana/grafana:latest
./1_archive/root_sh/step_273_fix_promtail_positions.sh:82:    container_name: pix2pi_grafana
./1_archive/root_sh/step_273_fix_promtail_positions.sh:89:      - ./grafana/provisioning:/etc/grafana/provisioning:ro
./1_archive/root_sh/step_273_fix_promtail_positions.sh:90:      - ./grafana/dashboards:/var/lib/grafana/dashboards:ro
./1_archive/root_sh/step_273_fix_promtail_positions.sh:94:      - prometheus
./1_archive/root_sh/step_273_fix_promtail_positions.sh:97:      - pix2pi_observability
./1_archive/root_sh/step_273_fix_promtail_positions.sh:111:      - pix2pi_observability
./1_archive/root_sh/step_273_fix_promtail_positions.sh:114:  pix2pi_observability:
./1_archive/root_sh/step_274_restart_observability.sh:4:cd ~/pix2pi/pix2pi-SaaS/infra/observability
./1_archive/root_sh/step_274_restart_observability.sh:13:echo "OK ✅ observability restart bitti"
./1_archive/root_sh/step_275_test_promtail_positions.sh:9:ls -lah ~/pix2pi/pix2pi-SaaS/infra/observability/promtail/data || true
```

Status: IMPLEMENTED_OR_PRESENT ✅
6-5.10 STATUS=IMPLEMENTED_OR_PRESENT ✅

# Final Runtime Implementation Interpretation

```text
REQUIRED_FAIL=0
OPTIONAL_WARN=0
FAZ_6_5_RUNTIME_REQUIRED_IMPLEMENTATION_STATUS=PASS ✅
FAZ_6_5_RUNTIME_OPTIONAL_IMPLEMENTATION_STATUS=PASS ✅
FAZ_6_5_REAL_IMPLEMENTATION_STATUS=PASS ✅
FAZ_6_6_READY=YES ✅
FAZ_6_5_REAL_IMPLEMENTATION_AUDIT=COMPLETE ✅
```
