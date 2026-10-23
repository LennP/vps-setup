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

backups=$(dokploy_get backup.list \
  --data-urlencode "databaseType=web-server")

backup_id=$(jq -r --arg destination "$destination_id" \
  '[.[] | select(.destinationId == $destination and .database == "dokploy") | .backupId][0] // empty' \
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

  created=$(dokploy_post backup.create "$payload")
  backup_id=$(jq -r '.backupId // empty' <<< "$created")

  if [[ -z "$backup_id" ]]; then
    backups=$(dokploy_get backup.list \
      --data-urlencode "databaseType=web-server")

    backup_id=$(jq -r --arg destination "$destination_id" \
      '[.[] | select(.destinationId == $destination and .database == "dokploy") | .backupId][0] // empty' \
      <<< "$backups")
  fi

  [[ -n "$backup_id" ]] \
    || fail "Failed to configure Dokploy instance backup"

  done_msg "Created backup configuration"
else
  done_msg "Backup configuration already exists"
fi

status "Starting Dokploy instance backup"

dokploy_post backup.manualBackupWebServer \
  "$(jq -n --arg id "$backup_id" '{backupId: $id}')" \
  >/dev/null

done_msg "Dokploy instance backup requested"