#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
standalone_header "Secure SSH"
require_root
require_command sshd

SSH_PORT=${SSH_PORT:-22}
[[ "$SSH_PORT" =~ ^[0-9]+$ ]] && (( SSH_PORT >= 1 && SSH_PORT <= 65535 )) || fail "SSH_PORT must be between 1 and 65535"

status "Confirming SSH key access exists before disabling passwords"
run_child "$REPO_DIR/requirements/04_ssh_key.sh"

config_dir=/etc/ssh/sshd_config.d
config_file="$config_dir/00-vps-setup.conf"
mkdir -p "$config_dir"

status "Writing SSH hardening configuration"
cat > "$config_file" <<CONFIG
# Managed by vps-setup.
PasswordAuthentication no
KbdInteractiveAuthentication no
PubkeyAuthentication yes
PermitRootLogin prohibit-password
Port $SSH_PORT
CONFIG

status "Validating SSH configuration"
run_quiet sshd -t

if systemctl list-unit-files ssh.service >/dev/null 2>&1; then
  run_quiet systemctl restart ssh
elif systemctl list-unit-files sshd.service >/dev/null 2>&1; then
  run_quiet systemctl restart sshd
else
  fail "Could not find the SSH systemd service"
fi

done_msg "SSH hardened: password login disabled; SSH port is $SSH_PORT"
if (( SSH_PORT != 22 )); then
  warn "Future SSH connections must use port $SSH_PORT. Keep this session open until you have verified a second connection."
fi
