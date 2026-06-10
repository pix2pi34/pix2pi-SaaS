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
