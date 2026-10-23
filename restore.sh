#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

standalone_header "VPS restore"
require_root

info "Restoring Dokploy and Docker application volumes."

printf '\n'
warn "This process is intended for a fresh VPS installation."
warn "Existing Dokploy data and Docker services may be replaced."

printf '\n'
read -rp "Continue with restoration? [y/N] " confirm

[[ "$confirm" =~ ^[Yy]$ ]] || exit 0

run_child "$REPO_DIR/restore/run.sh"

done_msg "VPS restoration completed"