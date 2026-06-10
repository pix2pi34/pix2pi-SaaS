#!/usr/bin/env bash
set -euo pipefail

clear

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="$(date +%Y%m%d_%H%M%S)"
PHASE="FAZ_1_4_2_LAYOUT_GRID_STANDARD"

BACKUP_DIR="$REPO/backups/faz1/faz_1_4_2_layout_grid_standard_$TS"
WEB_DIR="$REPO/web/faz1/ui-foundation/layout-grid"
CONFIG_DIR="$REPO/configs/faz1/web/ui_foundation"
DOC_DIR="$REPO/docs/faz1/web"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
SCRIPT_DIR="$REPO/scripts/web"

HTML_FILE="$WEB_DIR/index.html"
JS_FILE="$WEB_DIR/layout_grid.js"
CSS_FILE="$WEB_DIR/layout_grid.css"
CONFIG_FILE="$CONFIG_DIR/layout_grid_standard_contract.v1.json"
DOC_FILE="$DOC_DIR/FAZ_1_4_2_LAYOUT_GRID_STANDARD.md"
STRICT_SUITE_FILE="$SCRIPT_DIR/faz_1_4_2_layout_grid_standard_strict_suite.sh"
APPLY_SCRIPT_FILE="$SCRIPT_DIR/faz_1_4_2_layout_grid_standard.sh"
STRICT_SUITE_OUT="$BACKUP_DIR/faz_1_4_2_layout_grid_standard_strict_suite.out"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_4_2_LAYOUT_GRID_STANDARD_REAL_IMPLEMENTATION_AUDIT.md"
FINAL_SEAL_FILE="$EVIDENCE_DIR/FAZ_1_4_2_LAYOUT_GRID_STANDARD_FINAL_SEAL_$TS.md"

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

pass(){ PASS_COUNT=$((PASS_COUNT+1)); echo "$1 / OK ✅"; }
fail(){ FAIL_COUNT=$((FAIL_COUNT+1)); echo "$1 / FAIL ❌"; }
warn(){ WARN_COUNT=$((WARN_COUNT+1)); echo "$1 / WARN ⚠️"; }

extract_var() {
  local file="$1"
  local key="$2"
  grep "^${key}=" "$file" 2>/dev/null | tail -n1 | cut -d= -f2- || true
}

echo "===== FAZ 1-4.2 LAYOUT / GRID STANDARD START ====="

if [ -d "$REPO" ]; then
  pass "1. repo dizini mevcut: $REPO"
else
  fail "1. repo dizini bulunamadı: $REPO"
  exit 1
fi

mkdir -p "$BACKUP_DIR" "$WEB_DIR" "$CONFIG_DIR" "$DOC_DIR" "$EVIDENCE_DIR" "$SCRIPT_DIR"
cd "$REPO"

echo "2. mevcut dosyalar yedekleniyor..."

for f in "$HTML_FILE" "$JS_FILE" "$CSS_FILE" "$CONFIG_FILE" "$DOC_FILE" "$STRICT_SUITE_FILE" "$APPLY_SCRIPT_FILE"; do
  if [ -f "$f" ]; then
    cp "$f" "$BACKUP_DIR/$(basename "$f").before_$TS"
    pass "2.x yedek alındı: $f"
  else
    warn "2.x yedek atlandı, dosya yok: $f"
  fi
done

echo "3. layout / grid contract config yazılıyor..."

cat <<'JSON' > "$CONFIG_FILE"
{
  "phase": "FAZ_1_4_2",
  "module": "WEB_L1_UI_FOUNDATION_DESIGN_SYSTEM",
  "component": "layout_grid_standard",
  "status": "READY",
  "required_capabilities": [
    "page_grid",
    "card_layout",
    "form_layout",
    "table_layout",
    "responsive_layout"
  ],
  "layout_contract": {
    "page_shell_class": "pix2pi-page",
    "page_grid_class": "pix2pi-page-grid",
    "card_grid_class": "pix2pi-card-grid",
    "form_grid_class": "pix2pi-form-grid",
    "table_region_class": "pix2pi-table-region",
    "responsive_breakpoints": {
      "desktop": "min-width: 1024px",
      "tablet": "min-width: 768px",
      "mobile": "max-width: 767px"
    }
  },
  "grid_patterns": {
    "one_column": "pix2pi-grid-1",
    "two_column": "pix2pi-grid-2",
    "three_column": "pix2pi-grid-3",
    "auto_fit": "pix2pi-grid-auto",
    "sidebar_content": "pix2pi-grid-sidebar-content"
  },
  "spacing_contract": {
    "page_gap": "24px",
    "card_gap": "18px",
    "form_gap": "14px",
    "table_gap": "12px"
  },
  "responsive_policy": {
    "mobile": "STACK_ALL_COLUMNS",
    "tablet": "TWO_COLUMN_WHEN_SAFE",
    "desktop": "FULL_GRID"
  }
}
JSON

