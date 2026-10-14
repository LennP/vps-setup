#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
standalone_header "Install dependencies"
require_root

status "Installing base dependencies"
apt_install \
  ca-certificates \
  curl \
  git \
  gnupg \
  iproute2 \
  jq \
  openssh-server \
  tar \
  ufw \
  unzip \
  wireguard-tools

done_msg "Base dependencies installed"
