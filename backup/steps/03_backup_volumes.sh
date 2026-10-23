#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/common.sh"
source "$REPO_DIR/lib/dokploy.sh"
standalone_header "Back up volumes"
require_root

status "Starting Docker volume backups"

backups_file="$STATE_DIR/backup/volume-backups"

[[ -f "$backups_file" ]] || fail "Volume backups have not been configured"

count=0

while IFS=$'\t' read -r volume backup_id; do
  [[ -n "$backup_id" ]] || continue

  status "Backing up $volume"

  payload=$(jq -n \
    --arg id "$backup_id" \
    '{volumeBackupId: $id}')

  dokploy_post volumeBackups.runManually "$payload" >/dev/null

  done_msg "Backup requested for $volume"

  ((count += 1))
done < "$backups_file"

done_msg "Requested $count volume backups"