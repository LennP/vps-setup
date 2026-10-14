#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
standalone_header "Firewall"
require_root
require_command curl
require_command docker
require_command sshd
require_command ufw

UFW_DOCKER_URL=${UFW_DOCKER_URL:-https://raw.githubusercontent.com/chaifeng/ufw-docker/master/ufw-docker}
ssh_port=$(effective_ssh_port)
[[ -n "$ssh_port" ]] || fail "Could not determine the effective SSH port"

status "Installing Docker-aware UFW integration"
tmp_file=$(mktemp)
trap 'rm -f "$tmp_file"' EXIT
run_quiet curl -fsSL "$UFW_DOCKER_URL" -o "$tmp_file"
install -m 0755 "$tmp_file" /usr/local/bin/ufw-docker

status "Applying firewall baseline"
run_quiet ufw --force reset
run_quiet ufw default deny incoming
run_quiet ufw default allow outgoing
run_quiet ufw allow "${ssh_port}/tcp" comment 'SSH'
run_quiet ufw allow 80/tcp comment 'HTTP'
run_quiet ufw allow 443/tcp comment 'HTTPS'
run_quiet ufw allow 443/udp comment 'HTTPS HTTP/3'
run_quiet ufw-docker install
run_quiet ufw --force enable
run_quiet systemctl restart ufw

configure_dokploy_firewall

done_msg "Firewall enabled; public inbound access is limited to SSH, HTTP, and HTTPS"
