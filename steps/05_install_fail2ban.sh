#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
standalone_header "Fail2ban"
require_root
require_command sshd

ssh_port=$(effective_ssh_port)
[[ -n "$ssh_port" ]] || fail "Could not determine the effective SSH port"
config_file=/etc/fail2ban/jail.d/sshd-vps-setup.local

desired_config=$(cat <<CONFIG
[sshd]
enabled = true
port = $ssh_port
backend = systemd
maxretry = 5
findtime = 10m
bantime = 1h
CONFIG
)

package_installed=false
dpkg-query -W -f='${Status}' fail2ban 2>/dev/null | grep -qx 'install ok installed' && package_installed=true

if $package_installed \
  && [[ -f "$config_file" ]] && cmp -s "$config_file" <(printf '%s\n' "$desired_config") \
  && systemctl is-enabled --quiet fail2ban \
  && systemctl is-active --quiet fail2ban \
  && fail2ban-client status sshd >/dev/null 2>&1; then
  done_msg "Fail2ban is already active for SSH on port $ssh_port"
  exit 0
fi

if ! $package_installed; then
  status "Installing Fail2ban"
  apt_install fail2ban
fi

config_changed=false
if [[ ! -f "$config_file" ]] || ! cmp -s "$config_file" <(printf '%s\n' "$desired_config"); then
  status "Configuring the SSH Fail2ban jail"
  printf '%s\n' "$desired_config" > "$config_file"
  config_changed=true
fi

if ! systemctl is-enabled --quiet fail2ban || ! systemctl is-active --quiet fail2ban; then
  run_quiet systemctl enable --now fail2ban
elif $config_changed; then
  run_quiet systemctl restart fail2ban
fi

run_quiet fail2ban-client status sshd
done_msg "Fail2ban is active for SSH on port $ssh_port"
