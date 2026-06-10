import type {
  ReleaseReadiness,
  RuntimeSafetyGate,
} from './runtimeConfig'
import type { RuntimeSecurityGuard } from './runtimeSecurity'

export type ValidationClosureCheck = {
  id: string
  label: string
  status: 'pass' | 'warn'
}

export type ValidationClosure = {
  status: 'ready' | 'warning'
  checks: ValidationClosureCheck[]
}

export type ReleaseCandidateCheck = {
  id: string
  label: string
  status: 'pass' | 'warn' | 'block'
}

export type ReleaseCandidateClosure = {
  status: 'ready' | 'warning' | 'block'
  title: string
  description: string
  checks: ReleaseCandidateCheck[]
}

type EvaluateInput = {
  runtimeSafetyGate: RuntimeSafetyGate
  runtimeSecurityGuard: RuntimeSecurityGuard
  releaseReadiness: ReleaseReadiness
}

export function evaluateValidationClosure(
  input: EvaluateInput,
): ValidationClosure {
  const checks: ValidationClosureCheck[] = [
    {
      id: 'runtime-safety-validation',
      label: 'Runtime safety validation',
      status: input.runtimeSafetyGate.status === 'block' ? 'warn' : 'pass',
    },
    {
      id: 'runtime-security-validation',
      label: 'Runtime security validation',
      status: input.runtimeSecurityGuard.status === 'pass' ? 'pass' : 'warn',
    },
    {
      id: 'release-readiness-validation',
      label: 'Release readiness validation',
      status: input.releaseReadiness.status === 'ready' ? 'pass' : 'warn',
    },
  ]

  const hasWarn = checks.some((item) => item.status === 'warn')

  return {
    status: hasWarn ? 'warning' : 'ready',
    checks,
  }
}

export function evaluateReleaseCandidateClosure(
  input: EvaluateInput,
): ReleaseCandidateClosure {
  const checks: ReleaseCandidateCheck[] = [
    {
      id: 'rc-runtime-safety',
      label: 'RC runtime safety gate',
      status:
        input.runtimeSafetyGate.status === 'block'
          ? 'block'
          : input.runtimeSafetyGate.status === 'warning'
            ? 'warn'
            : 'pass',
    },
    {
      id: 'rc-runtime-security',
      label: 'RC runtime security guard',
      status:
        input.runtimeSecurityGuard.status === 'block'
          ? 'block'
          : input.runtimeSecurityGuard.status === 'warning'
            ? 'warn'
            : 'pass',
    },
    {
      id: 'rc-release-readiness',
      label: 'RC release readiness gate',
      status: input.releaseReadiness.status === 'ready' ? 'pass' : 'warn',
    },
    {
      id: 'rc-final-gate',
      label: 'RC final gate',
      status:
        input.runtimeSafetyGate.status === 'block' ||
        input.runtimeSecurityGuard.status === 'block'
          ? 'block'
          : input.runtimeSafetyGate.status === 'warning' ||
              input.runtimeSecurityGuard.status === 'warning' ||
              input.releaseReadiness.status === 'warning'
            ? 'warn'
            : 'pass',
    },
  ]

  const hasBlock = checks.some((item) => item.status === 'block')
  const hasWarn = checks.some((item) => item.status === 'warn')

  if (hasBlock) {
    return {
      status: 'block',
      title: 'Release candidate blocked',
      description:
        'Release candidate gate block verdi. Bu konfigurasyonla release onerilmez.',
      checks,
    }
  }

  if (hasWarn) {
    return {
      status: 'warning',
      title: 'Release candidate warning',
      description:
        'Release candidate warning modunda. Manuel smoke ve son kontrol onerilir.',
      checks,
    }
  }

  return {
    status: 'ready',
    title: 'Release candidate ready',
    description:
      'Release candidate gate tum kontrolleri gecti. LVL9 kapanisina hazir.',
    checks,
  }
}