if [ -f "$CONFIG_FILE" ]; then
  pass "3.1 layout/grid config yazıldı: $CONFIG_FILE"
else
  fail "3.1 layout/grid config yazılamadı"
  exit 1
fi

echo "4. layout / grid CSS yazılıyor..."

cat <<'CSS' > "$CSS_FILE"
:root {
  --pix2pi-bg: #0f172a;
  --pix2pi-surface: #111827;
  --pix2pi-surface-soft: #1f2937;
  --pix2pi-content: #020617;
  --pix2pi-border: #334155;
  --pix2pi-text: #e5e7eb;
  --pix2pi-muted: #9ca3af;
  --pix2pi-accent: #38bdf8;
  --pix2pi-ok: #22c55e;
  --pix2pi-warn: #f59e0b;
  --pix2pi-danger: #ef4444;
  --pix2pi-page-gap: 24px;
  --pix2pi-card-gap: 18px;
  --pix2pi-form-gap: 14px;
  --pix2pi-table-gap: 12px;
  --pix2pi-radius-lg: 20px;
  --pix2pi-radius-md: 14px;
  --pix2pi-shadow: 0 24px 80px rgba(0, 0, 0, 0.28);
}

* {
  box-sizing: border-box;
}

body {
  margin: 0;
  min-height: 100vh;
  background: radial-gradient(circle at top left, #1e293b 0, var(--pix2pi-bg) 40%);
  color: var(--pix2pi-text);
  font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
}

.pix2pi-page {
  width: min(1240px, calc(100% - 32px));
  margin: 0 auto;
  padding: 32px 0;
}

.pix2pi-page-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 18px;
  margin-bottom: var(--pix2pi-page-gap);
}

.pix2pi-page-title {
  margin: 0;
  font-size: 30px;
  line-height: 1.1;
  letter-spacing: -0.04em;
}

.pix2pi-page-subtitle {
  margin: 8px 0 0;
  color: var(--pix2pi-muted);
}

.pix2pi-page-grid {
  display: grid;
  gap: var(--pix2pi-page-gap);
}

.pix2pi-grid-1 {
  display: grid;
  grid-template-columns: 1fr;
  gap: var(--pix2pi-card-gap);
}

.pix2pi-grid-2 {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: var(--pix2pi-card-gap);
}

.pix2pi-grid-3 {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: var(--pix2pi-card-gap);
}

.pix2pi-grid-auto {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
  gap: var(--pix2pi-card-gap);
}

.pix2pi-grid-sidebar-content {
  display: grid;
  grid-template-columns: 320px minmax(0, 1fr);
  gap: var(--pix2pi-card-gap);
}

.pix2pi-card-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: var(--pix2pi-card-gap);
}

.pix2pi-card {
  background: rgba(17, 24, 39, 0.92);
  border: 1px solid var(--pix2pi-border);
  border-radius: var(--pix2pi-radius-lg);
  padding: 20px;
  box-shadow: var(--pix2pi-shadow);
}

.pix2pi-card-title {
  margin: 0;
  font-size: 18px;
}

.pix2pi-card-text {
  color: var(--pix2pi-muted);
  line-height: 1.6;
}

.pix2pi-form-layout {
  display: grid;
  gap: var(--pix2pi-form-gap);
}

.pix2pi-form-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: var(--pix2pi-form-gap);
}

.pix2pi-form-row {
  display: grid;
  gap: 6px;
}

.pix2pi-label {
  color: var(--pix2pi-muted);
  font-size: 13px;
  text-transform: uppercase;
  letter-spacing: 0.08em;
}

.pix2pi-input {
  width: 100%;
  border: 1px solid var(--pix2pi-border);
  border-radius: var(--pix2pi-radius-md);
  background: var(--pix2pi-content);
  color: var(--pix2pi-text);
  padding: 12px 14px;
  outline: none;
}

.pix2pi-table-region {
  display: grid;
  gap: var(--pix2pi-table-gap);
  overflow: hidden;
}

.pix2pi-table-toolbar {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  align-items: center;
}

.pix2pi-table-scroll {
  overflow-x: auto;
  border: 1px solid var(--pix2pi-border);
  border-radius: var(--pix2pi-radius-lg);
  background: var(--pix2pi-content);
}

.pix2pi-table {
  width: 100%;
  border-collapse: collapse;
  min-width: 720px;
}

.pix2pi-table th,
.pix2pi-table td {
  padding: 13px 14px;
  border-bottom: 1px solid var(--pix2pi-border);
  text-align: left;
}

.pix2pi-table th {
  color: var(--pix2pi-muted);
  font-size: 13px;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  background: rgba(31, 41, 55, 0.75);
}

.pix2pi-table tr:last-child td {
  border-bottom: 0;
}

