#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/common.sh"
source "$REPO_DIR/lib/dokploy.sh"
standalone_header "Back up Dokploy"
require_root

[[ -n ${DOKPLOY_BACKUP_ID:-} ]] \
  || fail "DOKPLOY_BACKUP_ID is required"

status "Starting Dokploy instance backup"

payload=$(jq -n \
  --arg id "$DOKPLOY_BACKUP_ID" \
  '{backupId: $id}')

dokploy_post backup.manualBackupWebServer "$payload" >/dev/null

done_msg "Dokploy instance backup requested"