import type {
  JobsQueueOverview,
  JobsQueueRow,
  JobsQueueRuntimeHealth,
  JobsRecentRow,
  JobsSummaryItem,
} from './types';

type FetchLike = (input: RequestInfo | URL, init?: RequestInit) => Promise<Response>;

type JobsQueueFetchOptions = {
  accessToken?: string;
  tenantId?: string;
};

function buildHeaders(options: JobsQueueFetchOptions): Record<string, string> {
  const headers: Record<string, string> = {
    Accept: 'application/json',
  };

  if (options.accessToken) {
    headers.Authorization = `Bearer ${options.accessToken}`;
  }

  if (options.tenantId) {
    headers['X-Tenant-ID'] = options.tenantId;
  }

  return headers;
}

function asText(value: unknown, fallback = ''): string {
  if (typeof value === 'string') {
    return value;
  }

  if (typeof value === 'number' || typeof value === 'boolean') {
    return String(value);
  }

  return fallback;
}

function asNumber(value: unknown): number {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return value;
  }

  if (typeof value === 'string') {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : 0;
  }

  return 0;
}

function asBool(value: unknown): boolean {
  if (typeof value === 'boolean') {
    return value;
  }

  if (typeof value === 'string') {
    return value.toLowerCase() === 'true';
  }

  return false;
}

function normalizeSummaryItem(raw: Record<string, unknown>): JobsSummaryItem {
  return {
    status: asText(raw.status, 'unknown'),
    count: asNumber(raw.count),
    queueCount: asNumber(raw.queue_count ?? raw.queueCount),
    attemptCount: asNumber(raw.attempt_count ?? raw.attemptCount),
    generatedAt: asText(raw.generated_at ?? raw.generatedAt, '-'),
  };
}

function normalizeQueueRow(raw: Record<string, unknown>): JobsQueueRow {
  return {
    queueKey: asText(raw.queue_key ?? raw.queueKey, '-'),
    displayName: asText(raw.display_name ?? raw.displayName, '-'),
    visibilityScope: asText(raw.visibility_scope ?? raw.visibilityScope, '-'),
    isEnabled: asBool(raw.is_enabled ?? raw.isEnabled),
    maxConcurrency: asNumber(raw.max_concurrency ?? raw.maxConcurrency),
    retryLimit: asNumber(raw.retry_limit ?? raw.retryLimit),
    retryBackoffSeconds: asNumber(raw.retry_backoff_seconds ?? raw.retryBackoffSeconds),
    deadLetterQueueKey: asText(raw.dead_letter_queue_key ?? raw.deadLetterQueueKey, '-'),
    queuedCount: asNumber(raw.queued_count ?? raw.queuedCount),
    processingCount: asNumber(raw.processing_count ?? raw.processingCount),
    failedCount: asNumber(raw.failed_count ?? raw.failedCount),
    deadLetterCount: asNumber(raw.dead_letter_count ?? raw.deadLetterCount),
    updatedAt: asText(raw.updated_at ?? raw.updatedAt, '-'),
  };
}

function normalizeRecentRow(raw: Record<string, unknown>): JobsRecentRow {
  return {
    jobId: asText(raw.job_id ?? raw.jobId, '-'),
    queueKey: asText(raw.queue_key ?? raw.queueKey, '-'),
    jobKey: asText(raw.job_key ?? raw.jobKey, '-'),
    jobType: asText(raw.job_type ?? raw.jobType, '-'),
    priority: asText(raw.priority, '-'),
    status: asText(raw.status, '-'),
    retryCount: asNumber(raw.retry_count ?? raw.retryCount),
    maxAttempts: asNumber(raw.max_attempts ?? raw.maxAttempts),
    lastError: asText(raw.last_error ?? raw.lastError, ''),
    lockedBy: asText(raw.locked_by ?? raw.lockedBy, ''),
    availableAt: asText(raw.available_at ?? raw.availableAt, '-'),
    createdAt: asText(raw.created_at ?? raw.createdAt, '-'),
    updatedAt: asText(raw.updated_at ?? raw.updatedAt, '-'),
  };
}

function listFromPayload(payload: unknown): Record<string, unknown>[] {
  if (!payload || typeof payload !== 'object') {
    return [];
  }

  const obj = payload as Record<string, unknown>;
  const items = obj.items;

  if (!Array.isArray(items)) {
    return [];
  }

  return items
    .filter((item): item is Record<string, unknown> => Boolean(item) && typeof item === 'object' && !Array.isArray(item));
}

export function normalizeJobsSummary(payload: unknown): JobsSummaryItem[] {
  return listFromPayload(payload).map(normalizeSummaryItem);
}

export function normalizeJobsQueues(payload: unknown): JobsQueueRow[] {
  return listFromPayload(payload).map(normalizeQueueRow);
}

export function normalizeRecentJobs(payload: unknown): JobsRecentRow[] {
  return listFromPayload(payload).map(normalizeRecentRow);
}

export async function fetchJobsQueueOverview(
  options: JobsQueueFetchOptions = {},
  fetcher: FetchLike = globalThis.fetch,
): Promise<JobsQueueOverview> {
  if (!fetcher) {
    throw new Error('fetch kullanilabilir degil');
  }

  const headers = buildHeaders(options);

  const [healthResponse, summaryResponse, queuesResponse, recentResponse] = await Promise.all([
    fetcher('/jobs-runtime/health', { headers }),
    fetcher('/jobs-runtime/api/jobs/summary', { headers }),
    fetcher('/jobs-runtime/api/jobs/queues', { headers }),
    fetcher('/jobs-runtime/api/jobs/recent?limit=25', { headers }),
  ]);

  if (!healthResponse.ok) {
    throw new Error(`jobs runtime health okunamadi: ${healthResponse.status}`);
  }

  if (!summaryResponse.ok) {
    throw new Error(`jobs summary okunamadi: ${summaryResponse.status}`);
  }

  if (!queuesResponse.ok) {
    throw new Error(`jobs queues okunamadi: ${queuesResponse.status}`);
  }

  if (!recentResponse.ok) {
    throw new Error(`recent jobs okunamadi: ${recentResponse.status}`);
  }

  const health = await healthResponse.json() as JobsQueueRuntimeHealth;
  const summaryPayload = await summaryResponse.json();
  const queuesPayload = await queuesResponse.json();
  const recentPayload = await recentResponse.json();

  return {
    health,
    summary: normalizeJobsSummary(summaryPayload),
    queues: normalizeJobsQueues(queuesPayload),
    recent: normalizeRecentJobs(recentPayload),
  };
}
