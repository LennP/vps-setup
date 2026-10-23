#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/common.sh"

standalone_header "Restore Docker volumes"
require_root

status "Discovering application volumes"

mapfile -t volumes < <(
  docker volume ls --format '{{.Name}}' \
    | awk '$0 != "dokploy" && $0 != "dokploy-postgres"'
)

if (( ${#volumes[@]} == 0 )); then
  warn "No application volumes currently exist"
  warn "Deploy the restored applications before restoring their volumes"
  fail "No application volumes found"
fi

done_msg "Found ${#volumes[@]} application volumes"

printf '\n'
info "Restore the following volumes using Dokploy."
printf '\n'

for volume in "${volumes[@]}"; do
  info "$volume"
done

printf '\n'
info "For each volume:"
printf '\n'

printf '  1. Open the application in Dokploy.\n'
printf '  2. Navigate to its volume backup configuration.\n'
printf '  3. Find the latest successful Cloudflare R2 backup.\n'
printf '  4. Restore the volume.\n'
printf '  5. Wait until restoration has completed.\n'
printf '\n'

warn "Stop applications before restoring volumes that contain active data."
warn "Restoring over a running database can cause data inconsistencies."

printf '\n'
read -rp "Have all application volumes been restored? [y/N] " confirm

[[ "$confirm" =~ ^[Yy]$ ]] \
  || fail "Volume restoration has not been confirmed"

done_msg "Application volume restoration confirmed"