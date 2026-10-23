#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/common.sh"

standalone_header "Restore Docker volumes"
require_root

info "Dokploy can restore volume backups even when Docker volumes do not exist."
info "Missing volumes are created automatically during restoration."

printf '\n'
info "For each application with volume backups:"
printf '\n'

printf '  1. Open the application in Dokploy.\n'
printf '  2. Navigate to Volume Backups.\n'
printf '  3. Open Restore Volume Backup.\n'
printf '  4. Enter the exact volume name from the backup configuration.\n'
printf '  5. Select the Cloudflare R2 destination.\n'
printf '  6. Select the latest successful backup.\n'
printf '  7. Restore and wait for completion.\n'
printf '  8. Repeat for all application volumes.\n'
printf '\n'
printf '  9. Redeploy all applications that are not running.\n'
printf ' 10. Verify that the applications start and use their restored data.\n'
printf '\n'

warn "The volume name must match the name expected by Docker Compose."
warn "Restore application volumes before deploying their applications."
warn "Never restore a volume while an application is using it."

printf '\n'
read -rp "Have all application volumes been restored? [y/N] " confirm

[[ "$confirm" =~ ^[Yy]$ ]] \
  || fail "Volume restoration has not been confirmed"

done_msg "Application volume restoration confirmed"