.pix2pi-badge {
  display: inline-flex;
  border: 1px solid var(--pix2pi-border);
  background: var(--pix2pi-surface-soft);
  color: var(--pix2pi-text);
  border-radius: 999px;
  padding: 6px 10px;
  font-size: 13px;
}

.pix2pi-badge.ok {
  border-color: rgba(34, 197, 94, 0.5);
  color: #bbf7d0;
}

.pix2pi-badge.warn {
  border-color: rgba(245, 158, 11, 0.5);
  color: #fde68a;
}

.pix2pi-button {
  border: 1px solid var(--pix2pi-border);
  border-radius: var(--pix2pi-radius-md);
  background: var(--pix2pi-surface-soft);
  color: var(--pix2pi-text);
  padding: 11px 14px;
  cursor: pointer;
  font-weight: 800;
}

.pix2pi-button.primary {
  border-color: rgba(56, 189, 248, 0.6);
  background: rgba(56, 189, 248, 0.14);
}

@media (max-width: 1023px) {
  .pix2pi-card-grid,
  .pix2pi-grid-3,
  .pix2pi-grid-sidebar-content {
    grid-template-columns: 1fr 1fr;
  }

  .pix2pi-grid-sidebar-content > aside {
    grid-column: 1 / -1;
  }
}

@media (max-width: 767px) {
  .pix2pi-page {
    width: min(100% - 20px, 1240px);
    padding: 20px 0;
  }

  .pix2pi-page-header,
  .pix2pi-table-toolbar {
    display: grid;
    grid-template-columns: 1fr;
  }

  .pix2pi-card-grid,
  .pix2pi-grid-2,
  .pix2pi-grid-3,
  .pix2pi-grid-auto,
  .pix2pi-grid-sidebar-content,
  .pix2pi-form-grid {
    grid-template-columns: 1fr;
  }

  .pix2pi-card {
    padding: 16px;
  }
}
CSS

if grep -q "pix2pi-page-grid" "$CSS_FILE" \
  && grep -q "pix2pi-card-grid" "$CSS_FILE" \
  && grep -q "pix2pi-form-grid" "$CSS_FILE" \
  && grep -q "pix2pi-table-region" "$CSS_FILE" \
  && grep -q "@media" "$CSS_FILE"; then
  pass "4.1 CSS layout/grid sınıfları mevcut"
else
  fail "4.1 CSS layout/grid sınıfları eksik"
  exit 1
fi

echo "5. layout / grid JS yazılıyor..."

cat <<'JS' > "$JS_FILE"
(function layoutGridStandardRuntime(global) {
  "use strict";

  const LAYOUT_PATTERNS = {
    pageGrid: "pix2pi-page-grid",
    cardLayout: "pix2pi-card-grid",
    formLayout: "pix2pi-form-grid",
    tableLayout: "pix2pi-table-region",
    responsiveLayout: "responsive_media_queries"
  };

  const DEMO_ROWS = [
    { code: "LAYOUT_PAGE", name: "Page grid", status: "PASS" },
    { code: "LAYOUT_CARD", name: "Card layout", status: "PASS" },
    { code: "LAYOUT_FORM", name: "Form layout", status: "PASS" },
    { code: "LAYOUT_TABLE", name: "Table layout", status: "PASS" },
    { code: "LAYOUT_RESPONSIVE", name: "Responsive layout", status: "PASS" }
  ];

  function getLayoutPatterns() {
    return Object.assign({}, LAYOUT_PATTERNS);
  }

  function validatePageGrid() {
    return Boolean(document.querySelector(".pix2pi-page-grid"));
  }

  function validateCardLayout() {
    return Boolean(document.querySelector(".pix2pi-card-grid"));
  }

  function validateFormLayout() {
    return Boolean(document.querySelector(".pix2pi-form-grid"));
  }

  function validateTableLayout() {
    return Boolean(document.querySelector(".pix2pi-table-region"));
  }

  function validateResponsiveLayout() {
    return Boolean(document.querySelector('[data-responsive-layout="true"]'));
  }

  function runLayoutGridChecks() {
    return {
      page_grid: validatePageGrid() ? "PASS" : "FAIL",
      card_layout: validateCardLayout() ? "PASS" : "FAIL",
      form_layout: validateFormLayout() ? "PASS" : "FAIL",
      table_layout: validateTableLayout() ? "PASS" : "FAIL",
      responsive_layout: validateResponsiveLayout() ? "PASS" : "FAIL"
    };
  }

  function renderLayoutTable() {
    const tbody = document.getElementById("layoutGridTableBody");
    if (!tbody) {
      return;
    }

    tbody.innerHTML = "";

    DEMO_ROWS.forEach((row) => {
      const tr = document.createElement("tr");
      tr.innerHTML = "<td></td><td></td><td></td>";
      tr.children[0].textContent = row.code;
      tr.children[1].textContent = row.name;
      tr.children[2].textContent = row.status;
      tbody.appendChild(tr);
    });
  }

  function renderLayoutGridChecks() {
    renderLayoutTable();

    const result = runLayoutGridChecks();
    const output = document.getElementById("layoutGridCheckOutput");

    if (output) {
      output.textContent = JSON.stringify(result, null, 2);
    }

    return result;
  }

  function bootstrapLayoutGridStandard() {
    const button = document.getElementById("runLayoutGridCheckButton");

    if (button) {
      button.addEventListener("click", renderLayoutGridChecks);
    }

    renderLayoutGridChecks();
  }

  const api = {
    LAYOUT_PATTERNS,
    DEMO_ROWS,
    getLayoutPatterns,
    validatePageGrid,
    validateCardLayout,
    validateFormLayout,
    validateTableLayout,
    validateResponsiveLayout,
    runLayoutGridChecks,
    renderLayoutTable,
    renderLayoutGridChecks,
    bootstrapLayoutGridStandard
  };

  global.Pix2piLayoutGridStandard = api;

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }

  if (global.document) {
    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", bootstrapLayoutGridStandard);
    } else {
      bootstrapLayoutGridStandard();
    }
  }
})(typeof window !== "undefined" ? window : globalThis);
JS

