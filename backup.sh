#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
require_root

section "VPS backup"
info "Backing up Dokploy and Docker named volumes."

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