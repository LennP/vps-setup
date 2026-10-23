#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/common.sh"
standalone_header "Discover volumes"
require_root

status "Discovering Docker named volumes"

mkdir -p "$STATE_DIR/backup"

docker volume ls --format '{{.Name}}' \
  | grep -vE '^dokploy(-postgres)?$' \
  > "$STATE_DIR/backup/volumes"

while IFS= read -r volume; do
  info "$volume"
done < "$STATE_DIR/backup/volumes"

count=$(wc -l < "$STATE_DIR/backup/volumes")

done_msg "Discovered $count application volumes"