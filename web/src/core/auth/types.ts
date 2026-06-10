export type SessionUser = {
  id: string;
  fullName: string;
  email: string;
  isSuperAdmin: boolean;
};

export type SessionTenant = {
  id: string;
  name: string;
  slug: string;
};

export type SessionRole = {
  code: string;
  label: string;
};

export type SessionResponse = {
  accessToken: string;
  expiresAt: string;
  user: SessionUser;
  activeTenant: SessionTenant;
  tenants: SessionTenant[];
  roles: SessionRole[];
};

