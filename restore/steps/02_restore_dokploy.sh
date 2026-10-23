#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/common.sh"

standalone_header "Restore Dokploy"
require_root

status "Checking Dokploy"

docker service inspect dokploy >/dev/null 2>&1 \
  || fail "Dokploy is not installed. Run setup.sh first."

done_msg "Dokploy is installed"

printf '\n'
info "Restore your Dokploy instance using its dashboard."
printf '\n'

printf '  1. Open your Dokploy dashboard.\n'
printf '  2. Log in to the fresh installation.\n'
printf '  3. Configure your Cloudflare R2 destination and name it exactly "Cloudflare".\n'
printf '  4. Open the web server backup/restore section.\n'
printf '  5. Select your existing backup from Cloudflare R2.\n'
printf '  6. Restore the Dokploy instance.\n'
printf '  7. Wait until restoration has completed.\n'
printf '\n'

warn "Do not continue until Dokploy has finished restoring."

printf '\n'
read -rp "Has the Dokploy restore completed successfully? [y/N] " confirm

[[ "$confirm" =~ ^[Yy]$ ]] \
  || fail "Dokploy restoration has not been confirmed"

done_msg "Dokploy restoration confirmed"