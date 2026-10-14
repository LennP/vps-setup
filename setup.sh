#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
require_root

section "VPS setup"
info "Preparing this server for Dokploy."

run_child "$REPO_DIR/requirements/run.sh"
run_child "$REPO_DIR/steps/run.sh"

printf '\n'
done_msg "VPS setup completed successfully"

ssh_alias=$(read_state ssh_alias || true)
ssh_user=$(read_state ssh_user || true)
server_ip=$(read_state server_ip || true)

section "Next"
info "Keep this SSH session open until a second login works."
if [[ -n "$ssh_alias" ]]; then
  info "Test from your computer: ssh $ssh_alias"
  info "Open Dokploy: ssh -L 3000:127.0.0.1:3000 $ssh_alias"
elif [[ -n "$ssh_user" && -n "$server_ip" ]]; then
  info "Test from your computer: ssh ${ssh_user}@${server_ip}"
  info "Open Dokploy: ssh -L 3000:127.0.0.1:3000 ${ssh_user}@${server_ip}"
else
  info "Test a new SSH login from a second terminal."
  info "Then forward local port 3000 to 127.0.0.1:3000 on this VPS."
fi
info "Then open: http://localhost:3000"