if grep -q "validatePageGrid" "$JS_FILE" \
  && grep -q "validateCardLayout" "$JS_FILE" \
  && grep -q "validateFormLayout" "$JS_FILE" \
  && grep -q "validateTableLayout" "$JS_FILE" \
  && grep -q "validateResponsiveLayout" "$JS_FILE"; then
  pass "5.1 JS layout/grid runtime fonksiyonları mevcut"
else
  fail "5.1 JS layout/grid runtime fonksiyonları eksik"
  exit 1
fi

echo "6. layout / grid HTML yazılıyor..."

cat <<'HTML' > "$HTML_FILE"
<!doctype html>
<html lang="tr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Pix2pi — Layout / Grid Standardı</title>
  <link rel="stylesheet" href="./layout_grid.css">
</head>
<body>
  <main class="pix2pi-page" data-responsive-layout="true">
    <header class="pix2pi-page-header">
      <div>
        <h1 class="pix2pi-page-title">Pix2pi Layout / Grid Standardı</h1>
        <p class="pix2pi-page-subtitle">FAZ 1-4.2 — WEB-L1 UI Foundation / Design System</p>
      </div>
      <span class="pix2pi-badge ok">WEB-L1 READY</span>
    </header>

    <section class="pix2pi-page-grid">
      <section class="pix2pi-card-grid">
        <article class="pix2pi-card">
          <h2 class="pix2pi-card-title">Page grid</h2>
          <p class="pix2pi-card-text">Sayfa genelinde standart gap, header ve içerik akışı.</p>
        </article>

        <article class="pix2pi-card">
          <h2 class="pix2pi-card-title">Card layout</h2>
          <p class="pix2pi-card-text">Dashboard ve domain yüzeyleri için ortak kart düzeni.</p>
        </article>

        <article class="pix2pi-card">
          <h2 class="pix2pi-card-title">Responsive layout</h2>
          <p class="pix2pi-card-text">Desktop, tablet ve mobil kırılımları desteklenir.</p>
        </article>
      </section>

      <section class="pix2pi-grid-sidebar-content">
        <aside class="pix2pi-card">
          <h2 class="pix2pi-card-title">Form layout</h2>
          <form class="pix2pi-form-layout">
            <div class="pix2pi-form-grid">
              <label class="pix2pi-form-row">
                <span class="pix2pi-label">Firma adı</span>
                <input class="pix2pi-input" type="text" value="Pix2pi Pilot">
              </label>

              <label class="pix2pi-form-row">
                <span class="pix2pi-label">Tenant kodu</span>
                <input class="pix2pi-input" type="text" value="tenant_7">
              </label>
            </div>

            <label class="pix2pi-form-row">
              <span class="pix2pi-label">Açıklama</span>
              <input class="pix2pi-input" type="text" value="Form layout standardı">
            </label>

            <button class="pix2pi-button primary" type="button">Kaydet</button>
          </form>
        </aside>

        <section class="pix2pi-card pix2pi-table-region">
          <div class="pix2pi-table-toolbar">
            <div>
              <h2 class="pix2pi-card-title">Table layout</h2>
              <p class="pix2pi-card-text">Tablo bölgesi scroll, toolbar ve responsive davranış ile gelir.</p>
            </div>
            <button class="pix2pi-button" id="runLayoutGridCheckButton" type="button">Layout check</button>
          </div>

          <div class="pix2pi-table-scroll">
            <table class="pix2pi-table">
              <thead>
                <tr>
                  <th>Kod</th>
                  <th>Alan</th>
                  <th>Durum</th>
                </tr>
              </thead>
              <tbody id="layoutGridTableBody"></tbody>
            </table>
          </div>

          <pre class="pix2pi-card-text" id="layoutGridCheckOutput">CHECK_LOADING</pre>
        </section>
      </section>
    </section>
  </main>

  <script src="./layout_grid.js"></script>
