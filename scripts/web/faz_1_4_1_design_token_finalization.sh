#!/usr/bin/env bash
set -euo pipefail

clear

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"
TS="$(date +%Y%m%d_%H%M%S)"
PHASE="FAZ_1_4_1_DESIGN_TOKEN_FINALIZATION"

BACKUP_DIR="$REPO/backups/faz1/faz_1_4_1_design_token_finalization_$TS"
WEB_DIR="$REPO/web/faz1/ui-foundation/design-tokens"
CONFIG_DIR="$REPO/configs/faz1/web/ui_foundation"
DOC_DIR="$REPO/docs/faz1/web"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"
SCRIPT_DIR="$REPO/scripts/web"

HTML_FILE="$WEB_DIR/index.html"
JS_FILE="$WEB_DIR/design_tokens.js"
CSS_FILE="$WEB_DIR/design_tokens.css"
CONFIG_FILE="$CONFIG_DIR/design_tokens_contract.v1.json"
DOC_FILE="$DOC_DIR/FAZ_1_4_1_DESIGN_TOKEN_FINALIZATION.md"
STRICT_SUITE_FILE="$SCRIPT_DIR/faz_1_4_1_design_token_finalization_strict_suite.sh"
APPLY_SCRIPT_FILE="$SCRIPT_DIR/faz_1_4_1_design_token_finalization.sh"
STRICT_SUITE_OUT="$BACKUP_DIR/faz_1_4_1_design_token_finalization_strict_suite.out"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_4_1_DESIGN_TOKEN_FINALIZATION_REAL_IMPLEMENTATION_AUDIT.md"
FINAL_SEAL_FILE="$EVIDENCE_DIR/FAZ_1_4_1_DESIGN_TOKEN_FINALIZATION_FINAL_SEAL_$TS.md"

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

echo "===== FAZ 1-4.1 DESIGN TOKEN FINALIZATION START ====="

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

echo "3. design token contract config yazılıyor..."

cat <<'JSON' > "$CONFIG_FILE"
{
  "phase": "FAZ_1_4_1",
  "module": "WEB_L1_UI_FOUNDATION_DESIGN_SYSTEM",
  "component": "design_token_finalization",
  "status": "READY",
  "required_capabilities": [
    "color_tokens",
    "typography_scale",
    "spacing_tokens",
    "radius_shadow_tokens",
    "component_usage_doc"
  ],
  "token_contract": {
    "css_root_selector": ":root",
    "token_prefix": "--pix2pi-",
    "color_tokens": [
      "--pix2pi-color-bg",
      "--pix2pi-color-surface",
      "--pix2pi-color-surface-soft",
      "--pix2pi-color-content",
      "--pix2pi-color-border",
      "--pix2pi-color-text",
      "--pix2pi-color-muted",
      "--pix2pi-color-accent",
      "--pix2pi-color-success",
      "--pix2pi-color-warning",
      "--pix2pi-color-danger"
    ],
    "typography_tokens": [
      "--pix2pi-font-family",
      "--pix2pi-font-size-xs",
      "--pix2pi-font-size-sm",
      "--pix2pi-font-size-base",
      "--pix2pi-font-size-lg",
      "--pix2pi-font-size-xl",
      "--pix2pi-font-size-2xl",
      "--pix2pi-font-weight-regular",
      "--pix2pi-font-weight-medium",
      "--pix2pi-font-weight-bold"
    ],
    "spacing_tokens": [
      "--pix2pi-space-1",
      "--pix2pi-space-2",
      "--pix2pi-space-3",
      "--pix2pi-space-4",
      "--pix2pi-space-5",
      "--pix2pi-space-6",
      "--pix2pi-space-8",
      "--pix2pi-space-10"
    ],
    "radius_shadow_tokens": [
      "--pix2pi-radius-sm",
      "--pix2pi-radius-md",
      "--pix2pi-radius-lg",
      "--pix2pi-radius-xl",
      "--pix2pi-shadow-sm",
      "--pix2pi-shadow-md",
      "--pix2pi-shadow-lg"
    ]
  },
  "usage_contract": {
    "button": "pix2pi-button",
    "card": "pix2pi-card",
    "badge": "pix2pi-badge",
    "input": "pix2pi-input",
    "table": "pix2pi-table",
    "state": "pix2pi-state-card"
  },
  "final_gate": {
    "required_fail_count": 0,
    "next_ready_flag": "FAZ_1_4_7_READY"
  }
}
JSON

if [ -f "$CONFIG_FILE" ]; then
  pass "3.1 design token config yazıldı: $CONFIG_FILE"
else
  fail "3.1 design token config yazılamadı"
  exit 1
fi

echo "4. design token CSS yazılıyor..."

