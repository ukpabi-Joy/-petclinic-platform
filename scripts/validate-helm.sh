#!/usr/bin/env bash
#
# validate-helm.sh (PetclinicPlatform110) — lint and render the petclinic-service
# Helm chart for every service against both environments.
#
# For each of the 8 services and each env (dev, prod) it runs:
#   1. helm lint   — chart + merged values are well-formed
#   2. helm template --debug  — manifests render without error
# and, when a kubectl cluster is reachable, pipes the rendered output through
#   3. kubectl apply --dry-run=client  — server-side schema validation
# (skipped automatically when no cluster is reachable, e.g. in CI without EKS).
#
# Usage:  scripts/validate-helm.sh
# Exit:   non-zero if any lint/template/dry-run step fails.
set -euo pipefail

# Resolve repo root from this script's location so it works from any CWD.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
CHART="${ROOT_DIR}/helm/petclinic-service"
VALUES_DIR="${ROOT_DIR}/helm-values"

SERVICES=(
  config-server
  discovery-server
  customers-service
  visits-service
  vets-service
  genai-service
  api-gateway
  admin-server
)
ENVIRONMENTS=(dev prod)

fail=0

# Detect a reachable cluster once; only then attempt the dry-run step.
DRYRUN=0
if kubectl cluster-info >/dev/null 2>&1; then
  DRYRUN=1
  echo "==> Cluster reachable: kubectl apply --dry-run=client enabled"
else
  echo "==> No reachable cluster: skipping kubectl apply --dry-run=client (offline mode)"
fi
echo

for svc in "${SERVICES[@]}"; do
  svc_values="${VALUES_DIR}/${svc}.yaml"
  if [[ ! -f "${svc_values}" ]]; then
    echo "MISSING per-service values: ${svc_values}"
    fail=1
    continue
  fi

  for env in "${ENVIRONMENTS[@]}"; do
    env_values="${VALUES_DIR}/${env}.yaml"
    release="${svc}"
    ns="petclinic-${env}"
    echo "==================================================================="
    echo "Service: ${svc}  |  Env: ${env}  |  Namespace: ${ns}"
    echo "==================================================================="

    # 1. lint
    if helm lint "${CHART}" -f "${svc_values}" -f "${env_values}" >/dev/null; then
      echo "  [ok]   helm lint"
    else
      echo "  [FAIL] helm lint"
      helm lint "${CHART}" -f "${svc_values}" -f "${env_values}" || true
      fail=1
    fi

    # 2. template
    rendered="$(helm template "${release}" "${CHART}" \
      --namespace "${ns}" \
      -f "${svc_values}" -f "${env_values}" 2>/tmp/helm-tmpl-err.txt)" || {
        echo "  [FAIL] helm template"
        cat /tmp/helm-tmpl-err.txt
        fail=1
        continue
      }
    echo "  [ok]   helm template ($(printf '%s' "${rendered}" | grep -c '^kind:') objects)"

    # 3. dry-run (only if a cluster is reachable)
    if [[ "${DRYRUN}" -eq 1 ]]; then
      if printf '%s' "${rendered}" | kubectl apply --dry-run=client -f - >/dev/null 2>/tmp/helm-dryrun-err.txt; then
        echo "  [ok]   kubectl apply --dry-run=client"
      else
        echo "  [FAIL] kubectl apply --dry-run=client"
        cat /tmp/helm-dryrun-err.txt
        fail=1
      fi
    fi
    echo
  done
done

echo "==================================================================="
if [[ "${fail}" -eq 0 ]]; then
  echo "All Helm validations passed."
else
  echo "Helm validation FAILED — see [FAIL] lines above."
fi
exit "${fail}"
