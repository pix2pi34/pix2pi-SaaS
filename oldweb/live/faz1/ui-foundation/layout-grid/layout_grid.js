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