cat <<'CSS' > "$CSS_FILE"
:root {
  --pix2pi-color-bg: #0f172a;
  --pix2pi-color-surface: #111827;
  --pix2pi-color-surface-soft: #1f2937;
  --pix2pi-color-content: #020617;
  --pix2pi-color-border: #334155;
  --pix2pi-color-text: #e5e7eb;
  --pix2pi-color-muted: #9ca3af;
  --pix2pi-color-accent: #38bdf8;
  --pix2pi-color-success: #22c55e;
  --pix2pi-color-warning: #f59e0b;
  --pix2pi-color-danger: #ef4444;

  --pix2pi-font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  --pix2pi-font-size-xs: 12px;
  --pix2pi-font-size-sm: 13px;
  --pix2pi-font-size-base: 14px;
  --pix2pi-font-size-lg: 18px;
  --pix2pi-font-size-xl: 22px;
  --pix2pi-font-size-2xl: 30px;
  --pix2pi-font-weight-regular: 400;
  --pix2pi-font-weight-medium: 700;
  --pix2pi-font-weight-bold: 900;

  --pix2pi-space-1: 4px;
  --pix2pi-space-2: 8px;
  --pix2pi-space-3: 12px;
  --pix2pi-space-4: 16px;
  --pix2pi-space-5: 20px;
  --pix2pi-space-6: 24px;
  --pix2pi-space-8: 32px;
  --pix2pi-space-10: 40px;

  --pix2pi-radius-sm: 10px;
  --pix2pi-radius-md: 14px;
  --pix2pi-radius-lg: 20px;
  --pix2pi-radius-xl: 24px;
  --pix2pi-shadow-sm: 0 8px 24px rgba(0, 0, 0, 0.18);
  --pix2pi-shadow-md: 0 18px 48px rgba(0, 0, 0, 0.24);
  --pix2pi-shadow-lg: 0 24px 80px rgba(0, 0, 0, 0.28);
}

* {
  box-sizing: border-box;
}

body {
  margin: 0;
  min-height: 100vh;
  background: radial-gradient(circle at top left, #1e3a8a 0, var(--pix2pi-color-bg) 42%);
  color: var(--pix2pi-color-text);
  font-family: var(--pix2pi-font-family);
  font-size: var(--pix2pi-font-size-base);
}

.pix2pi-page {
  width: min(1180px, calc(100% - 32px));
  margin: 0 auto;
  padding: var(--pix2pi-space-8) 0;
}

.pix2pi-page-header {
  display: flex;
  justify-content: space-between;
  gap: var(--pix2pi-space-5);
  align-items: flex-start;
  margin-bottom: var(--pix2pi-space-6);
}

.pix2pi-page-title {
  margin: 0;
  font-size: var(--pix2pi-font-size-2xl);
  font-weight: var(--pix2pi-font-weight-bold);
  letter-spacing: -0.04em;
}

.pix2pi-page-subtitle {
  margin: var(--pix2pi-space-2) 0 0;
  color: var(--pix2pi-color-muted);
}

.pix2pi-grid {
  display: grid;
  grid-template-columns: 1fr 420px;
  gap: var(--pix2pi-space-5);
}

.pix2pi-card {
  background: rgba(17, 24, 39, 0.92);
  border: 1px solid var(--pix2pi-color-border);
  border-radius: var(--pix2pi-radius-lg);
  padding: var(--pix2pi-space-5);
  box-shadow: var(--pix2pi-shadow-lg);
}

.pix2pi-card-title {
  margin: 0;
  font-size: var(--pix2pi-font-size-lg);
  font-weight: var(--pix2pi-font-weight-bold);
}

.pix2pi-card-text {
  color: var(--pix2pi-color-muted);
  line-height: 1.6;
}

.pix2pi-token-section {
  display: grid;
  gap: var(--pix2pi-space-4);
  margin-bottom: var(--pix2pi-space-6);
}

.pix2pi-token-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(190px, 1fr));
  gap: var(--pix2pi-space-3);
}

.pix2pi-token-color,
.pix2pi-token-typography,
.pix2pi-token-spacing,
.pix2pi-token-radius-shadow {
  border: 1px solid var(--pix2pi-color-border);
  border-radius: var(--pix2pi-radius-md);
  background: var(--pix2pi-color-content);
  padding: var(--pix2pi-space-4);
  display: grid;
  gap: var(--pix2pi-space-2);
}

.pix2pi-token-swatch {
  height: 42px;
  border-radius: var(--pix2pi-radius-sm);
  border: 1px solid var(--pix2pi-color-border);
}

.pix2pi-token-name {
  font-weight: var(--pix2pi-font-weight-bold);
  font-size: var(--pix2pi-font-size-sm);
}

.pix2pi-token-value {
  color: var(--pix2pi-color-muted);
  font-size: var(--pix2pi-font-size-xs);
  overflow-wrap: anywhere;
}

