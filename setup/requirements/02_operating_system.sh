#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/common.sh"
standalone_header "Operating system"
status "Checking operating system"

[[ -r /etc/os-release ]] || fail "/etc/os-release is unavailable"
source /etc/os-release

case "${ID:-}:${VERSION_ID:-}" in
  ubuntu:22.04|ubuntu:24.04|debian:12) ;;
  ubuntu:*) fail "Supported Ubuntu versions are 22.04 and 24.04; detected: ${PRETTY_NAME:-unknown}" ;;
  debian:*) fail "Supported Debian version is 12; detected: ${PRETTY_NAME:-unknown}" ;;
  *) fail "Supported operating systems are Ubuntu 22.04/24.04 and Debian 12; detected: ${PRETTY_NAME:-unknown}" ;;
esac

done_msg "Supported OS: ${PRETTY_NAME}"
