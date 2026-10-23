#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/common.sh"
source "$REPO_DIR/lib/dokploy.sh"
standalone_header "Back up Dokploy"
require_root

status "Creating Dokploy instance backup configuration"

destinations=$(dokploy_get destination.all)

destination_id=$(jq -r \
  '.[] | select(.name == "Cloudflare") | .destinationId' \
  <<< "$destinations" | head -1)

[[ -n "$destination_id" ]] || fail "Cloudflare destination not found"

payload=$(jq -n \
  --arg destination "$destination_id" \
  '{
    schedule: "0 3 * * *",
    enabled: false,
    prefix: "dokploy",
    destinationId: $destination,
    database: "dokploy",
    databaseType: "web-server"
  }')

created=$(dokploy_post backup.create "$payload")
backup_id=$(jq -r '.backupId // empty' <<< "$created")

[[ -n "$backup_id" ]] || fail "Failed to create Dokploy backup configuration"

status "Starting Dokploy instance backup"

dokploy_post backup.manualBackupWebServer \
  "$(jq -n --arg id "$backup_id" '{backupId: $id}')" \
  >/dev/null

done_msg "Dokploy instance backup requested"