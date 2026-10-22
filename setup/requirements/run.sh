#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/common.sh"
run_numbered_scripts "$REPO_DIR/setup/requirements" "Requirements"
