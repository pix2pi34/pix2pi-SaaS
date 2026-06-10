/* PIX2PI_341_PANEL_PLANS_RUNTIME_START */
(function () {
  "use strict";

  const CONFIG = {
    surface: "panel_plans",
    phase: "FAZ_7R",
    step: "341",
    planCatalogEndpoint: "/api/commercial/plans/catalog",
    tenantSubscriptionEndpoint: "/api/commercial/subscription/current",
    planChangeEndpoint: "/api/commercial/subscription/change",
    selectedTenantKey: "pix2pi.panel.tenant.preference",
    merchantSessionKey: "pix2pi.panel.merchant.session",
    billingCycleKey: "pix2pi.panel.plans.billing_cycle",
    runtimeContract: {
      realPlanChangeEnabled: false,
      realPaymentCollectionEnabled: false,
      realInvoiceIssueEnabled: false,
      realEntitlementEnforcementEnabled: false,
      planCatalogEnabled: true,
      fallbackPlanCatalogEnabled: true,
      readyForStep342: true
    },
    fallbackCatalog: {
      tenant_id: "controlled-pilot",
      merchant_session_id: "MERCHANT_DEMO_SESSION",
      current_plan_code: "pilot_free",
      currency: "TRY",
      vat_rate: 20,
      plans: [
        {
          code: "pilot_free",
          name: "Pilot Free",
          description: "Küçük işletme pilot kullanımı için kapalı tahsilatlı plan.",
          monthly_price: 0,
          annual_price: 0,
          badge: "Mevcut",
          recommended: false,
          features: {
            merchant_panel: true,
            pos_surface: true,
            market_surface: true,
            product_limit: 250,
            user_limit: 3,
            store_limit: 1,
            support_level: "community"
          }
        },
        {
          code: "small_business",
          name: "Small Business",
          description: "Tek işletme / tek şube için ticari başlangıç paketi.",
          monthly_price: 999,
          annual_price: 9990,
          badge: "Başlangıç",
          recommended: true,
          features: {
            merchant_panel: true,
            pos_surface: true,
            market_surface: true,
            product_limit: 2500,
            user_limit: 10,
            store_limit: 1,
            support_level: "standard"
          }
        },
        {
          code: "growth",
          name: "Growth",
          description: "Birden fazla mağaza ve büyüyen operasyonlar için.",
          monthly_price: 2999,
          annual_price: 29990,
          badge: "Büyüme",
          recommended: false,
          features: {
            merchant_panel: true,
            pos_surface: true,
            market_surface: true,
            product_limit: 15000,
            user_limit: 50,
            store_limit: 5,
            support_level: "priority"
          }
        },
        {
          code: "enterprise",
          name: "Enterprise",
          description: "Özel SLA, çoklu şube ve kurumsal operasyonlar.",
          monthly_price: null,
          annual_price: null,
          badge: "Teklif",
          recommended: false,
          features: {
            merchant_panel: true,
            pos_surface: true,
            market_surface: true,
            product_limit: "custom",
            user_limit: "custom",
            store_limit: "custom",
            support_level: "enterprise"
          }
        }
      ],
      policy_notes: [
        "Gerçek tahsilat kapalıdır.",
        "Plan değişikliği production billing gate sonrası açılır.",
        "KDV ve mali müşavir/hukuk onayı gerçek faturalama öncesi zorunludur."
      ]
    }
  };

  function getTenantId() {
    return window.localStorage.getItem(CONFIG.selectedTenantKey) || CONFIG.fallbackCatalog.tenant_id;
  }

  function getMerchantSession() {
    const raw = window.localStorage.getItem(CONFIG.merchantSessionKey);
    if (!raw) {
      return {
        session_present: false,
        session_id: CONFIG.fallbackCatalog.merchant_session_id,
        role: "OWNER"
      };
    }

    try {
      return Object.assign({
        session_present: true
      }, JSON.parse(raw));
    } catch (_error) {
      return {
        session_present: false,
        session_id: "INVALID_MERCHANT_SESSION",
        role: "UNKNOWN"
      };
    }
  }

  function getBillingCycle() {
    return window.localStorage.getItem(CONFIG.billingCycleKey) || "monthly";
  }

  function setBillingCycle(value) {
    const next = value === "annual" ? "annual" : "monthly";
    window.localStorage.setItem(CONFIG.billingCycleKey, next);
    return next;
  }

  function commercialScopeHeaders() {
    const session = getMerchantSession();

    return {
      "Content-Type": "application/json",
      "X-Tenant-ID": getTenantId(),
      "X-Merchant-Session": session.session_id,
      "X-Pix2pi-Surface": "merchant_panel_commercial",
      "X-Pix2pi-Step": "341"
    };
  }

  function moneyTRY(value) {
    if (value === null || value === undefined) return "Teklif al";
    try {
      return new Intl.NumberFormat("tr-TR", {
        style: "currency",
        currency: "TRY",
        maximumFractionDigits: 0
      }).format(Number(value || 0));
    } catch (_error) {
      return String(value || 0) + " TL";
    }
  }

  function priceForCycle(plan, cycle) {
    return cycle === "annual" ? plan.annual_price : plan.monthly_price;
  }

  function vatIncludedPrice(value, vatRate) {
    if (value === null || value === undefined) return null;
    return Number(value || 0) * (1 + Number(vatRate || 0) / 100);
  }

  function validatePlanScope(catalog) {
    const errors = [];

    if (!catalog || !catalog.tenant_id) {
      errors.push({ field: "tenant_id", code: "TENANT_REQUIRED" });
    }

    if (!catalog || !catalog.merchant_session_id) {
      errors.push({ field: "merchant_session_id", code: "MERCHANT_SESSION_REQUIRED" });
    }

    if (!catalog || !Array.isArray(catalog.plans) || catalog.plans.length === 0) {
      errors.push({ field: "plans", code: "PLAN_CATALOG_REQUIRED" });
    }

    if (!catalog || !catalog.current_plan_code) {
      errors.push({ field: "current_plan_code", code: "CURRENT_PLAN_REQUIRED" });
    }

    return {
      valid: errors.length === 0,
      errors: errors
    };
  }

  async function apiJson(endpoint) {
    const response = await fetch(endpoint, {
      method: "GET",
      headers: commercialScopeHeaders()
    });

    if (!response.ok) {
      throw new Error("PANEL_PLAN_BACKEND_NOT_READY_OR_FAILED");
    }

    return response.json();
  }

  async function fetchPlanCatalog() {
    try {
      return await apiJson(CONFIG.planCatalogEndpoint);
    } catch (_error) {
      const catalog = JSON.parse(JSON.stringify(CONFIG.fallbackCatalog));
      const session = getMerchantSession();
      catalog.tenant_id = getTenantId();
      catalog.merchant_session_id = session.session_id;
      return catalog;
    }
  }

  function buildPlanComparison(catalog, cycle) {
    const billingCycle = cycle || getBillingCycle();

    return (catalog.plans || []).map(function (plan) {
      const basePrice = priceForCycle(plan, billingCycle);
      const grossPrice = vatIncludedPrice(basePrice, catalog.vat_rate);

      return {
        code: plan.code,
        name: plan.name,
        billing_cycle: billingCycle,
        base_price: basePrice,
        gross_price: grossPrice,
        base_price_label: moneyTRY(basePrice),
        gross_price_label: moneyTRY(grossPrice),
        is_current: plan.code === catalog.current_plan_code,
        recommended: Boolean(plan.recommended),
        features: plan.features,
        runtime_contract: CONFIG.runtimeContract
      };
    });
  }

  function buildEntitlementPreview(plan) {
    return {
      plan_code: plan.code,
      merchant_panel: Boolean(plan.features.merchant_panel),
      pos_surface: Boolean(plan.features.pos_surface),
      market_surface: Boolean(plan.features.market_surface),
      product_limit: plan.features.product_limit,
      user_limit: plan.features.user_limit,
      store_limit: plan.features.store_limit,
      support_level: plan.features.support_level,
      enforcement_enabled: CONFIG.runtimeContract.realEntitlementEnforcementEnabled,
      source: {
        surface: "panel_plans",
        phase: "FAZ_7R",
        step: "341"
      }
    };
  }

  function buildPlanChangeDisabledGuard(planCode) {
    return {
      accepted: false,
      plan_code: planCode,
      reason: "REAL_PLAN_CHANGE_DISABLED_IN_STEP_341",
      real_plan_change_enabled: CONFIG.runtimeContract.realPlanChangeEnabled,
      real_payment_collection_enabled: CONFIG.runtimeContract.realPaymentCollectionEnabled,
      real_invoice_issue_enabled: CONFIG.runtimeContract.realInvoiceIssueEnabled,
      source: {
        surface: "panel_plans",
        phase: "FAZ_7R",
        step: "341"
      }
    };
  }

  function buildPlanRuntimeContract(catalog) {
    return {
      tenant_id: catalog.tenant_id,
      merchant_session_id: catalog.merchant_session_id,
      current_plan_code: catalog.current_plan_code,
      billing_cycle: getBillingCycle(),
      plan_count: Array.isArray(catalog.plans) ? catalog.plans.length : 0,
      runtime_contract: CONFIG.runtimeContract,
      scope_validation: validatePlanScope(catalog),
      source: {
        surface: "panel_plans",
        phase: "FAZ_7R",
        step: "341"
      }
    };
  }

  function renderTenantContext(catalog) {
    const tenant = document.getElementById("plans-tenant");
    const session = document.getElementById("plans-merchant-session");
    const current = document.getElementById("plans-current-plan");
    const validation = document.getElementById("plans-scope-validation");
    const contract = buildPlanRuntimeContract(catalog);

    if (tenant) tenant.textContent = contract.tenant_id;
    if (session) session.textContent = catalog.merchant_session_id;
    if (current) current.textContent = catalog.current_plan_code;
    if (validation) {
      validation.textContent = contract.scope_validation.valid ? "VALID" : "INVALID";
      validation.setAttribute("data-validation-status", contract.scope_validation.valid ? "valid" : "invalid");
    }
  }

  function renderPlanCards(catalog) {
    const target = document.getElementById("plans-card-grid");
    if (!target) return;

    target.innerHTML = "";

    const cycle = getBillingCycle();
    const comparisons = buildPlanComparison(catalog, cycle);

    comparisons.forEach(function (planView) {
      const plan = catalog.plans.find(function (item) { return item.code === planView.code; });
      const card = document.createElement("article");
      card.className = "plan-card";
      card.setAttribute("data-plan-code", plan.code);
      card.setAttribute("data-current-plan", String(planView.is_current));
      card.innerHTML = [
        "<span class='plan-badge'>" + plan.badge + "</span>",
        "<strong>" + plan.name + "</strong>",
        "<p>" + plan.description + "</p>",
        "<em>" + planView.base_price_label + "</em>",
        "<small>KDV dahil: " + planView.gross_price_label + "</small>",
        planView.is_current ? "<span class='current'>Mevcut plan</span>" : "<button type='button' disabled>Plan değişikliği kapalı</button>"
      ].join("");
      target.appendChild(card);
    });
  }

  function renderFeatureMatrix(catalog) {
    const target = document.getElementById("plans-feature-matrix");
    if (!target) return;

    target.innerHTML = "";

    (catalog.plans || []).forEach(function (plan) {
      const ent = buildEntitlementPreview(plan);
      const row = document.createElement("article");
      row.className = "feature-row";
      row.setAttribute("data-plan-code", plan.code);
      row.innerHTML = [
        "<strong>" + plan.name + "</strong>",
        "<p>Ürün: " + ent.product_limit + " / Kullanıcı: " + ent.user_limit + " / Mağaza: " + ent.store_limit + "</p>",
        "<p>POS: " + ent.pos_surface + " / Market: " + ent.market_surface + " / Destek: " + ent.support_level + "</p>"
      ].join("");
      target.appendChild(row);
    });
  }

  function renderPolicyNotes(catalog) {
    const target = document.getElementById("plans-policy-notes");
    if (!target) return;

    target.innerHTML = "";

    (catalog.policy_notes || []).forEach(function (note) {
      const item = document.createElement("li");
      item.textContent = note;
      target.appendChild(item);
    });
  }

  function renderRuntimeContract(catalog) {
    const target = document.getElementById("plans-runtime-contract");
    if (!target) return;

    const contract = buildPlanRuntimeContract(catalog);

    target.textContent = [
      "real_plan_change_enabled=" + CONFIG.runtimeContract.realPlanChangeEnabled,
      "real_payment_collection_enabled=" + CONFIG.runtimeContract.realPaymentCollectionEnabled,
      "real_invoice_issue_enabled=" + CONFIG.runtimeContract.realInvoiceIssueEnabled,
      "real_entitlement_enforcement_enabled=" + CONFIG.runtimeContract.realEntitlementEnforcementEnabled,
      "ready_for_step_342=" + CONFIG.runtimeContract.readyForStep342,
      "scope=" + (contract.scope_validation.valid ? "VALID" : "INVALID")
    ].join(" / ");
  }

  function renderPlansScreen(catalog) {
    renderTenantContext(catalog);
    renderPlanCards(catalog);
    renderFeatureMatrix(catalog);
    renderPolicyNotes(catalog);
    renderRuntimeContract(catalog);
    document.body.setAttribute("data-panel-plans-rendered", "true");
  }

  async function bootPlansScreen() {
    const catalog = await fetchPlanCatalog();
    renderPlansScreen(catalog);
    return buildPlanRuntimeContract(catalog);
  }

  window.Pix2piPanelPlans = {
    CONFIG: CONFIG,
    getTenantId: getTenantId,
    getMerchantSession: getMerchantSession,
    getBillingCycle: getBillingCycle,
    setBillingCycle: setBillingCycle,
    commercialScopeHeaders: commercialScopeHeaders,
    validatePlanScope: validatePlanScope,
    fetchPlanCatalog: fetchPlanCatalog,
    buildPlanComparison: buildPlanComparison,
    buildEntitlementPreview: buildEntitlementPreview,
    buildPlanChangeDisabledGuard: buildPlanChangeDisabledGuard,
    buildPlanRuntimeContract: buildPlanRuntimeContract,
    renderTenantContext: renderTenantContext,
    renderPlanCards: renderPlanCards,
    renderFeatureMatrix: renderFeatureMatrix,
    renderPolicyNotes: renderPolicyNotes,
    renderRuntimeContract: renderRuntimeContract,
    renderPlansScreen: renderPlansScreen,
    bootPlansScreen: bootPlansScreen,
    moneyTRY: moneyTRY
  };
})();
/* PIX2PI_341_PANEL_PLANS_RUNTIME_END */
