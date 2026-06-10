export type PluginRuntimeHealth = {
  status: string;
  service: string;
  db: string;
  port: string;
};

export type PluginSummaryItem = {
  status: string;
  count: number;
  pluginCount: number;
  stateCount: number;
  generatedAt: string;
};

export type PluginCatalogRow = {
  pluginKey: string;
  displayName: string;
  versionNo: string;
  visibilityScope: string;
  sourceType: string;
  lifecycleStatus: string;
  entrypointRef: string;
  checksum: string;
  requiredPlatformVersion: string;
  isEnabled: boolean;
  publishedAt: string;
  deprecatedAt: string;
  archivedAt: string;
  createdAt: string;
  updatedAt: string;
};

export type PluginStateRow = {
  stateId: string;
  pluginKey: string;
  stateKey: string;
  desiredState: string;
  currentState: string;
  installRef: string;
  installedAt: string;
  activatedAt: string;
  deactivatedAt: string;
  lastHealthAt: string;
  lastError: string;
  createdAt: string;
  updatedAt: string;
};

export type PluginMonitorOverview = {
  health: PluginRuntimeHealth;
  summary: PluginSummaryItem[];
  catalog: PluginCatalogRow[];
  states: PluginStateRow[];
  runtime: PluginStateRow[];
};