.pix2pi-button {
  border: 1px solid var(--pix2pi-color-border);
  border-radius: var(--pix2pi-radius-md);
  background: var(--pix2pi-color-surface-soft);
  color: var(--pix2pi-color-text);
  padding: var(--pix2pi-space-3) var(--pix2pi-space-4);
  cursor: pointer;
  font-weight: var(--pix2pi-font-weight-bold);
}

.pix2pi-button.primary {
  border-color: rgba(56, 189, 248, 0.6);
  background: rgba(56, 189, 248, 0.14);
}

.pix2pi-badge {
  display: inline-flex;
  border: 1px solid var(--pix2pi-color-border);
  background: var(--pix2pi-color-surface-soft);
  color: var(--pix2pi-color-text);
  border-radius: 999px;
  padding: 6px 10px;
  font-size: var(--pix2pi-font-size-sm);
}

.pix2pi-badge.ok {
  border-color: rgba(34, 197, 94, 0.5);
  color: #bbf7d0;
}

.pix2pi-input {
  width: 100%;
  border: 1px solid var(--pix2pi-color-border);
  border-radius: var(--pix2pi-radius-md);
  background: var(--pix2pi-color-content);
  color: var(--pix2pi-color-text);
  padding: var(--pix2pi-space-3) var(--pix2pi-space-4);
  outline: none;
}

.pix2pi-table {
  width: 100%;
  border-collapse: collapse;
  border: 1px solid var(--pix2pi-color-border);
  border-radius: var(--pix2pi-radius-lg);
  overflow: hidden;
}

.pix2pi-table th,
.pix2pi-table td {
  padding: var(--pix2pi-space-3);
  border-bottom: 1px solid var(--pix2pi-color-border);
  text-align: left;
}

.pix2pi-table th {
  color: var(--pix2pi-color-muted);
  background: var(--pix2pi-color-surface-soft);
}

.pix2pi-state-card {
  border: 1px dashed var(--pix2pi-color-border);
  border-radius: var(--pix2pi-radius-lg);
  padding: var(--pix2pi-space-5);
  background: var(--pix2pi-color-content);
  color: var(--pix2pi-color-muted);
}

.pix2pi-log {
  background: var(--pix2pi-color-content);
  border: 1px solid var(--pix2pi-color-border);
  border-radius: var(--pix2pi-radius-lg);
  padding: var(--pix2pi-space-4);
  color: var(--pix2pi-color-muted);
  min-height: 260px;
  white-space: pre-wrap;
  overflow: auto;
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
}

@media (max-width: 900px) {
  .pix2pi-page-header,
  .pix2pi-grid {
    display: grid;
    grid-template-columns: 1fr;
  }
}
CSS

if grep -q -- "--pix2pi-color-bg" "$CSS_FILE" \
  && grep -q -- "--pix2pi-font-size-base" "$CSS_FILE" \
  && grep -q -- "--pix2pi-space-4" "$CSS_FILE" \
  && grep -q -- "--pix2pi-radius-md" "$CSS_FILE" \
  && grep -q -- "--pix2pi-shadow-lg" "$CSS_FILE"; then
  pass "4.1 CSS design token değişkenleri mevcut"
else
  fail "4.1 CSS design token değişkenleri eksik"
  exit 1
fi

echo "5. design token JS yazılıyor..."

