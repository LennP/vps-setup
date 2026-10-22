#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/common.sh"
standalone_header "Dokploy"
require_root
require_command curl
require_command docker
require_command ss
require_command ufw-docker

if docker service inspect dokploy >/dev/null 2>&1; then
  done_msg "Dokploy is already installed"
  status "Verifying Dokploy firewall rules"
else
  status "Checking ports required by Dokploy"
  for port in 80 443 3000; do
    port_info=$(ss -H -ltnp "sport = :$port" 2>/dev/null || true)
    [[ -n "$port_info" ]] || continue

    process=$(sed -n 's/.*users:(("\([^"]*\)",pid=\([0-9]*\).*/\1 (PID \2)/p' <<< "$port_info")
    process=${process%%$'\n'*}
    if [[ -n "$process" ]]; then
      fail "TCP port $port is already in use by $process"
    else
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
