#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
standalone_header "Docker"
require_root
require_command curl


configure_docker_networking() {
  require_command modprobe
  require_command sysctl

  local modules_file=/etc/modules-load.d/vps-setup-docker.conf
  local sysctl_file=/etc/sysctl.d/99-vps-setup-docker.conf
  local desired_modules='br_netfilter'
  local desired_sysctl='net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1'
  local changed=false

  if [[ ! -f "$modules_file" ]] || ! cmp -s "$modules_file" <(printf '%s\n' "$desired_modules"); then
    printf '%s\n' "$desired_modules" > "$modules_file"
    changed=true
  fi

  if [[ ! -d /sys/module/br_netfilter ]]; then
    status "Loading br_netfilter kernel module"
    run_quiet modprobe br_netfilter
    changed=true
  fi

  if [[ ! -f "$sysctl_file" ]] || ! cmp -s "$sysctl_file" <(printf '%s\n' "$desired_sysctl"); then
    printf '%s\n' "$desired_sysctl" > "$sysctl_file"
    changed=true
  fi

  if [[ "$(sysctl -n net.bridge.bridge-nf-call-iptables 2>/dev/null || true)" != 1 ]]; then
    run_quiet sysctl -w net.bridge.bridge-nf-call-iptables=1
    changed=true
  fi

  if [[ "$(sysctl -n net.bridge.bridge-nf-call-ip6tables 2>/dev/null || true)" != 1 ]]; then
    run_quiet sysctl -w net.bridge.bridge-nf-call-ip6tables=1
    changed=true
  fi

  if $changed; then
    done_msg "Docker bridge firewall integration configured"
  else
    done_msg "Docker bridge firewall integration is already configured"
  fi
}

configure_docker_networking

if command -v docker >/dev/null 2>&1; then
  if docker info >/dev/null 2>&1; then
    done_msg "Docker is already installed and healthy: $(docker --version)"
    exit 0
  fi

  status "Docker is installed but not running; starting it"
  run_quiet systemctl enable --now docker
  run_quiet docker info
  done_msg "Docker is installed and healthy: $(docker --version)"
  exit 0
fi

[[ -r /etc/os-release ]] || fail "/etc/os-release is unavailable"
source /etc/os-release
[[ -n ${VERSION_CODENAME:-} ]] || fail "Could not determine the OS codename"

case "${ID:-}" in
  ubuntu|debian) docker_repo="https://download.docker.com/linux/$ID" ;;
  *) fail "Docker installation is only configured for Ubuntu and Debian" ;;
esac

status "Configuring Docker's official package repository"
install -m 0755 -d /etc/apt/keyrings
run_quiet curl -fsSL "$docker_repo/gpg" -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
architecture=$(dpkg --print-architecture)
printf 'deb [arch=%s signed-by=/etc/apt/keyrings/docker.asc] %s %s stable\n' \
  "$architecture" "$docker_repo" "$VERSION_CODENAME" > /etc/apt/sources.list.d/docker.list

status "Installing Docker Engine"
export DEBIAN_FRONTEND=noninteractive
run_quiet apt-get update
run_quiet apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
run_quiet systemctl enable --now docker
run_quiet docker info

done_msg "Docker installed and running: $(docker --version)"
