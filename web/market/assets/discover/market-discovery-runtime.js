/* PIX2PI_337_MARKET_DISCOVERY_RUNTIME_START */
(function () {
  "use strict";

  const CONFIG = {
    surface: "market_discovery",
    phase: "FAZ_7R",
    step: "337",
    discoverySnapshotEndpoint: "/api/market/discovery/snapshot",
    storeSearchEndpoint: "/api/market/stores/search",
    campaignPreviewEndpoint: "/api/market/campaigns/preview",
    customerSessionKey: "pix2pi.market.customer.session",
    regionKey: "pix2pi.market.region.preference",
    runtimeContract: {
      realCustomerLoginEnabled: false,
      realOrderEnabled: false,
      realPaymentEnabled: false,
      realStockReservationEnabled: false,
      discoverySnapshotEnabled: true,
      fallbackDiscoveryEnabled: true,
      readyForStep338: true
    },
    defaultRegion: {
      city: "İstanbul",
      district: "Pilot",
      neighborhood: "Demo Mahalle",
      region_code: "TR-34-PILOT"
    },
    fallbackDiscovery: {
      region: {
        city: "İstanbul",
        district: "Pilot",
        neighborhood: "Demo Mahalle",
        region_code: "TR-34-PILOT"
      },
      categories: [
        { id: "market", name: "Market", emoji: "🛒", store_count: 18 },
        { id: "bakery", name: "Fırın", emoji: "🥖", store_count: 8 },
        { id: "butcher", name: "Kasap", emoji: "🥩", store_count: 5 },
        { id: "greengrocer", name: "Manav", emoji: "🥬", store_count: 11 },
        { id: "cleaning", name: "Temizlik", emoji: "🧴", store_count: 6 }
      ],
      campaigns: [
        {
          id: "deal-001",
          title: "Mahalle kampanyaları",
          description: "Yakındaki pilot mağazalarda vitrin fırsatları.",
          tag: "PILOT"
        },
        {
          id: "deal-002",
          title: "Gel-al hızlı teslim",
          description: "Gel-al destekli mağazaları keşfet.",
          tag: "PICKUP"
        }
      ],
      stores: [
        {
          id: "store-001",
          tenant_id: "controlled-pilot",
          store_slug: "demo-market",
          name: "Demo Market",
          category_id: "market",
          category_name: "Market",
          city: "İstanbul",
          district: "Pilot",
          neighborhood: "Demo Mahalle",
          distance_km: 0.4,
          rating: 4.8,
          review_count: 128,
          status: "OPEN",
          delivery_enabled: true,
          pickup_enabled: true,
          estimated_delivery_minutes: 35,
          minimum_basket_amount: 150,
          campaign_label: "Pilot fırsat"
        },
        {
          id: "store-002",
          tenant_id: "controlled-pilot",
          store_slug: "demo-firin",
          name: "Demo Fırın",
          category_id: "bakery",
          category_name: "Fırın",
          city: "İstanbul",
          district: "Pilot",
          neighborhood: "Demo Mahalle",
          distance_km: 0.7,
          rating: 4.7,
          review_count: 72,
          status: "OPEN",
          delivery_enabled: false,
          pickup_enabled: true,
          estimated_delivery_minutes: 20,
          minimum_basket_amount: 80,
          campaign_label: "Sıcak ürün"
        },
        {
          id: "store-003",
          tenant_id: "controlled-pilot",
          store_slug: "demo-manav",
          name: "Demo Manav",
          category_id: "greengrocer",
          category_name: "Manav",
          city: "İstanbul",
          district: "Pilot",
          neighborhood: "Demo Mahalle",
          distance_km: 1.1,
          rating: 4.6,
          review_count: 54,
          status: "OPEN",
          delivery_enabled: true,
          pickup_enabled: true,
          estimated_delivery_minutes: 30,
          minimum_basket_amount: 120,
          campaign_label: "Taze"
        },
        {
          id: "store-004",
          tenant_id: "controlled-pilot",
          store_slug: "demo-kasap",
          name: "Demo Kasap",
          category_id: "butcher",
          category_name: "Kasap",
          city: "İstanbul",
          district: "Pilot",
          neighborhood: "Demo Mahalle",
          distance_km: 1.8,
          rating: 4.9,
          review_count: 41,
          status: "CLOSED",
          delivery_enabled: true,
          pickup_enabled: false,
          estimated_delivery_minutes: 45,
          minimum_basket_amount: 250,
          campaign_label: "Kapalı"
        }
      ]
    }
  };

  function getRegionContext() {
    const raw = window.localStorage.getItem(CONFIG.regionKey);
    if (!raw) return CONFIG.defaultRegion;

    try {
      return Object.assign({}, CONFIG.defaultRegion, JSON.parse(raw));
    } catch (_error) {
      return CONFIG.defaultRegion;
    }
  }

  function getCustomerSession() {
    const raw = window.localStorage.getItem(CONFIG.customerSessionKey);
    if (!raw) {
      return {
        session_present: false,
        session_id: "ANONYMOUS_DEMO_SESSION",
        real_customer_login_enabled: false
      };
    }

    try {
      return Object.assign({
        session_present: true,
        real_customer_login_enabled: false
      }, JSON.parse(raw));
    } catch (_error) {
      return {
        session_present: false,
        session_id: "INVALID_SESSION",
        real_customer_login_enabled: false
      };
    }
  }

  function marketRegionHeaders() {
    const region = getRegionContext();
    const session = getCustomerSession();

    return {
      "Content-Type": "application/json",
      "X-Market-Region": region.region_code,
      "X-Market-Customer-Session": session.session_id,
      "X-Pix2pi-Surface": "marketplace",
      "X-Pix2pi-Step": "337"
    };
  }

  function normalizeTerm(value) {
    return String(value || "").trim().toLowerCase();
  }

  function moneyTRY(value) {
    try {
      return new Intl.NumberFormat("tr-TR", {
        style: "currency",
        currency: "TRY"
      }).format(Number(value || 0));
    } catch (_error) {
      return String(value || 0) + " TL";
    }
  }

  function validateStoreDiscoveryScope(store) {
    const errors = [];

    if (!store || !store.tenant_id) {
      errors.push({ field: "tenant_id", code: "TENANT_REQUIRED" });
    }

    if (!store || !store.store_slug) {
      errors.push({ field: "store_slug", code: "STORE_SLUG_REQUIRED" });
    }

    if (!store || !store.city || !store.district) {
      errors.push({ field: "region", code: "REGION_REQUIRED" });
    }

    return {
      valid: errors.length === 0,
      errors: errors
    };
  }

  async function apiJson(endpoint) {
    const response = await fetch(endpoint, {
      method: "GET",
      headers: marketRegionHeaders()
    });

    if (!response.ok) {
      throw new Error("MARKET_DISCOVERY_BACKEND_NOT_READY_OR_FAILED");
    }

    return response.json();
  }

  async function fetchDiscoverySnapshot() {
    const region = getRegionContext();

    try {
      return await apiJson(CONFIG.discoverySnapshotEndpoint + "?region=" + encodeURIComponent(region.region_code));
    } catch (_error) {
      const snapshot = JSON.parse(JSON.stringify(CONFIG.fallbackDiscovery));
      snapshot.region = region;
      return snapshot;
    }
  }

  function readDiscoveryFilters(form) {
    const data = {};

    if (!form) {
      return {
        search: "",
        category_id: "all",
        fulfillment: "all",
        open_now: "all",
        sort_by: "nearby"
      };
    }

    new FormData(form).forEach(function (value, key) {
      data[key] = String(value || "").trim();
    });

    return Object.assign({
      search: "",
      category_id: "all",
      fulfillment: "all",
      open_now: "all",
      sort_by: "nearby"
    }, data);
  }

  function applyDiscoveryFilters(stores, filters) {
    const f = filters || {};
    const search = normalizeTerm(f.search);

    let list = (stores || []).filter(function (store) {
      const matchesSearch = !search ||
        normalizeTerm(store.name).indexOf(search) >= 0 ||
        normalizeTerm(store.category_name).indexOf(search) >= 0 ||
        normalizeTerm(store.store_slug).indexOf(search) >= 0;

      const matchesCategory = !f.category_id || f.category_id === "all" || store.category_id === f.category_id;

      const matchesFulfillment = !f.fulfillment || f.fulfillment === "all" ||
        (f.fulfillment === "delivery" && store.delivery_enabled) ||
        (f.fulfillment === "pickup" && store.pickup_enabled);

      const matchesOpen = !f.open_now || f.open_now === "all" ||
        (f.open_now === "open" && store.status === "OPEN");

      return matchesSearch && matchesCategory && matchesFulfillment && matchesOpen;
    });

    return sortStores(list, f.sort_by || "nearby");
  }

  function sortStores(stores, sortBy) {
    const list = (stores || []).slice();

    switch (sortBy) {
      case "rating":
        return list.sort(function (a, b) { return Number(b.rating || 0) - Number(a.rating || 0); });
      case "delivery_eta":
        return list.sort(function (a, b) { return Number(a.estimated_delivery_minutes || 999) - Number(b.estimated_delivery_minutes || 999); });
      case "minimum_basket":
        return list.sort(function (a, b) { return Number(a.minimum_basket_amount || 0) - Number(b.minimum_basket_amount || 0); });
      case "open_first":
        return list.sort(function (a, b) {
          const weight = { OPEN: 0, CLOSED: 1 };
          return (weight[a.status] || 9) - (weight[b.status] || 9);
        });
      default:
        return list.sort(function (a, b) { return Number(a.distance_km || 999) - Number(b.distance_km || 999); });
    }
  }

  function buildDiscoveryContract(snapshot, filters, visibleStores) {
    return {
      region: snapshot.region,
      customer_session: getCustomerSession(),
      total_store_count: Array.isArray(snapshot.stores) ? snapshot.stores.length : 0,
      visible_store_count: Array.isArray(visibleStores) ? visibleStores.length : 0,
      filters: filters,
      runtime_contract: CONFIG.runtimeContract,
      scope_valid: (visibleStores || []).every(function (store) {
        return validateStoreDiscoveryScope(store).valid;
      }),
      source: {
        surface: "market_discovery",
        phase: "FAZ_7R",
        step: "337"
      }
    };
  }

  function buildStoreQuickPreview(store) {
    return {
      store_id: store.id,
      tenant_id: store.tenant_id,
      store_slug: store.store_slug,
      name: store.name,
      category_name: store.category_name,
      status: store.status,
      distance_label: store.distance_km + " km",
      rating_label: "★ " + store.rating + " (" + store.review_count + ")",
      delivery_label: store.delivery_enabled ? "Teslimat var" : "Teslimat yok",
      pickup_label: store.pickup_enabled ? "Gel-al var" : "Gel-al yok",
      min_basket_label: moneyTRY(store.minimum_basket_amount),
      storefront_url: "/storefront/?store=" + encodeURIComponent(store.store_slug),
      products_url: "/products/?store=" + encodeURIComponent(store.store_slug),
      order_enabled: CONFIG.runtimeContract.realOrderEnabled
    };
  }

  function renderRegionContext(snapshot) {
    const region = snapshot.region || getRegionContext();

    const city = document.getElementById("discovery-city");
    const district = document.getElementById("discovery-district");
    const neighborhood = document.getElementById("discovery-neighborhood");
    const code = document.getElementById("discovery-region-code");

    if (city) city.textContent = region.city;
    if (district) district.textContent = region.district;
    if (neighborhood) neighborhood.textContent = region.neighborhood;
    if (code) code.textContent = region.region_code;
  }

  function renderCustomerSession() {
    const target = document.getElementById("discovery-customer-session");
    const session = getCustomerSession();

    if (target) {
      target.textContent = session.session_present ? "SESSION_PRESENT" : "ANONYMOUS_PLACEHOLDER";
      target.setAttribute("data-real-customer-login-enabled", String(CONFIG.runtimeContract.realCustomerLoginEnabled));
    }
  }

  function renderCategoryCards(snapshot) {
    const target = document.getElementById("discovery-category-cards");
    if (!target) return;

    target.innerHTML = "";

    (snapshot.categories || []).forEach(function (category) {
      const card = document.createElement("article");
      card.className = "category-card";
      card.setAttribute("data-category-id", category.id);
      card.innerHTML = [
        "<span>" + category.emoji + "</span>",
        "<strong>" + category.name + "</strong>",
        "<p>" + category.store_count + " mağaza</p>"
      ].join("");
      target.appendChild(card);
    });
  }

  function renderCampaignStrips(snapshot) {
    const target = document.getElementById("discovery-campaign-strips");
    if (!target) return;

    target.innerHTML = "";

    (snapshot.campaigns || []).forEach(function (campaign) {
      const strip = document.createElement("article");
      strip.className = "campaign-strip";
      strip.setAttribute("data-campaign-id", campaign.id);
      strip.innerHTML = [
        "<strong>" + campaign.title + "</strong>",
        "<p>" + campaign.description + "</p>",
        "<span>" + campaign.tag + "</span>"
      ].join("");
      target.appendChild(strip);
    });
  }

  function renderStoreGrid(stores) {
    const target = document.getElementById("discovery-store-grid");
    if (!target) return;

    target.innerHTML = "";

    (stores || []).forEach(function (store) {
      const preview = buildStoreQuickPreview(store);
      const card = document.createElement("article");
      card.className = "store-card";
      card.setAttribute("data-store-slug", store.store_slug);
      card.setAttribute("data-store-status", store.status);
      card.innerHTML = [
        "<span class='status " + store.status.toLowerCase() + "'>" + store.status + "</span>",
        "<strong>" + store.name + "</strong>",
        "<p>" + store.category_name + " / " + store.neighborhood + " / " + preview.distance_label + "</p>",
        "<p>" + preview.rating_label + " / ETA " + store.estimated_delivery_minutes + " dk</p>",
        "<p>" + preview.delivery_label + " / " + preview.pickup_label + " / Min " + preview.min_basket_label + "</p>",
        "<span class='deal'>" + store.campaign_label + "</span>",
        "<button type='button' data-preview-store='" + store.store_slug + "'>Quick preview</button>",
        "<a href='" + preview.storefront_url + "'>Vitrine git</a>",
        "<a href='" + preview.products_url + "'>Ürünlere git</a>"
      ].join("");

      card.querySelector("[data-preview-store]").addEventListener("click", function () {
        renderStoreQuickPreview(preview);
      });

      target.appendChild(card);
    });
  }

  function renderStoreQuickPreview(preview) {
    const target = document.getElementById("discovery-store-quick-preview");
    if (!target) return;

    target.innerHTML = [
      "<strong>" + preview.name + "</strong>",
      "<p>Store: " + preview.store_slug + " / " + preview.category_name + "</p>",
      "<p>" + preview.status + " / " + preview.distance_label + " / " + preview.rating_label + "</p>",
      "<p>" + preview.delivery_label + " / " + preview.pickup_label + " / Min: " + preview.min_basket_label + "</p>",
      "<p>Deep-link: " + preview.storefront_url + " / " + preview.products_url + "</p>",
      "<p>Order enabled: false</p>"
    ].join("");
    target.setAttribute("data-preview-store-slug", preview.store_slug);
  }

  function renderDiscoverySummary(contract) {
    const total = document.getElementById("discovery-total-store-count");
    const visible = document.getElementById("discovery-visible-store-count");
    const scope = document.getElementById("discovery-scope-validation");

    if (total) total.textContent = String(contract.total_store_count);
    if (visible) visible.textContent = String(contract.visible_store_count);
    if (scope) {
      scope.textContent = contract.scope_valid ? "VALID" : "INVALID";
      scope.setAttribute("data-validation-status", contract.scope_valid ? "valid" : "invalid");
    }
  }

  function renderDiscoveryFilterOptions(snapshot) {
    const categorySelect = document.getElementById("discovery-category-filter");
    if (!categorySelect) return;

    categorySelect.innerHTML = "<option value='all'>Tüm kategoriler</option>";

    (snapshot.categories || []).forEach(function (category) {
      const option = document.createElement("option");
      option.value = category.id;
      option.textContent = category.name;
      categorySelect.appendChild(option);
    });
  }

  async function applyFiltersFromForm(form) {
    const snapshot = await fetchDiscoverySnapshot();
    const filters = readDiscoveryFilters(form);
    const visibleStores = applyDiscoveryFilters(snapshot.stores, filters);
    const contract = buildDiscoveryContract(snapshot, filters, visibleStores);

    renderStoreGrid(visibleStores);
    renderDiscoverySummary(contract);
    document.body.setAttribute("data-market-discovery-filtered", "true");
    return contract;
  }

  async function bootDiscoveryScreen() {
    const snapshot = await fetchDiscoverySnapshot();
    const filters = readDiscoveryFilters(document.getElementById("discovery-filter-form"));
    const visibleStores = applyDiscoveryFilters(snapshot.stores, filters);
    const contract = buildDiscoveryContract(snapshot, filters, visibleStores);

    renderRegionContext(snapshot);
    renderCustomerSession();
    renderCategoryCards(snapshot);
    renderCampaignStrips(snapshot);
    renderDiscoveryFilterOptions(snapshot);
    renderStoreGrid(visibleStores);
    renderDiscoverySummary(contract);

    document.body.setAttribute("data-market-discovery-rendered", "true");
    return contract;
  }

  window.Pix2piMarketDiscovery = {
    CONFIG: CONFIG,
    getRegionContext: getRegionContext,
    getCustomerSession: getCustomerSession,
    marketRegionHeaders: marketRegionHeaders,
    validateStoreDiscoveryScope: validateStoreDiscoveryScope,
    fetchDiscoverySnapshot: fetchDiscoverySnapshot,
    readDiscoveryFilters: readDiscoveryFilters,
    applyDiscoveryFilters: applyDiscoveryFilters,
    sortStores: sortStores,
    buildDiscoveryContract: buildDiscoveryContract,
    buildStoreQuickPreview: buildStoreQuickPreview,
    renderRegionContext: renderRegionContext,
    renderCustomerSession: renderCustomerSession,
    renderCategoryCards: renderCategoryCards,
    renderCampaignStrips: renderCampaignStrips,
    renderStoreGrid: renderStoreGrid,
    renderStoreQuickPreview: renderStoreQuickPreview,
    renderDiscoverySummary: renderDiscoverySummary,
    renderDiscoveryFilterOptions: renderDiscoveryFilterOptions,
    applyFiltersFromForm: applyFiltersFromForm,
    bootDiscoveryScreen: bootDiscoveryScreen,
    moneyTRY: moneyTRY
  };
})();
/* PIX2PI_337_MARKET_DISCOVERY_RUNTIME_END */