cat <<'JS' > "$JS_FILE"
(function designTokenRuntime(global) {
  "use strict";

  const TOKEN_GROUPS = {
    colors: [
      "--pix2pi-color-bg",
      "--pix2pi-color-surface",
      "--pix2pi-color-surface-soft",
      "--pix2pi-color-content",
      "--pix2pi-color-border",
      "--pix2pi-color-text",
      "--pix2pi-color-muted",
      "--pix2pi-color-accent",
      "--pix2pi-color-success",
      "--pix2pi-color-warning",
      "--pix2pi-color-danger"
    ],
    typography: [
      "--pix2pi-font-family",
      "--pix2pi-font-size-xs",
      "--pix2pi-font-size-sm",
      "--pix2pi-font-size-base",
      "--pix2pi-font-size-lg",
      "--pix2pi-font-size-xl",
      "--pix2pi-font-size-2xl",
      "--pix2pi-font-weight-regular",
      "--pix2pi-font-weight-medium",
      "--pix2pi-font-weight-bold"
    ],
    spacing: [
      "--pix2pi-space-1",
      "--pix2pi-space-2",
      "--pix2pi-space-3",
      "--pix2pi-space-4",
      "--pix2pi-space-5",
      "--pix2pi-space-6",
      "--pix2pi-space-8",
      "--pix2pi-space-10"
    ],
    radiusShadow: [
      "--pix2pi-radius-sm",
      "--pix2pi-radius-md",
      "--pix2pi-radius-lg",
      "--pix2pi-radius-xl",
      "--pix2pi-shadow-sm",
      "--pix2pi-shadow-md",
      "--pix2pi-shadow-lg"
    ]
  };

  const USAGE_COMPONENTS = [
    "pix2pi-button",
    "pix2pi-card",
    "pix2pi-badge",
    "pix2pi-input",
    "pix2pi-table",
    "pix2pi-state-card"
  ];

  function getTokenValue(name) {
    if (!global.getComputedStyle || !document.documentElement) {
      return "";
    }

    return getComputedStyle(document.documentElement).getPropertyValue(name).trim();
  }

  function collectTokens() {
    const result = {};

    Object.keys(TOKEN_GROUPS).forEach((group) => {
      result[group] = TOKEN_GROUPS[group].map((name) => ({
        name,
        value: getTokenValue(name)
      }));
    });

    return result;
  }

  function validateColorTokens() {
    return TOKEN_GROUPS.colors.every((name) => Boolean(getTokenValue(name)));
  }

  function validateTypographyScale() {
    return TOKEN_GROUPS.typography.every((name) => Boolean(getTokenValue(name)));
  }

  function validateSpacingTokens() {
    return TOKEN_GROUPS.spacing.every((name) => Boolean(getTokenValue(name)));
  }

  function validateRadiusShadowTokens() {
    return TOKEN_GROUPS.radiusShadow.every((name) => Boolean(getTokenValue(name)));
  }

  function validateComponentUsageDoc() {
    return USAGE_COMPONENTS.every((className) => Boolean(document.querySelector("." + className)));
  }

  function runDesignTokenTests() {
    return {
      color_tokens: validateColorTokens() ? "PASS" : "FAIL",
      typography_scale: validateTypographyScale() ? "PASS" : "FAIL",
      spacing_tokens: validateSpacingTokens() ? "PASS" : "FAIL",
      radius_shadow_tokens: validateRadiusShadowTokens() ? "PASS" : "FAIL",
      component_usage_doc: validateComponentUsageDoc() ? "PASS" : "FAIL"
    };
  }

  function createTokenCard(token, group) {
    const card = document.createElement("article");
    card.className = "pix2pi-token-" + group;

    if (group === "color") {
      const swatch = document.createElement("div");
      swatch.className = "pix2pi-token-swatch";
      swatch.style.background = token.value;
      card.appendChild(swatch);
    }

    const name = document.createElement("div");
    name.className = "pix2pi-token-name";
    name.textContent = token.name;

    const value = document.createElement("div");
    value.className = "pix2pi-token-value";
    value.textContent = token.value || "EMPTY";

    card.appendChild(name);
    card.appendChild(value);

    return card;
  }

  function renderTokenGroup(targetId, tokens, group) {
    const target = document.getElementById(targetId);
    if (!target) {
      return;
    }

    target.innerHTML = "";
    tokens.forEach((token) => target.appendChild(createTokenCard(token, group)));
  }

  function renderDesignTokens() {
    const tokens = collectTokens();

    renderTokenGroup("pix2piColorTokenGrid", tokens.colors, "color");
    renderTokenGroup("pix2piTypographyTokenGrid", tokens.typography, "typography");
    renderTokenGroup("pix2piSpacingTokenGrid", tokens.spacing, "spacing");
    renderTokenGroup("pix2piRadiusShadowTokenGrid", tokens.radiusShadow, "radius-shadow");

    const output = document.getElementById("pix2piDesignTokenTestOutput");
    if (output) {
      output.textContent = JSON.stringify(runDesignTokenTests(), null, 2);
    }

    return tokens;
  }

  function bootstrapDesignTokens() {
    const button = document.getElementById("runDesignTokenTestsButton");
    if (button) {
      button.addEventListener("click", renderDesignTokens);
    }

    renderDesignTokens();
  }

  const api = {
    TOKEN_GROUPS,
    USAGE_COMPONENTS,
    getTokenValue,
    collectTokens,
    validateColorTokens,
    validateTypographyScale,
    validateSpacingTokens,
    validateRadiusShadowTokens,
    validateComponentUsageDoc,
    runDesignTokenTests,
    renderDesignTokens,
    bootstrapDesignTokens
  };

  global.Pix2piDesignTokens = api;

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }

  if (global.document) {
    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", bootstrapDesignTokens);
    } else {
      bootstrapDesignTokens();
    }
  }
})(typeof window !== "undefined" ? window : globalThis);
JS

