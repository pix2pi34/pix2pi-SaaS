export type RuntimeTopologyHealth = {
  status: string;
  service: string;
  db: string;
  port: string;
};

export type RuntimeTopologySummaryItem = {
  topologyStatus: string;
  nodeCount: number;
  nodeOKCount: number;
  nodeFailCount: number;
  edgeCount: number;
  registryServiceCount: number;
  registryInstanceCount: number;
  registryHeartbeatCount: number;
  generatedAt: string;
};

export type RuntimeTopologyNode = {
  nodeKey: string;
  display: string;
  nodeType: string;
  layer: string;
  checkMode: string;
  port: string;
  url: string;
  address: string;
  status: string;
  httpStatus: number;
  latencyMs: number;
  message: string;
  checkedAt: string;
};

export type RuntimeTopologyEdge = {
  fromNode: string;
  toNode: string;
  relation: string;
  protocol: string;
};

export type RuntimeTopologyRegistryItem = {
  tableName: string;
  count: number;
  generatedAt: string;
};

export type RuntimeTopologyOverview = {
  health: RuntimeTopologyHealth;
  summary: RuntimeTopologySummaryItem[];
  nodes: RuntimeTopologyNode[];
  edges: RuntimeTopologyEdge[];
  registry: RuntimeTopologyRegistryItem[];
};
