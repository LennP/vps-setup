#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/common.sh"
standalone_header "Dokploy"
require_root

status "Checking Dokploy"

docker service inspect dokploy >/dev/null 2>&1 \
  || fail "Dokploy service not found"

docker service inspect dokploy-postgres >/dev/null 2>&1 \
  || fail "Dokploy PostgreSQL service not found"

done_msg "Dokploy is available"