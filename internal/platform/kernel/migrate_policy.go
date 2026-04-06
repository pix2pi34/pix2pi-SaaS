package kernel

import (
	"fmt"

	"gorm.io/gorm"
)

// EnsurePolicyRulesTable: tenant schema içinde policy_rules tablosunu garanti eder.
// NOT: GORM AutoMigrate yerine direkt SQL kullanıyoruz (daha deterministik).
func EnsurePolicyRulesTable(db *gorm.DB, schema string) error {
	if schema == "" {
		return fmt.Errorf("schema empty")
	}

	sql := fmt.Sprintf(`
CREATE TABLE IF NOT EXISTS %s.policy_rules (
  id BIGSERIAL PRIMARY KEY,
  route VARCHAR(200) NOT NULL,
  role  VARCHAR(50)  NOT NULL,
  allow BOOLEAN      NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_policy_rules_route ON %s.policy_rules(route);
CREATE INDEX IF NOT EXISTS idx_policy_rules_role  ON %s.policy_rules(role);
`, schema, schema, schema)

	return db.Exec(sql).Error
}