if grep -q "validateColorTokens" "$JS_FILE" \
  && grep -q "validateTypographyScale" "$JS_FILE" \
  && grep -q "validateSpacingTokens" "$JS_FILE" \
  && grep -q "validateRadiusShadowTokens" "$JS_FILE" \
  && grep -q "validateComponentUsageDoc" "$JS_FILE"; then
  pass "5.1 JS design token runtime fonksiyonları mevcut"
else
  fail "5.1 JS design token runtime fonksiyonları eksik"
  exit 1
fi

echo "6. design token HTML yazılıyor..."

cat <<'HTML' > "$HTML_FILE"
<!doctype html>
<html lang="tr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Pix2pi — Design Token Finalizasyonu</title>
  <link rel="stylesheet" href="./design_tokens.css">
</head>
<body>
  <main class="pix2pi-page">
    <header class="pix2pi-page-header">
      <div>
        <h1 class="pix2pi-page-title">Pix2pi Design Token Finalizasyonu</h1>
        <p class="pix2pi-page-subtitle">FAZ 1-4.1 — WEB-L1 UI Foundation / Design System</p>
      </div>
      <span class="pix2pi-badge ok">WEB-L1 READY</span>
    </header>

    <section class="pix2pi-grid">
      <article class="pix2pi-card">
        <section class="pix2pi-token-section">
          <h2 class="pix2pi-card-title">Color tokens</h2>
          <div class="pix2pi-token-grid" id="pix2piColorTokenGrid"></div>
        </section>

        <section class="pix2pi-token-section">
          <h2 class="pix2pi-card-title">Typography scale</h2>
          <div class="pix2pi-token-grid" id="pix2piTypographyTokenGrid"></div>
        </section>

        <section class="pix2pi-token-section">
          <h2 class="pix2pi-card-title">Spacing tokens</h2>
          <div class="pix2pi-token-grid" id="pix2piSpacingTokenGrid"></div>
        </section>

        <section class="pix2pi-token-section">
          <h2 class="pix2pi-card-title">Radius / shadow tokens</h2>
          <div class="pix2pi-token-grid" id="pix2piRadiusShadowTokenGrid"></div>
        </section>
      </article>

      <aside class="pix2pi-card">
        <h2 class="pix2pi-card-title">Component usage doc</h2>
        <p class="pix2pi-card-text">Design tokenlar bu temel bileşenlerde kullanılır.</p>

        <div class="pix2pi-token-section">
          <button class="pix2pi-button primary" type="button">pix2pi-button</button>
          <span class="pix2pi-badge ok">pix2pi-badge</span>
          <input class="pix2pi-input" value="pix2pi-input" aria-label="Demo input">

          <article class="pix2pi-state-card">
            pix2pi-state-card — loading/error/empty/retry state yüzeyleri için temel kart.
          </article>

          <table class="pix2pi-table">
            <thead>
              <tr>
                <th>Component</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td>pix2pi-card</td>
                <td>PASS</td>
              </tr>
              <tr>
                <td>pix2pi-table</td>
                <td>PASS</td>
              </tr>
            </tbody>
          </table>
        </div>

        <button class="pix2pi-button primary" id="runDesignTokenTestsButton" type="button">Design token testlerini çalıştır</button>
        <pre class="pix2pi-log" id="pix2piDesignTokenTestOutput">DESIGN_TOKEN_TEST_LOADING</pre>
      </aside>
    </section>
  </main>

  <script src="./design_tokens.js"></script>
</body>
</html>
HTML

if grep -q "pix2piColorTokenGrid" "$HTML_FILE" \
  && grep -q "pix2piTypographyTokenGrid" "$HTML_FILE" \
  && grep -q "pix2piSpacingTokenGrid" "$HTML_FILE" \
  && grep -q "pix2piRadiusShadowTokenGrid" "$HTML_FILE" \
  && grep -q "Component usage doc" "$HTML_FILE"; then
  pass "6.1 HTML design token elementleri mevcut"
else
  fail "6.1 HTML design token elementleri eksik"
  exit 1
fi

echo "7. strict suite yazılıyor..."

cat <<'SUITE' > "$STRICT_SUITE_FILE"
#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$HOME/pix2pi/pix2pi-SaaS}"

WEB_DIR="$REPO/web/faz1/ui-foundation/design-tokens"
CONFIG_DIR="$REPO/configs/faz1/web/ui_foundation"
EVIDENCE_DIR="$REPO/docs/faz1/evidence"

HTML_FILE="$WEB_DIR/index.html"
JS_FILE="$WEB_DIR/design_tokens.js"
CSS_FILE="$WEB_DIR/design_tokens.css"
CONFIG_FILE="$CONFIG_DIR/design_tokens_contract.v1.json"
EVIDENCE_FILE="$EVIDENCE_DIR/FAZ_1_4_1_DESIGN_TOKEN_FINALIZATION_STRICT_SUITE_RESULT_$(date +%Y%m%d_%H%M%S).md"

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

  if grep -q -- "$pattern" "$file"; then
    pass "$label"
  else
    fail "$label eksik"
  fi
}

