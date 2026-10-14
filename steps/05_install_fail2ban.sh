#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
standalone_header "Fail2ban"
require_root
require_command sshd

status "Installing Fail2ban"
apt_install fail2ban

ssh_port=$(effective_ssh_port)
[[ -n "$ssh_port" ]] || fail "Could not determine the effective SSH port"

status "Configuring the SSH Fail2ban jail"
cat > /etc/fail2ban/jail.d/sshd-vps-setup.local <<CONFIG
[sshd]
enabled = true
port = $ssh_port
backend = systemd
maxretry = 5
findtime = 10m
bantime = 1h
CONFIG

run_quiet systemctl enable --now fail2ban
run_quiet systemctl restart fail2ban
run_quiet fail2ban-client status sshd
done_msg "Fail2ban is active for SSH on port $ssh_port"
