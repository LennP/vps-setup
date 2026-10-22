#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/common.sh"
standalone_header "Server resources"
MIN_MEMORY_MB=${MIN_MEMORY_MB:-1900}
MIN_DISK_GB=${MIN_DISK_GB:-30}

status "Checking RAM and disk space"
memory_mb=$(awk '/MemTotal/ { printf "%d", $2 / 1024 }' /proc/meminfo)
disk_gb=$(df -BG --output=avail / | tail -n 1 | tr -dc '0-9')

(( memory_mb >= MIN_MEMORY_MB )) || fail "At least ~2 GB RAM is required; detected ${memory_mb} MB"
(( disk_gb >= MIN_DISK_GB )) || fail "At least ${MIN_DISK_GB} GB free disk is required; detected ${disk_gb} GB"

done_msg "Resources OK: ${memory_mb} MB RAM, ${disk_gb} GB free disk"