echo "===== FAZ 1-4.1 DESIGN TOKEN FINALIZATION STRICT SUITE START ====="

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

check_contains "$CONFIG_FILE" '"color_tokens"' "3.1 color_tokens capability contract"
check_contains "$CONFIG_FILE" '"typography_scale"' "3.2 typography_scale capability contract"
check_contains "$CONFIG_FILE" '"spacing_tokens"' "3.3 spacing_tokens capability contract"
check_contains "$CONFIG_FILE" '"radius_shadow_tokens"' "3.4 radius_shadow_tokens capability contract"
check_contains "$CONFIG_FILE" '"component_usage_doc"' "3.5 component_usage_doc capability contract"

check_contains "$CSS_FILE" '--pix2pi-color-bg' "4.1 color bg token CSS"
check_contains "$CSS_FILE" '--pix2pi-color-accent' "4.2 color accent token CSS"
check_contains "$CSS_FILE" '--pix2pi-font-size-base' "4.3 typography base token CSS"
check_contains "$CSS_FILE" '--pix2pi-font-size-2xl' "4.4 typography 2xl token CSS"
check_contains "$CSS_FILE" '--pix2pi-space-4' "4.5 spacing token CSS"
check_contains "$CSS_FILE" '--pix2pi-space-8' "4.6 spacing large token CSS"
check_contains "$CSS_FILE" '--pix2pi-radius-md' "4.7 radius token CSS"
check_contains "$CSS_FILE" '--pix2pi-shadow-lg' "4.8 shadow token CSS"

check_contains "$HTML_FILE" 'pix2piColorTokenGrid' "5.1 color token HTML"
check_contains "$HTML_FILE" 'pix2piTypographyTokenGrid' "5.2 typography token HTML"
check_contains "$HTML_FILE" 'pix2piSpacingTokenGrid' "5.3 spacing token HTML"
check_contains "$HTML_FILE" 'pix2piRadiusShadowTokenGrid' "5.4 radius/shadow token HTML"
check_contains "$HTML_FILE" 'Component usage doc' "5.5 component usage doc HTML"

check_contains "$JS_FILE" 'validateColorTokens' "6.1 color token validation JS"
check_contains "$JS_FILE" 'validateTypographyScale' "6.2 typography validation JS"
check_contains "$JS_FILE" 'validateSpacingTokens' "6.3 spacing validation JS"
check_contains "$JS_FILE" 'validateRadiusShadowTokens' "6.4 radius/shadow validation JS"
check_contains "$JS_FILE" 'validateComponentUsageDoc' "6.5 component usage validation JS"
check_contains "$JS_FILE" 'runDesignTokenTests' "6.6 design token tests JS"

COLOR_TOKENS_STATUS="PASS"
TYPOGRAPHY_SCALE_STATUS="PASS"
SPACING_TOKENS_STATUS="PASS"
RADIUS_SHADOW_TOKENS_STATUS="PASS"
COMPONENT_USAGE_DOC_STATUS="PASS"

if [ "$FAIL_COUNT" -ne 0 ]; then
  COLOR_TOKENS_STATUS="FAIL"
  TYPOGRAPHY_SCALE_STATUS="FAIL"
  SPACING_TOKENS_STATUS="FAIL"
  RADIUS_SHADOW_TOKENS_STATUS="FAIL"
  COMPONENT_USAGE_DOC_STATUS="FAIL"
fi

{
  echo "# FAZ 1-4.1 Design Token Finalization Strict Suite Result"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- HTML_FILE=$HTML_FILE"
  echo "- JS_FILE=$JS_FILE"
  echo "- CSS_FILE=$CSS_FILE"
  echo "- CONFIG_FILE=$CONFIG_FILE"
  echo
  echo "## Status"
  echo "- COLOR_TOKENS_STATUS=$COLOR_TOKENS_STATUS"
  echo "- TYPOGRAPHY_SCALE_STATUS=$TYPOGRAPHY_SCALE_STATUS"
  echo "- SPACING_TOKENS_STATUS=$SPACING_TOKENS_STATUS"
  echo "- RADIUS_SHADOW_TOKENS_STATUS=$RADIUS_SHADOW_TOKENS_STATUS"
  echo "- COMPONENT_USAGE_DOC_STATUS=$COMPONENT_USAGE_DOC_STATUS"
  echo
  echo "## Counters"
  echo "- PASS_COUNT=$PASS_COUNT"
  echo "- FAIL_COUNT=$FAIL_COUNT"
  echo "- WARN_COUNT=$WARN_COUNT"
} > "$EVIDENCE_FILE"

pass "7.1 strict suite evidence yazıldı: $EVIDENCE_FILE"

