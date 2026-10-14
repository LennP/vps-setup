#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
standalone_header "Update system"
require_root

export DEBIAN_FRONTEND=noninteractive
status "Updating package indexes"
run_quiet apt-get update

if ! apt-get -s upgrade 2>/dev/null | grep -q '^Inst '; then
  done_msg "System packages are already up to date"
  exit 0
fi

status "Upgrading installed packages"
run_quiet apt-get -y upgrade

done_msg "System packages updated"
