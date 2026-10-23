#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
require_root

section "VPS backup"
info "Backing up Dokploy and Docker named volumes."

printf '\n'
info "Create a Dokploy API key:"
printf '  1. Open your Dokploy dashboard.\n'
printf '  2. Navigate to Profile → API/CLI.\n'
printf '  3. Create a new API key.\n'
printf '  4. Copy the generated key.\n'
printf '\n'

printf '  Dokploy API key: '
IFS= read -rs DOKPLOY_API_KEY
printf '\n'

[[ -n "$DOKPLOY_API_KEY" ]] || fail "API key is required"

export DOKPLOY_API_KEY
export DOKPLOY_URL="http://127.0.0.1:3000"

run_child "$REPO_DIR/backup/requirements/run.sh"
run_child "$REPO_DIR/backup/steps/run.sh"
run_child "$REPO_DIR/backup/verify.sh"

unset DOKPLOY_API_KEY

printf '\n'
done_msg "VPS backup requests submitted successfully"