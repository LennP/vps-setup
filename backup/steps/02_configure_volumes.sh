#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/common.sh"
source "$REPO_DIR/lib/dokploy.sh"
standalone_header "Configure volume backups"
require_root

status "Retrieving Dokploy configuration"

projects=$(dokploy_get project.all)
destinations=$(dokploy_get destination.all)

destination_id=$(jq -r \
  '.[] | select(.name == "Cloudflare") | .destinationId' \
  <<< "$destinations" | head -1)

[[ -n "$destination_id" ]] || fail "Cloudflare destination not found"

volumes_file="$STATE_DIR/backup/volumes"
backups_file="$STATE_DIR/backup/volume-backups"

[[ -f "$volumes_file" ]] || fail "Volume discovery has not completed"

: > "$backups_file"

# Resolve Dokploy Compose resources once.
declare -A compose_ids

while IFS= read -r compose_id; do
  compose=$(dokploy_get compose.one \
    --data-urlencode "composeId=$compose_id")

  app_name=$(jq -r '.appName // empty' <<< "$compose")

  [[ -n "$app_name" ]] && compose_ids["$app_name"]=$compose_id
done < <(
  jq -r '.[].environments[]?.compose[]?.composeId' <<< "$projects"
)

while IFS= read -r volume; do
  [[ -n "$volume" ]] || continue

  status "Configuring $volume"

  project=$(docker volume inspect "$volume" \
    --format '{{index .Labels "com.docker.compose.project"}}')

  [[ -n "$project" && "$project" != "<no value>" ]] \
    || fail "Compose project label missing for $volume"

  compose_id=${compose_ids[$project]:-}

  [[ -n "$compose_id" ]] \
    || fail "Dokploy Compose resource not found for $volume"

  existing=$(dokploy_get volumeBackups.list \
    --data-urlencode "id=$compose_id" \
    --data-urlencode "volumeBackupType=compose")

  backup_id=$(jq -r --arg volume "$volume" \
    '[.[] | select(.volumeName == $volume) | .volumeBackupId][0] // empty' \
    <<< "$existing")

  if [[ -z "$backup_id" ]]; then
    payload=$(jq -n \
      --arg volume "$volume" \
      --arg compose "$compose_id" \
      --arg destination "$destination_id" \
      '{
        name: $volume,
        volumeName: $volume,
        composeId: $compose,
        serviceType: "compose",
        destinationId: $destination,
        prefix: $volume,
        cronExpression: "0 3 * * *",
        enabled: false,
        turnOff: false
      }')

    created=$(dokploy_post volumeBackups.create "$payload")
    backup_id=$(jq -r '.volumeBackupId // empty' <<< "$created")

    [[ -n "$backup_id" ]] \
      || fail "Failed to configure backup for $volume"

    done_msg "Created backup configuration"
  else
    done_msg "Backup configuration already exists"
  fi

  printf '%s\t%s\n' "$volume" "$backup_id" >> "$backups_file"

done < "$volumes_file"

count=$(wc -l < "$backups_file")

done_msg "Configured $count volume backups"