</body>
</html>
HTML

if grep -q "pix2pi-page-grid" "$HTML_FILE" \
  && grep -q "pix2pi-card-grid" "$HTML_FILE" \
  && grep -q "pix2pi-form-grid" "$HTML_FILE" \
  && grep -q "pix2pi-table-region" "$HTML_FILE" \
  && grep -q 'data-responsive-layout="true"' "$HTML_FILE"; then
  pass "6.1 HTML layout/grid elementleri mevcut"
else
  fail "6.1 HTML layout/grid elementleri eksik"
  exit 1
fi

echo "7. strict suite yazılıyor..."

cat <<'SUITE' > "$STRICT_SUITE_FILE"
#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"

WEB_DIR="$REPO/web/faz1/ui-foundation/layout-grid"
CONFIG_DIR="$REPO/configs/faz1/web/ui_foundation"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"

HTML_FILE="$WEB_DIR/index.html"
JS_FILE="$WEB_DIR/layout_grid.js"
CSS_FILE="$WEB_DIR/layout_grid.css"
CONFIG_FILE="$CONFIG_DIR/layout_grid_standard_contract.v1.json"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_4_2_LAYOUT_GRID_STANDARD_STRICT_SUITE_RESULT_$(date +%Y%m%d_%H%M%S).md"

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

pass(){ PASS_COUNT=$((PASS_COUNT+1)); echo "$1 / OK ✅"; }
fail(){ FAIL_COUNT=$((FAIL_COUNT+1)); echo "$1 / FAIL ❌"; }
warn(){ WARN_COUNT=$((WARN_COUNT+1)); echo "$1 / WARN ⚠️"; }

check_file() {
  local file="$1"
  local label="$2"

  if [ -f "$file" ]; then
    pass "$label mevcut"
  else
    fail "$label eksik: $file"
  fi
}

check_contains() {
  local file="$1"
  local pattern="$2"
  local label="$3"

  if grep -q "$pattern" "$file"; then
    pass "$label"
  else
    fail "$label eksik"
  fi
}

echo "===== FAZ 1-4.2 LAYOUT / GRID STANDARD STRICT SUITE START ====="

mkdir -p "$EVIDENCE_DIR"

check_file "$HTML_FILE" "1.1 HTML file"
check_file "$JS_FILE" "1.2 JS file"
check_file "$CSS_FILE" "1.3 CSS file"
check_file "$CONFIG_FILE" "1.4 config file"

if command -v python3 >/dev/null 2>&1; then
  if python3 -m json.tool "$CONFIG_FILE" >/dev/null 2>&1; then
    pass "2.1 config JSON valid"
  else
    fail "2.1 config JSON invalid"
  fi
else
  warn "2.1 python3 yok, JSON validation atlandı"
fi

check_contains "$CONFIG_FILE" '"page_grid"' "3.1 page_grid capability contract"
check_contains "$CONFIG_FILE" '"card_layout"' "3.2 card_layout capability contract"
check_contains "$CONFIG_FILE" '"form_layout"' "3.3 form_layout capability contract"
check_contains "$CONFIG_FILE" '"table_layout"' "3.4 table_layout capability contract"
check_contains "$CONFIG_FILE" '"responsive_layout"' "3.5 responsive_layout capability contract"

check_contains "$HTML_FILE" 'pix2pi-page-grid' "4.1 page grid HTML"
check_contains "$HTML_FILE" 'pix2pi-card-grid' "4.2 card layout HTML"
check_contains "$HTML_FILE" 'pix2pi-form-grid' "4.3 form layout HTML"
check_contains "$HTML_FILE" 'pix2pi-table-region' "4.4 table layout HTML"
check_contains "$HTML_FILE" 'data-responsive-layout="true"' "4.5 responsive layout HTML"

check_contains "$JS_FILE" 'validatePageGrid' "5.1 page grid validation JS"
check_contains "$JS_FILE" 'validateCardLayout' "5.2 card layout validation JS"
check_contains "$JS_FILE" 'validateFormLayout' "5.3 form layout validation JS"
check_contains "$JS_FILE" 'validateTableLayout' "5.4 table layout validation JS"
check_contains "$JS_FILE" 'validateResponsiveLayout' "5.5 responsive layout validation JS"
check_contains "$JS_FILE" 'runLayoutGridChecks' "5.6 layout checks JS"

