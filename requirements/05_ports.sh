#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
standalone_header "Required ports"
status "Checking ports required by Dokploy"
if ! command -v ss >/dev/null 2>&1; then
  warn "ss is not installed yet; skipping port checks. It will be installed in the dependencies step."
  exit 0
fi

for port in 80 443 3000; do
  port_info="$(ss -H -ltnp "sport = :$port" 2>/dev/null)"

  if [[ -n "$port_info" ]]; then
    process="$(sed -n 's/.*users:(("\([^"]*\)",pid=\([0-9]*\).*/\1 (PID \2)/p' <<< "$port_info" | head -n1)"

    if [[ -n "$process" ]]; then
      fail "TCP port $port is already in use by $process"
    else
      fail "TCP port $port is already in use"
    fi
  fi
done

done_msg "Ports 80, 443, and 3000 are available"
