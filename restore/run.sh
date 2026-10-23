#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

section "Restore"

run_child "$REPO_DIR/restore/steps/run.sh"