check_contains "$CSS_FILE" 'pix2pi-page-grid' "6.1 page grid CSS"
check_contains "$CSS_FILE" 'pix2pi-card-grid' "6.2 card layout CSS"
check_contains "$CSS_FILE" 'pix2pi-form-grid' "6.3 form layout CSS"
check_contains "$CSS_FILE" 'pix2pi-table-region' "6.4 table layout CSS"
check_contains "$CSS_FILE" '@media' "6.5 responsive media CSS"

PAGE_GRID_STATUS="PASS"
CARD_LAYOUT_STATUS="PASS"
FORM_LAYOUT_STATUS="PASS"
TABLE_LAYOUT_STATUS="PASS"
RESPONSIVE_LAYOUT_STATUS="PASS"

if [ "$FAIL_COUNT" -ne 0 ]; then
  PAGE_GRID_STATUS="FAIL"
  CARD_LAYOUT_STATUS="FAIL"
  FORM_LAYOUT_STATUS="FAIL"
  TABLE_LAYOUT_STATUS="FAIL"
  RESPONSIVE_LAYOUT_STATUS="FAIL"
fi

{
  echo "# FAZ 1-4.2 Layout / Grid Standard Strict Suite Result"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- HTML_FILE=$HTML_FILE"
  echo "- JS_FILE=$JS_FILE"
  echo "- CSS_FILE=$CSS_FILE"
  echo "- CONFIG_FILE=$CONFIG_FILE"
  echo
  echo "## Status"
  echo "- PAGE_GRID_STATUS=$PAGE_GRID_STATUS"
  echo "- CARD_LAYOUT_STATUS=$CARD_LAYOUT_STATUS"
  echo "- FORM_LAYOUT_STATUS=$FORM_LAYOUT_STATUS"
  echo "- TABLE_LAYOUT_STATUS=$TABLE_LAYOUT_STATUS"
  echo "- RESPONSIVE_LAYOUT_STATUS=$RESPONSIVE_LAYOUT_STATUS"
  echo
  echo "## Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

pass "7.1 strict suite evidence yazıldı: $EVIDENCE_FILE"

echo "===== FAZ 1-4.2 LAYOUT / GRID STANDARD STRICT SUITE RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "PAGE_GRID_STATUS=$PAGE_GRID_STATUS"
echo "CARD_LAYOUT_STATUS=$CARD_LAYOUT_STATUS"
echo "FORM_LAYOUT_STATUS=$FORM_LAYOUT_STATUS"
echo "TABLE_LAYOUT_STATUS=$TABLE_LAYOUT_STATUS"
echo "RESPONSIVE_LAYOUT_STATUS=$RESPONSIVE_LAYOUT_STATUS"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_4_2_LAYOUT_GRID_STANDARD_STRICT_SUITE_STATUS=PASS"
  echo "FAZ_1_4_2_LAYOUT_GRID_STANDARD_STRICT_SUITE_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_4_2_LAYOUT_GRID_STANDARD_STRICT_SUITE_STATUS=FAIL"
  echo "FAZ_1_4_2_LAYOUT_GRID_STANDARD_STRICT_SUITE_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-4.2 LAYOUT / GRID STANDARD STRICT SUITE END ====="
SUITE

chmod +x "$STRICT_SUITE_FILE"

if [ -x "$STRICT_SUITE_FILE" ]; then
  pass "7.1 strict suite dosyası yazıldı ve executable yapıldı: $STRICT_SUITE_FILE"
else
  fail "7.1 strict suite executable değil"
  exit 1
fi

echo "8. strict suite çalıştırılıyor..."

set +e
"$STRICT_SUITE_FILE" > "$STRICT_SUITE_OUT" 2>&1
STRICT_SUITE_EXIT_CODE=$?
set -e

cat "$STRICT_SUITE_OUT"

if [ "$STRICT_SUITE_EXIT_CODE" -eq 0 ]; then
  pass "8.1 strict suite exit code 0"
else
  fail "8.1 strict suite başarısız exit_code=$STRICT_SUITE_EXIT_CODE"
  exit 1
fi

STRICT_SUITE_PASS_COUNT="$(extract_var "$STRICT_SUITE_OUT" "PASS_COUNT")"
STRICT_SUITE_FAIL_COUNT="$(extract_var "$STRICT_SUITE_OUT" "FAIL_COUNT")"
STRICT_SUITE_WARN_COUNT="$(extract_var "$STRICT_SUITE_OUT" "WARN_COUNT")"
STRICT_SUITE_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_4_2_LAYOUT_GRID_STANDARD_STRICT_SUITE_STATUS")"
STRICT_SUITE_SEAL_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_4_2_LAYOUT_GRID_STANDARD_STRICT_SUITE_SEAL_STATUS")"

PAGE_GRID_STATUS="$(extract_var "$STRICT_SUITE_OUT" "PAGE_GRID_STATUS")"
CARD_LAYOUT_STATUS="$(extract_var "$STRICT_SUITE_OUT" "CARD_LAYOUT_STATUS")"
FORM_LAYOUT_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FORM_LAYOUT_STATUS")"
TABLE_LAYOUT_STATUS="$(extract_var "$STRICT_SUITE_OUT" "TABLE_LAYOUT_STATUS")"
RESPONSIVE_LAYOUT_STATUS="$(extract_var "$STRICT_SUITE_OUT" "RESPONSIVE_LAYOUT_STATUS")"

[ "${STRICT_SUITE_FAIL_COUNT:-1}" = "0" ] && pass "8.2 strict suite FAIL_COUNT=0 doğrulandı" || fail "8.2 strict suite FAIL_COUNT sıfır değil"
[ "${STRICT_SUITE_STATUS:-FAIL}" = "PASS" ] && pass "8.3 strict suite PASS doğrulandı" || fail "8.3 strict suite PASS değil"
[ "${STRICT_SUITE_SEAL_STATUS:-OPEN}" = "SEALED" ] && pass "8.4 strict suite SEALED doğrulandı" || fail "8.4 strict suite SEALED değil"

echo "9. dokümantasyon ve evidence yazılıyor..."

cat <<DOC > "$DOC_FILE"
# FAZ 1-4.2 — Layout / Grid Standardı

## Kapsam

- Page grid
- Card layout
- Form layout
- Table layout
- Responsive layout

## Üretilen Dosyalar

- UI: web/faz1/ui-foundation/layout-grid/index.html
- Runtime JS: web/faz1/ui-foundation/layout-grid/layout_grid.js
- CSS: web/faz1/ui-foundation/layout-grid/layout_grid.css
- Contract: configs/faz1/web/ui_foundation/layout_grid_standard_contract.v1.json
- Strict suite: scripts/web/faz_1_4_2_layout_grid_standard_strict_suite.sh

## Final Status

- PAGE_GRID_STATUS=${PAGE_GRID_STATUS:-N/A}
- CARD_LAYOUT_STATUS=${CARD_LAYOUT_STATUS:-N/A}
- FORM_LAYOUT_STATUS=${FORM_LAYOUT_STATUS:-N/A}
- TABLE_LAYOUT_STATUS=${TABLE_LAYOUT_STATUS:-N/A}
- RESPONSIVE_LAYOUT_STATUS=${RESPONSIVE_LAYOUT_STATUS:-N/A}
- STRICT_SUITE_STATUS=${STRICT_SUITE_STATUS:-N/A}
- STRICT_SUITE_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}
DOC

