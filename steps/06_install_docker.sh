#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
standalone_header "Docker"
require_root
require_command curl

if command -v docker >/dev/null 2>&1; then
  status "Docker is already installed; verifying it"
  run_quiet docker info
  done_msg "Existing Docker installation is healthy: $(docker --version)"
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
