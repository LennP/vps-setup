#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
require_root

section "VPS backup"
info "Backing up Dokploy and Docker named volumes."

printf '  Dokploy API key: '
IFS= read -rs DOKPLOY_API_KEY
printf '\n'

[[ -n "$DOKPLOY_API_KEY" ]] || fail "API key is required"

printf '  Dokploy instance backup ID: '
IFS= read -r DOKPLOY_BACKUP_ID

[[ -n "$DOKPLOY_BACKUP_ID" ]] || fail "Instance backup ID is required"

export DOKPLOY_API_KEY
export DOKPLOY_BACKUP_ID
export DOKPLOY_URL="http://127.0.0.1:3000"

run_child "$REPO_DIR/backup/requirements/run.sh"
run_child "$REPO_DIR/backup/steps/run.sh"
run_child "$REPO_DIR/backup/verify.sh"

unset DOKPLOY_API_KEY
unset DOKPLOY_BACKUP_ID

printf '\n'
done_msg "VPS backup requests submitted successfully"