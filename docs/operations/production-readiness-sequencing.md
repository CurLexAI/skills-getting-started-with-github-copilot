# Production Readiness Sequencing

This document defines mandatory runtime sequencing and smoke checks.

## Start Order

1. **Backend first**
   - Export runtime env vars (`PYTHON_BACKEND_URL`, `AGENT_API_TOKEN`).
   - Confirm backend contracts:
     - workflow endpoint contract: `POST $PYTHON_BACKEND_URL/api/v1/workflow/query`
     - health endpoint contract: `GET $PYTHON_BACKEND_URL/health`

2. **Modal services second**
   - Export `BAYYINAH_ENDPOINT` and `MIHWAR_ENDPOINT`.
   - Confirm each endpoint includes a non-root path and valid `http(s)` URL.
   - Validate adapter→provider→endpoint_env linkage from `agents/registry.yaml`.

3. **Frontend last**
   - Export `FRONTEND_API_BASE_URL`.
   - Contract check: `${FRONTEND_API_BASE_URL}/api` is the API base used by frontend calls.

4. **Smoke checks**
   - Run preflight gate:
     ```bash
     scripts/preflight/production-readiness.sh
     ```
   - If preflight fails, deployment is blocked until the failing contract is corrected.

## CI Gate

Deployment-related workflows must execute `scripts/preflight/production-readiness.sh` before any deploy step.
