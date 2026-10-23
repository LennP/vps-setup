#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/common.sh"

standalone_header "Restore applications"
require_root

printf '\n'
info "Restore application volumes before redeploying applications."
info "Dokploy automatically creates missing Docker volumes during restoration."
printf '\n'

info "For each application with volume backups:"
printf '\n'

printf '  1. Open the application in Dokploy.\n'
printf '  2. Navigate to Volume Backups.\n'
printf '  3. Open Restore Volume Backup.\n'
printf '  4. Enter the exact volume name from your recovery information.\n'
printf '  5. Select the backup destination.\n'
printf '  6. Select the latest successful backup.\n'
printf '  7. Restore and wait for completion.\n'
printf '  8. Repeat for all application volumes.\n'
printf '\n'

warn "The volume names must match those expected by Docker Compose."
warn "Do not deploy applications before restoring their volumes."
warn "Never restore a volume while an application is using it."

printf '\n'
read -rp "Have all application volumes been restored? [y/N] " confirm

[[ "$confirm" =~ ^[Yy]$ ]] \
  || fail "Volume restoration has not been confirmed"

done_msg "Application volume restoration confirmed"

printf '\n'
info "Redeploy applications"
printf '\n'

printf '  1. Open Projects in Dokploy.\n'
printf '  2. Redeploy every application that is not running.\n'
printf '  3. Include applications without persistent volumes.\n'
printf '  4. Wait for all deployments to complete.\n'
printf '  5. Verify that applications use their restored data.\n'
printf '\n'

read -rp "Have all applications been deployed and verified? [y/N] " confirm

[[ "$confirm" =~ ^[Yy]$ ]] \
  || fail "Application deployment has not been confirmed"

done_msg "Application deployments confirmed"

printf '\n'
info "Update DNS"
printf '\n'

printf '  1. Open your DNS provider.\n'
printf '  2. Update the relevant A records to the new VPS IPv4 address.\n'
printf '  3. Update AAAA records if your new VPS uses IPv6.\n'
printf '  4. Wait for DNS changes to take effect.\n'
printf '  5. Verify that all application domains work correctly.\n'
printf '\n'

warn "Keep the old VPS running until all domains work on the new server."

printf '\n'
read -rp "Have DNS records been updated and all domains verified? [y/N] " confirm

[[ "$confirm" =~ ^[Yy]$ ]] \
  || fail "DNS migration has not been confirmed"

done_msg "DNS migration confirmed"
done_msg "VPS restoration completed"