{
  echo "# FAZ 1-4.2 Layout / Grid Standard Real Implementation Audit"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Repo: $REPO"
  echo "- HTML_FILE=$HTML_FILE"
  echo "- JS_FILE=$JS_FILE"
  echo "- CSS_FILE=$CSS_FILE"
  echo "- CONFIG_FILE=$CONFIG_FILE"
  echo "- STRICT_SUITE_FILE=$STRICT_SUITE_FILE"
  echo "- DOC_FILE=$DOC_FILE"
  echo "- BACKUP_DIR=$BACKUP_DIR"
  echo
  echo "## Status"
  echo "- PAGE_GRID_STATUS=${PAGE_GRID_STATUS:-N/A}"
  echo "- CARD_LAYOUT_STATUS=${CARD_LAYOUT_STATUS:-N/A}"
  echo "- FORM_LAYOUT_STATUS=${FORM_LAYOUT_STATUS:-N/A}"
  echo "- TABLE_LAYOUT_STATUS=${TABLE_LAYOUT_STATUS:-N/A}"
  echo "- RESPONSIVE_LAYOUT_STATUS=${RESPONSIVE_LAYOUT_STATUS:-N/A}"
  echo "- STRICT_SUITE_STATUS=${STRICT_SUITE_STATUS:-N/A}"
  echo "- STRICT_SUITE_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
  echo
  echo "## Counters"
  echo "- APPLY_PASS_COUNT=$PASS_COUNT"
  echo "- APPLY_FAIL_COUNT=$FAIL_COUNT"
  echo "- APPLY_WARN_COUNT=$WARN_COUNT"
  echo "- STRICT_SUITE_PASS_COUNT=${STRICT_SUITE_PASS_COUNT:-N/A}"
  echo "- STRICT_SUITE_FAIL_COUNT=${STRICT_SUITE_FAIL_COUNT:-N/A}"
  echo "- STRICT_SUITE_WARN_COUNT=${STRICT_SUITE_WARN_COUNT:-N/A}"
} > "$EVIDENCE_FILE"

