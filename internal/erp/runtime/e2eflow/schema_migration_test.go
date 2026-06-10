package e2eflow

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

const e2eFlowMigrationUpRelativePath = "db/migrations/20260426_111001_erp_runtime_e2e_flow.up.sql"
const e2eFlowMigrationDownRelativePath = "db/migrations/20260426_111001_erp_runtime_e2e_flow.down.sql"

func TestE2EFlowMigrationContract(t *testing.T) {
	root := findRepoRootForE2EFlowMigrationTest(t)

	up, err := os.ReadFile(filepath.Join(root, e2eFlowMigrationUpRelativePath))
	if err != nil {
		t.Fatalf("read migration up: %v", err)
	}

	content := string(up)

	requiredSnippets := []string{
		"CREATE TABLE IF NOT EXISTS erp_runtime_flows",
		"CREATE TABLE IF NOT EXISTS erp_runtime_flow_steps",
		"flow_id uuid PRIMARY KEY DEFAULT gen_random_uuid()",
		"tenant_id text NOT NULL",
		"request_id text NOT NULL",
		"transaction_kind text NOT NULL",
		"source_module text NOT NULL",
		"source_document_type text NOT NULL",
		"total_amount numeric(18, 2) NOT NULL",
		"currency_code text NOT NULL DEFAULT 'TRY'",
		"exchange_rate numeric(18, 6) NOT NULL DEFAULT 1",
		"idempotency_key text NOT NULL",
		"flow_status text NOT NULL DEFAULT 'draft'",
		"step_kind text NOT NULL",
		"step_status text NOT NULL DEFAULT 'pending'",
		"REFERENCES erp_runtime_flows(flow_id) ON DELETE CASCADE",
		"ALTER TABLE erp_runtime_flows ENABLE ROW LEVEL SECURITY",
		"ALTER TABLE erp_runtime_flows FORCE ROW LEVEL SECURITY",
		"ALTER TABLE erp_runtime_flow_steps ENABLE ROW LEVEL SECURITY",
		"ALTER TABLE erp_runtime_flow_steps FORCE ROW LEVEL SECURITY",
		"CREATE POLICY erp_runtime_flows_tenant_isolation",
		"CREATE POLICY erp_runtime_flow_steps_tenant_isolation",
		"tenant_id = current_setting('app.tenant_id', true)",
	}

	for _, snippet := range requiredSnippets {
		if !strings.Contains(content, snippet) {
			t.Fatalf("migration up missing snippet: %s", snippet)
		}
	}

	down, err := os.ReadFile(filepath.Join(root, e2eFlowMigrationDownRelativePath))
	if err != nil {
		t.Fatalf("read migration down: %v", err)
	}

	downContent := string(down)

	requiredDownSnippets := []string{
		"DROP TABLE IF EXISTS erp_runtime_flow_steps",
		"DROP TABLE IF EXISTS erp_runtime_flows",
	}

	for _, snippet := range requiredDownSnippets {
		if !strings.Contains(downContent, snippet) {
			t.Fatalf("migration down missing snippet: %s", snippet)
		}
	}
}

func findRepoRootForE2EFlowMigrationTest(t *testing.T) string {
	t.Helper()

	wd, err := os.Getwd()
	if err != nil {
		t.Fatalf("get working directory: %v", err)
	}

	current := wd

	for i := 0; i < 8; i++ {
		candidate := filepath.Join(current, "go.mod")
		if _, err := os.Stat(candidate); err == nil {
			return current
		}

		parent := filepath.Dir(current)
		if parent == current {
			break
		}

		current = parent
	}

	t.Fatalf("repo root bulunamadi, working_dir=%s", wd)
	return ""
}
