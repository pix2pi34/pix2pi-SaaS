export type RuntimeConfig = {
  apiBaseUrl: string;
  environmentName: string;
  appName: string;
};

const defaultConfig: RuntimeConfig = {
  apiBaseUrl: 'http://localhost:9010',
  environmentName: 'local',
  appName: 'Pix2pi',
};

export function getRuntimeConfig(): RuntimeConfig {
  const runtimeWindow = window as typeof window & {
    __PIX2PI_RUNTIME_CONFIG__?: Partial<RuntimeConfig>;
  };

  return {
    ...defaultConfig,
    ...(runtimeWindow.__PIX2PI_RUNTIME_CONFIG__ ?? {}),
  };
}