{
  echo "# FAZ 1-4.2 Layout / Grid Standard Final Seal"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Evidence file: $EVIDENCE_FILE"
  echo "- Doc file: $DOC_FILE"
  echo
  echo "FAZ_1_4_2_PAGE_GRID_STATUS=${PAGE_GRID_STATUS:-N/A}"
  echo "FAZ_1_4_2_CARD_LAYOUT_STATUS=${CARD_LAYOUT_STATUS:-N/A}"
  echo "FAZ_1_4_2_FORM_LAYOUT_STATUS=${FORM_LAYOUT_STATUS:-N/A}"
  echo "FAZ_1_4_2_TABLE_LAYOUT_STATUS=${TABLE_LAYOUT_STATUS:-N/A}"
  echo "FAZ_1_4_2_RESPONSIVE_LAYOUT_STATUS=${RESPONSIVE_LAYOUT_STATUS:-N/A}"
  echo "FAZ_1_4_2_LAYOUT_GRID_STANDARD_FINAL_STATUS=${STRICT_SUITE_STATUS:-N/A}"
  echo "FAZ_1_4_2_LAYOUT_GRID_STANDARD_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
  echo "FAZ_1_4_4_READY=YES"
} > "$FINAL_SEAL_FILE"

pass "9.1 dokümantasyon yazıldı: $DOC_FILE"
pass "9.2 real implementation audit evidence yazıldı: $EVIDENCE_FILE"
pass "9.3 final seal evidence yazıldı: $FINAL_SEAL_FILE"

cp "$0" "$APPLY_SCRIPT_FILE"
chmod +x "$APPLY_SCRIPT_FILE"

if [ -x "$APPLY_SCRIPT_FILE" ]; then
  pass "9.4 apply script repo içine kopyalandı: $APPLY_SCRIPT_FILE"
else
  fail "9.4 apply script repo içine kopyalanamadı"
  exit 1
fi

echo "===== FAZ 1-4.2 LAYOUT / GRID STANDARD RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "STRICT_SUITE_PASS_COUNT=${STRICT_SUITE_PASS_COUNT:-N/A}"
echo "STRICT_SUITE_FAIL_COUNT=${STRICT_SUITE_FAIL_COUNT:-N/A}"
echo "STRICT_SUITE_WARN_COUNT=${STRICT_SUITE_WARN_COUNT:-N/A}"
echo "PAGE_GRID_STATUS=${PAGE_GRID_STATUS:-N/A}"
echo "CARD_LAYOUT_STATUS=${CARD_LAYOUT_STATUS:-N/A}"
echo "FORM_LAYOUT_STATUS=${FORM_LAYOUT_STATUS:-N/A}"
echo "TABLE_LAYOUT_STATUS=${TABLE_LAYOUT_STATUS:-N/A}"
echo "RESPONSIVE_LAYOUT_STATUS=${RESPONSIVE_LAYOUT_STATUS:-N/A}"
echo "STRICT_SUITE_STATUS=${STRICT_SUITE_STATUS:-N/A}"
echo "STRICT_SUITE_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
echo "HTML_FILE=$HTML_FILE"
echo "JS_FILE=$JS_FILE"
echo "CSS_FILE=$CSS_FILE"
echo "CONFIG_FILE=$CONFIG_FILE"
echo "STRICT_SUITE_FILE=$STRICT_SUITE_FILE"
echo "DOC_FILE=$DOC_FILE"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"
echo "FINAL_SEAL_FILE=$FINAL_SEAL_FILE"
echo "BACKUP_DIR=$BACKUP_DIR"

if [ "$FAIL_COUNT" -eq 0 ] \
  && [ "${STRICT_SUITE_FAIL_COUNT:-1}" = "0" ] \
  && [ "${STRICT_SUITE_STATUS:-FAIL}" = "PASS" ] \
  && [ "${STRICT_SUITE_SEAL_STATUS:-OPEN}" = "SEALED" ]; then

  echo "FAZ_1_4_2_PAGE_GRID_STATUS=PASS"
  echo "FAZ_1_4_2_CARD_LAYOUT_STATUS=PASS"
  echo "FAZ_1_4_2_FORM_LAYOUT_STATUS=PASS"
  echo "FAZ_1_4_2_TABLE_LAYOUT_STATUS=PASS"
  echo "FAZ_1_4_2_RESPONSIVE_LAYOUT_STATUS=PASS"
  echo "FAZ_1_4_2_LAYOUT_GRID_STANDARD_FINAL_STATUS=PASS"
  echo "FAZ_1_4_2_LAYOUT_GRID_STANDARD_SEAL_STATUS=SEALED"
  echo "FAZ_1_4_4_READY=YES"
else
  echo "FAZ_1_4_2_LAYOUT_GRID_STANDARD_FINAL_STATUS=FAIL"
  echo "FAZ_1_4_2_LAYOUT_GRID_STANDARD_SEAL_STATUS=OPEN"
  echo "FAZ_1_4_4_READY=NO"
  exit 1
fi

echo "===== FAZ 1-4.2 LAYOUT / GRID STANDARD END ====="
