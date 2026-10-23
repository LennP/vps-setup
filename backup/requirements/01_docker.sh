#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/common.sh"
standalone_header "Docker"
require_root

require_command docker
require_command jq
require_command curl

status "Checking Docker"

docker info >/dev/null 2>&1 || fail "Docker is not running"

done_msg "Docker is available"