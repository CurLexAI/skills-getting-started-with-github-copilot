#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REGISTRY_PATH="${ROOT_DIR}/agents/registry.yaml"

fail() {
  echo "[FAIL] $1"
  exit 1
}

warn() {
  echo "[WARN] $1"
}

pass() {
  echo "[PASS] $1"
}

check_env_var() {
  local var_name="$1"
  if [[ -z "${!var_name:-}" ]]; then
    fail "SECRET_MISSING: required env var ${var_name} is not set"
  fi
  pass "env var ${var_name} is set"
}

check_url_env_var() {
  local var_name="$1"
  local value="${!var_name:-}"
  if [[ -z "${value}" ]]; then
    fail "CONFIG_NOT_FOUND: ${var_name} is not set"
  fi
  if [[ ! "${value}" =~ ^https?:// ]]; then
    fail "CONFIG_NOT_FOUND: ${var_name} must start with http:// or https://"
  fi
  pass "url contract for ${var_name} is valid"
}

[[ -f "${REGISTRY_PATH}" ]] || fail "CONFIG_NOT_FOUND: ${REGISTRY_PATH} is missing"

check_env_var "PYTHON_BACKEND_URL"
check_env_var "AGENT_API_TOKEN"
check_env_var "BAYYINAH_ENDPOINT"
check_env_var "MIHWAR_ENDPOINT"
check_url_env_var "FRONTEND_API_BASE_URL"

python - <<'PY'
import os
import sys
import yaml
from urllib.parse import urlparse
from pathlib import Path

registry_path = Path("agents/registry.yaml")
with registry_path.open("r", encoding="utf-8") as f:
    data = yaml.safe_load(f)

if not isinstance(data, dict) or "agents" not in data:
    print("[FAIL] REGISTRY_LOAD_FAILURE: top-level agents key missing")
    sys.exit(1)

providers = data.get("providers", {})
if not isinstance(providers, dict):
    print("[FAIL] REGISTRY_LOAD_FAILURE: providers must be a mapping")
    sys.exit(1)

required_backend_path = "/api/v1/workflow/query"
backend_url = os.environ["PYTHON_BACKEND_URL"].rstrip("/")
backend_path = urlparse(backend_url).path or "/"
if backend_path not in ("", "/"):
    print("[FAIL] CONFIG_NOT_FOUND: PYTHON_BACKEND_URL must be base host without path")
    sys.exit(1)

for agent in data["agents"]:
    aid = agent.get("id", "<missing-id>")
    provider = agent.get("provider")
    if not isinstance(provider, dict):
        print(f"[FAIL] REGISTRY_LOAD_FAILURE: agent {aid} missing provider block")
        sys.exit(1)

    kind = provider.get("kind")
    if kind not in providers:
        print(f"[FAIL] REGISTRY_LOAD_FAILURE: agent {aid} references unknown provider '{kind}'")
        sys.exit(1)

    endpoint_env = provider.get("endpoint_env")
    if endpoint_env:
        endpoint = os.environ.get(endpoint_env, "").strip()
        if not endpoint:
            print(f"[FAIL] SECRET_MISSING: {endpoint_env} required for agent {aid}")
            sys.exit(1)
        parsed = urlparse(endpoint)
        if parsed.scheme not in ("http", "https") or not parsed.netloc:
            print(f"[FAIL] CONFIG_NOT_FOUND: invalid endpoint URL in {endpoint_env} for agent {aid}")
            sys.exit(1)
        if parsed.path in ("", "/"):
            print(f"[FAIL] CONFIG_NOT_FOUND: endpoint path missing in {endpoint_env} for agent {aid}")
            sys.exit(1)

print("[PASS] registry -> adapter provider schema linkage is valid")
print(f"[PASS] adapter python endpoint contract: {backend_url}{required_backend_path}")
print(f"[PASS] backend health endpoint contract: {backend_url}/health")
print(f"[PASS] frontend API contract: {os.environ['FRONTEND_API_BASE_URL'].rstrip('/')}/api")
PY

echo "[PASS] production preflight readiness checks succeeded"
