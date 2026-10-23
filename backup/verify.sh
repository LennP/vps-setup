#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
require_root

section "Verification"

backups_file="$STATE_DIR/backup/volume-backups"

[[ -f "$backups_file" ]] || fail "Backup configuration list missing"

count=$(wc -l < "$backups_file")

done_msg "$count volume backup requests submitted"
warn "Backup upload completion has not been verified"