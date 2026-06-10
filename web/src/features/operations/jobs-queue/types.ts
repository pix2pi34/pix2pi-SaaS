export type JobsQueueRuntimeHealth = {
  status: string;
  service: string;
  db: string;
  port: string;
};

export type JobsSummaryItem = {
  status: string;
  count: number;
  queueCount: number;
  attemptCount: number;
  generatedAt: string;
};

export type JobsQueueRow = {
  queueKey: string;
  displayName: string;
  visibilityScope: string;
  isEnabled: boolean;
  maxConcurrency: number;
  retryLimit: number;
  retryBackoffSeconds: number;
  deadLetterQueueKey: string;
  queuedCount: number;
  processingCount: number;
  failedCount: number;
  deadLetterCount: number;
  updatedAt: string;
};

export type JobsRecentRow = {
  jobId: string;
  queueKey: string;
  jobKey: string;
  jobType: string;
  priority: string;
  status: string;
  retryCount: number;
  maxAttempts: number;
  lastError: string;
  lockedBy: string;
  availableAt: string;
  createdAt: string;
  updatedAt: string;
};

export type JobsQueueOverview = {
  health: JobsQueueRuntimeHealth;
  summary: JobsSummaryItem[];
  queues: JobsQueueRow[];
  recent: JobsRecentRow[];
};
