#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
standalone_header "Install dependencies"
require_root

packages=(
  ca-certificates
  curl
  git
  gnupg
  iproute2
  jq
  kmod
  openssh-server
  tar
  ufw
  unzip
  wireguard-tools
)

missing=()
for package in "${packages[@]}"; do
  if ! dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -qx 'install ok installed'; then
    missing+=("$package")
  fi
done

if (( ${#missing[@]} == 0 )); then
  done_msg "Base dependencies are already installed"
  exit 0
fi

status "Installing missing base dependencies: ${missing[*]}"
apt_install "${missing[@]}"
done_msg "Base dependencies installed"
