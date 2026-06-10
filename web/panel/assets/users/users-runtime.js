/* PIX2PI_321_USERS_RUNTIME_START */
(function () {
  "use strict";

  const CONFIG = {
    listEndpoint: "/api/panel/users",
    inviteEndpoint: "/api/panel/users/invite",
    assignRoleEndpoint: "/api/panel/users/assign-role",
    statusEndpoint: "/api/panel/users/status",
    selectedTenantKey: "pix2pi.panel.tenant.preference",
    jwtKey: "pix2pi.panel.jwt",
    roles: ["OWNER_ADMIN", "MANAGER", "ACCOUNTANT", "CASHIER", "STAFF", "READONLY"],
    statuses: ["ACTIVE", "INVITED", "SUSPENDED", "DISABLED"],
    fallbackUsers: [
      {
        id: "usr_owner_demo",
        name: "Demo Owner",
        email: "owner@pix2pi.test",
        role: "OWNER_ADMIN",
        status: "ACTIVE",
        personnel_type: "owner"
      },
      {
        id: "usr_cashier_demo",
        name: "Demo Kasiyer",
        email: "cashier@pix2pi.test",
        role: "CASHIER",
        status: "INVITED",
        personnel_type: "staff"
      }
    ]
  };

  function getSelectedTenantId() {
    return window.localStorage.getItem(CONFIG.selectedTenantKey) || "controlled-pilot";
  }

  function getJwt() {
    return window.localStorage.getItem(CONFIG.jwtKey) || "";
  }

  function tenantScopedHeaders() {
    const token = getJwt();
    return {
      "Content-Type": "application/json",
      "Authorization": token ? "Bearer " + token : "",
      "X-Tenant-ID": getSelectedTenantId(),
      "X-Pix2pi-Surface": "panel",
      "X-Pix2pi-Step": "321"
    };
  }

  function validateInvitePayload(payload) {
    const errors = [];

    if (!payload.name) {
      errors.push({ field: "name", code: "REQUIRED" });
    }

    if (!payload.email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(payload.email)) {
      errors.push({ field: "email", code: "INVALID_EMAIL" });
    }

    if (!payload.role || CONFIG.roles.indexOf(payload.role) === -1) {
      errors.push({ field: "role", code: "INVALID_ROLE" });
    }

    return {
      valid: errors.length === 0,
      errors
    };
  }

  function buildInvitePayload(payload) {
    return {
      tenant_id: getSelectedTenantId(),
      name: payload.name,
      email: payload.email,
      role: payload.role,
      personnel_type: payload.personnel_type || "staff",
      source: "panel_users_screen",
      phase: "FAZ_7R",
      step: "321"
    };
  }

  function buildRoleAssignmentPayload(userId, role) {
    return {
      tenant_id: getSelectedTenantId(),
      user_id: userId,
      role,
      source: "panel_users_screen",
      step: "321"
    };
  }

  function buildStatusUpdatePayload(userId, status) {
    return {
      tenant_id: getSelectedTenantId(),
      user_id: userId,
      status,
      source: "panel_users_screen",
      step: "321"
    };
  }

  function buildPermissionMatrix(role) {
    const matrix = {
      OWNER_ADMIN: ["users:manage", "billing:manage", "erp:manage", "pos:manage", "reports:view"],
      MANAGER: ["erp:manage", "pos:manage", "reports:view"],
      ACCOUNTANT: ["erp:accounting", "documents:export", "reports:view"],
      CASHIER: ["pos:sell", "pos:return"],
      STAFF: ["erp:view", "pos:view"],
      READONLY: ["reports:view"]
    };

    return matrix[role] || [];
  }

  async function apiJson(endpoint, options) {
    const response = await fetch(endpoint, Object.assign({
      headers: tenantScopedHeaders()
    }, options || {}));

    if (!response.ok) {
      throw new Error("USERS_BACKEND_NOT_READY_OR_FAILED");
    }

    return response.json();
  }

  async function fetchUsers() {
    try {
      return await apiJson(CONFIG.listEndpoint, { method: "GET" });
    } catch (_error) {
      return {
        tenant_id: getSelectedTenantId(),
        users: CONFIG.fallbackUsers
      };
    }
  }

  async function inviteUser(payload) {
    const validation = validateInvitePayload(payload);
    if (!validation.valid) {
      return { invited: false, validation };
    }

    const invitePayload = buildInvitePayload(payload);

    try {
      const response = await apiJson(CONFIG.inviteEndpoint, {
        method: "POST",
        body: JSON.stringify(invitePayload)
      });

      return { invited: true, validation, response };
    } catch (_error) {
      return { invited: false, validation, fallback_payload: invitePayload };
    }
  }

  async function assignRole(userId, role) {
    const payload = buildRoleAssignmentPayload(userId, role);

    try {
      return await apiJson(CONFIG.assignRoleEndpoint, {
        method: "POST",
        body: JSON.stringify(payload)
      });
    } catch (_error) {
      return payload;
    }
  }

  async function updateUserStatus(userId, status) {
    const payload = buildStatusUpdatePayload(userId, status);

    try {
      return await apiJson(CONFIG.statusEndpoint, {
        method: "POST",
        body: JSON.stringify(payload)
      });
    } catch (_error) {
      return payload;
    }
  }

  function renderUsers(target, users) {
    if (!target) return;

    target.innerHTML = "";

    users.forEach(function (user) {
      const row = document.createElement("article");
      row.className = "user-row";
      row.setAttribute("data-user-id", user.id);
      row.setAttribute("data-user-role", user.role);
      row.setAttribute("data-user-status", user.status);
      row.innerHTML = [
        "<div>",
        "<strong>" + user.name + "</strong>",
        "<p>" + user.email + "</p>",
        "</div>",
        "<span class='pill'>" + user.role + "</span>",
        "<span class='pill' data-status='" + user.status + "'>" + user.status + "</span>"
      ].join("");
      target.appendChild(row);
    });
  }

  async function bootUsersScreen() {
    const result = await fetchUsers();
    const users = result.users || [];
    renderUsers(document.getElementById("users-list"), users);

    const matrixTarget = document.getElementById("permission-matrix-preview");
    if (matrixTarget) {
      matrixTarget.textContent = buildPermissionMatrix("OWNER_ADMIN").join(", ");
    }

    document.body.setAttribute("data-users-rendered", "true");
    return result;
  }

  window.Pix2piUsers = {
    CONFIG,
    getSelectedTenantId,
    getJwt,
    tenantScopedHeaders,
    validateInvitePayload,
    buildInvitePayload,
    buildRoleAssignmentPayload,
    buildStatusUpdatePayload,
    buildPermissionMatrix,
    fetchUsers,
    inviteUser,
    assignRole,
    updateUserStatus,
    renderUsers,
    bootUsersScreen
  };
})();
/* PIX2PI_321_USERS_RUNTIME_END */