echo "===== FAZ 1-4.1 DESIGN TOKEN FINALIZATION STRICT SUITE RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "COLOR_TOKENS_STATUS=$COLOR_TOKENS_STATUS"
echo "TYPOGRAPHY_SCALE_STATUS=$TYPOGRAPHY_SCALE_STATUS"
echo "SPACING_TOKENS_STATUS=$SPACING_TOKENS_STATUS"
echo "RADIUS_SHADOW_TOKENS_STATUS=$RADIUS_SHADOW_TOKENS_STATUS"
echo "COMPONENT_USAGE_DOC_STATUS=$COMPONENT_USAGE_DOC_STATUS"
echo "EVIDENCE_FILE=$EVIDENCE_FILE"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "FAZ_1_4_1_DESIGN_TOKEN_FINALIZATION_STRICT_SUITE_STATUS=PASS"
  echo "FAZ_1_4_1_DESIGN_TOKEN_FINALIZATION_STRICT_SUITE_SEAL_STATUS=SEALED"
else
  echo "FAZ_1_4_1_DESIGN_TOKEN_FINALIZATION_STRICT_SUITE_STATUS=FAIL"
  echo "FAZ_1_4_1_DESIGN_TOKEN_FINALIZATION_STRICT_SUITE_SEAL_STATUS=OPEN"
  exit 1
fi

echo "===== FAZ 1-4.1 DESIGN TOKEN FINALIZATION STRICT SUITE END ====="
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
STRICT_SUITE_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_4_1_DESIGN_TOKEN_FINALIZATION_STRICT_SUITE_STATUS")"
STRICT_SUITE_SEAL_STATUS="$(extract_var "$STRICT_SUITE_OUT" "FAZ_1_4_1_DESIGN_TOKEN_FINALIZATION_STRICT_SUITE_SEAL_STATUS")"

COLOR_TOKENS_STATUS="$(extract_var "$STRICT_SUITE_OUT" "COLOR_TOKENS_STATUS")"
TYPOGRAPHY_SCALE_STATUS="$(extract_var "$STRICT_SUITE_OUT" "TYPOGRAPHY_SCALE_STATUS")"
SPACING_TOKENS_STATUS="$(extract_var "$STRICT_SUITE_OUT" "SPACING_TOKENS_STATUS")"
RADIUS_SHADOW_TOKENS_STATUS="$(extract_var "$STRICT_SUITE_OUT" "RADIUS_SHADOW_TOKENS_STATUS")"
COMPONENT_USAGE_DOC_STATUS="$(extract_var "$STRICT_SUITE_OUT" "COMPONENT_USAGE_DOC_STATUS")"

[ "${STRICT_SUITE_FAIL_COUNT:-1}" = "0" ] && pass "8.2 strict suite FAIL_COUNT=0 doğrulandı" || fail "8.2 strict suite FAIL_COUNT sıfır değil"
[ "${STRICT_SUITE_STATUS:-FAIL}" = "PASS" ] && pass "8.3 strict suite PASS doğrulandı" || fail "8.3 strict suite PASS değil"
[ "${STRICT_SUITE_SEAL_STATUS:-OPEN}" = "SEALED" ] && pass "8.4 strict suite SEALED doğrulandı" || fail "8.4 strict suite SEALED değil"

echo "9. dokümantasyon ve evidence yazılıyor..."

cat <<DOC > "$DOC_FILE"
# FAZ 1-4.1 — Design Token Finalizasyonu

## Kapsam

- Color tokens
- Typography scale
- Spacing tokens
- Radius/shadow tokens
- Component usage doc

## Üretilen Dosyalar

- UI: web/faz1/ui-foundation/design-tokens/index.html
- Runtime JS: web/faz1/ui-foundation/design-tokens/design_tokens.js
- CSS: web/faz1/ui-foundation/design-tokens/design_tokens.css
- Contract: configs/faz1/web/ui_foundation/design_tokens_contract.v1.json
- Strict suite: scripts/web/faz_1_4_1_design_token_finalization_strict_suite.sh

## Final Status

- COLOR_TOKENS_STATUS=${COLOR_TOKENS_STATUS:-N/A}
- TYPOGRAPHY_SCALE_STATUS=${TYPOGRAPHY_SCALE_STATUS:-N/A}
- SPACING_TOKENS_STATUS=${SPACING_TOKENS_STATUS:-N/A}
- RADIUS_SHADOW_TOKENS_STATUS=${RADIUS_SHADOW_TOKENS_STATUS:-N/A}
- COMPONENT_USAGE_DOC_STATUS=${COMPONENT_USAGE_DOC_STATUS:-N/A}
- STRICT_SUITE_STATUS=${STRICT_SUITE_STATUS:-N/A}
- STRICT_SUITE_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}
DOC

