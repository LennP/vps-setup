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
printf '  3. Configure your backup destination.\n'
printf '  4. Open the web server backup/restore section.\n'
printf '  5. Select your existing instance backup.\n'
printf '  6. Restore the Dokploy instance.\n'
printf '  7. Wait until restoration has completed.\n'
printf '\n'

warn "Do not continue until Dokploy has finished restoring."

printf '\n'
read -rp "Has the Dokploy restore completed successfully? [y/N] " confirm

[[ "$confirm" =~ ^[Yy]$ ]] \
  || fail "Dokploy restoration has not been confirmed"

done_msg "Dokploy restoration confirmed"

status "Checking Traefik configuration"

if ! docker inspect dokploy-traefik >/dev/null 2>&1; then
  warn "Traefik container not found"
  fail "Verify the Traefik installation in Dokploy"
fi

if ! docker exec dokploy-traefik \
  test -f /etc/dokploy/traefik/dynamic/dokploy.yml; then

  warn "Traefik cannot access the restored Dokploy configuration."
  warn "This can happen when restoration replaces a bind-mounted directory."

  printf '\n'
  info "Recreate Traefik through Dokploy:"
  printf '\n'

  printf '  1. Open Web Server in Dokploy.\n'
  printf '  2. Navigate to Traefik settings.\n'
  printf '  3. Open Additional Port Mappings.\n'
  printf '  4. Save the existing configuration without changing it.\n'
  printf '  5. Wait for Traefik to be recreated.\n'
  printf '\n'

  read -rp "Has Traefik been recreated? [y/N] " confirm

  [[ "$confirm" =~ ^[Yy]$ ]] \
    || fail "Traefik recreation has not been confirmed"

  docker exec dokploy-traefik \
    test -f /etc/dokploy/traefik/dynamic/dokploy.yml \
    || fail "Traefik still cannot access the restored configuration"
fi

done_msg "Traefik configuration is accessible"