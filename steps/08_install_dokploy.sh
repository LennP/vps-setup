#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
standalone_header "Dokploy"
require_root
require_command curl
require_command docker
require_command ss
require_command ufw-docker

if docker service inspect dokploy >/dev/null 2>&1; then
  status "Dokploy is already installed; verifying firewall rules"
else
  status "Checking ports required by Dokploy"
  for port in 80 443 3000; do
    if ss -H -ltn "sport = :$port" 2>/dev/null | grep -q .; then
      fail "TCP port $port is already in use"
    fi
  done

  install_script=$(mktemp)
  trap 'rm -f "$install_script"' EXIT

  if [[ -n "${DOKPLOY_VERSION:-}" && "${DOKPLOY_VERSION}" != "latest" ]]; then
    url="https://github.com/Dokploy/dokploy/releases/download/${DOKPLOY_VERSION}/install.sh"
    status "Downloading Dokploy installer for ${DOKPLOY_VERSION}"
  else
    url="https://dokploy.com/install.sh"
    status "Downloading latest stable Dokploy installer"
  fi

  run_quiet curl -fsSL "$url" -o "$install_script"
  status "Installing Dokploy"
  run_quiet sh "$install_script"
  done_msg "Dokploy installation completed"
fi

configure_dokploy_firewall
