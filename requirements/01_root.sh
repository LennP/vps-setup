#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
standalone_header "Root access"
status "Checking privileges"
require_root
done_msg "Running as root"
