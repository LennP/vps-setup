#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
standalone_header "Required ports"
status "Checking TCP ports 80, 443, and 3000"

if ! command -v ss >/dev/null 2>&1; then
  warn "ss is not installed yet; skipping port checks. It will be installed in the dependencies step."
  exit 0
fi

ports_in_use=false
for port in 80 443 3000; do
  port_info=$(ss -H -ltnp "sport = :$port" 2>/dev/null || true)
  [[ -n "$port_info" ]] || continue

  ports_in_use=true
  process=$(sed -n 's/.*users:(("\([^"]*\)",pid=\([0-9]*\).*/\1 (PID \2)/p' <<< "$port_info")
  process=${process%%$'\n'*}
  if [[ -n "$process" ]]; then
    warn "TCP port $port is already in use by $process"
  else
    warn "TCP port $port is already in use"
  fi
done

if $ports_in_use; then
  done_msg "Port check completed"
else
  done_msg "Ports 80, 443, and 3000 are available"
fi
