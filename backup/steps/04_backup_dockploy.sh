#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/common.sh"
source "$REPO_DIR/lib/dokploy.sh"
standalone_header "Back up Dokploy"
require_root

status "Finding Dokploy instance backup configuration"

destinations=$(dokploy_get destination.all)

destination_id=$(jq -r \
  '.[] | select(.name == "Cloudflare") | .destinationId' \
  <<< "$destinations" | head -1)

[[ -n "$destination_id" ]] || fail "Cloudflare destination not found"

backups=$(dokploy_get user.getBackups)

backup_id=$(jq -r --arg destination "$destination_id" \
  '[.backups[] | select(
    .destinationId == $destination
    and .database == "dokploy"
    and .databaseType == "web-server"
  ) | .backupId][0] // empty' \
  <<< "$backups")

if [[ -z "$backup_id" ]]; then
  status "Creating Dokploy instance backup configuration"

  payload=$(jq -n \
    --arg destination "$destination_id" \
    '{
      schedule: "0 0 * * 1-5",
      enabled: false,
      prefix: "/",
      destinationId: $destination,
      database: "dokploy",
      databaseType: "web-server"
    }')

  dokploy_post backup.create "$payload" >/dev/null

  backups=$(dokploy_get user.getBackups)

  backup_id=$(jq -r --arg destination "$destination_id" \
    '[.backups[] | select(
      .destinationId == $destination
      and .database == "dokploy"
      and .databaseType == "web-server"
    ) | .backupId][0] // empty' \
    <<< "$backups")

  [[ -n "$backup_id" ]] \
    || fail "Failed to create Dokploy backup configuration"

  done_msg "Created backup configuration"
else
  done_msg "Backup configuration already exists"
fi

status "Starting Dokploy instance backup"

dokploy_post backup.manualBackupWebServer \
  "$(jq -n --arg id "$backup_id" '{backupId: $id}')" \
  >/dev/null

done_msg "Dokploy instance backup requested"