#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/common.sh"
standalone_header "WireGuard support"
status "Checking TUN/WireGuard host support"
[[ -c /dev/net/tun ]] || fail "/dev/net/tun is unavailable; WireGuard/VPN containers requiring TUN will not work on this VPS"
done_msg "/dev/net/tun is available"

if [[ -d /sys/module/wireguard ]] || { [[ -r /proc/modules ]] && grep -q '^wireguard ' /proc/modules; }; then
  done_msg "WireGuard kernel module is available"
else
  warn "WireGuard kernel module is not currently loaded. /dev/net/tun is available, so userspace/container WireGuard may still work."
fi