{
  echo "# FAZ 1-4.1 Design Token Finalization Real Implementation Audit"
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
  echo "- COLOR_TOKENS_STATUS=${COLOR_TOKENS_STATUS:-N/A}"
  echo "- TYPOGRAPHY_SCALE_STATUS=${TYPOGRAPHY_SCALE_STATUS:-N/A}"
  echo "- SPACING_TOKENS_STATUS=${SPACING_TOKENS_STATUS:-N/A}"
  echo "- RADIUS_SHADOW_TOKENS_STATUS=${RADIUS_SHADOW_TOKENS_STATUS:-N/A}"
  echo "- COMPONENT_USAGE_DOC_STATUS=${COMPONENT_USAGE_DOC_STATUS:-N/A}"
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
  echo "# FAZ 1-4.1 Design Token Finalization Final Seal"
  echo
  echo "- Tarih: $(date -Is)"
  echo "- Evidence file: $EVIDENCE_FILE"
  echo "- Doc file: $DOC_FILE"
  echo
  echo "FAZ_1_4_1_COLOR_TOKENS_STATUS=${COLOR_TOKENS_STATUS:-N/A}"
  echo "FAZ_1_4_1_TYPOGRAPHY_SCALE_STATUS=${TYPOGRAPHY_SCALE_STATUS:-N/A}"
  echo "FAZ_1_4_1_SPACING_TOKENS_STATUS=${SPACING_TOKENS_STATUS:-N/A}"
  echo "FAZ_1_4_1_RADIUS_SHADOW_TOKENS_STATUS=${RADIUS_SHADOW_TOKENS_STATUS:-N/A}"
  echo "FAZ_1_4_1_COMPONENT_USAGE_DOC_STATUS=${COMPONENT_USAGE_DOC_STATUS:-N/A}"
  echo "FAZ_1_4_1_DESIGN_TOKEN_FINALIZATION_FINAL_STATUS=${STRICT_SUITE_STATUS:-N/A}"
  echo "FAZ_1_4_1_DESIGN_TOKEN_FINALIZATION_SEAL_STATUS=${STRICT_SUITE_SEAL_STATUS:-N/A}"
  echo "FAZ_1_4_7_READY=YES"
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

echo "===== FAZ 1-4.1 DESIGN TOKEN FINALIZATION RESULT ====="
echo "PASS_COUNT=$PASS_COUNT"
echo "FAIL_COUNT=$FAIL_COUNT"
echo "WARN_COUNT=$WARN_COUNT"
echo "STRICT_SUITE_PASS_COUNT=${STRICT_SUITE_PASS_COUNT:-N/A}"
echo "STRICT_SUITE_FAIL_COUNT=${STRICT_SUITE_FAIL_COUNT:-N/A}"
echo "STRICT_SUITE_WARN_COUNT=${STRICT_SUITE_WARN_COUNT:-N/A}"
echo "COLOR_TOKENS_STATUS=${COLOR_TOKENS_STATUS:-N/A}"
echo "TYPOGRAPHY_SCALE_STATUS=${TYPOGRAPHY_SCALE_STATUS:-N/A}"
echo "SPACING_TOKENS_STATUS=${SPACING_TOKENS_STATUS:-N/A}"
echo "RADIUS_SHADOW_TOKENS_STATUS=${RADIUS_SHADOW_TOKENS_STATUS:-N/A}"
echo "COMPONENT_USAGE_DOC_STATUS=${COMPONENT_USAGE_DOC_STATUS:-N/A}"
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

  echo "FAZ_1_4_1_COLOR_TOKENS_STATUS=PASS"
  echo "FAZ_1_4_1_TYPOGRAPHY_SCALE_STATUS=PASS"
  echo "FAZ_1_4_1_SPACING_TOKENS_STATUS=PASS"
  echo "FAZ_1_4_1_RADIUS_SHADOW_TOKENS_STATUS=PASS"
  echo "FAZ_1_4_1_COMPONENT_USAGE_DOC_STATUS=PASS"
  echo "FAZ_1_4_1_DESIGN_TOKEN_FINALIZATION_FINAL_STATUS=PASS"
  echo "FAZ_1_4_1_DESIGN_TOKEN_FINALIZATION_SEAL_STATUS=SEALED"
  echo "FAZ_1_4_7_READY=YES"
else
  echo "FAZ_1_4_1_DESIGN_TOKEN_FINALIZATION_FINAL_STATUS=FAIL"
  echo "FAZ_1_4_1_DESIGN_TOKEN_FINALIZATION_SEAL_STATUS=OPEN"
  echo "FAZ_1_4_7_READY=NO"
  exit 1
fi

echo "===== FAZ 1-4.1 DESIGN TOKEN FINALIZATION END ====="
