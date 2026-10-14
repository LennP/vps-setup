#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
require_root
run_numbered_scripts "$REPO_DIR/steps" "Setup"
