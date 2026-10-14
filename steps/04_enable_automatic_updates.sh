#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
standalone_header "Automatic updates"
require_root

status "Installing unattended-upgrades"
apt_install unattended-upgrades

status "Enabling automatic package-list refresh and unattended upgrades"
cat > /etc/apt/apt.conf.d/20auto-upgrades <<'CONFIG'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
CONFIG

status "Enabling automatic reboot when an update requires it"
cat > /etc/apt/apt.conf.d/52unattended-upgrades-vps-setup <<'CONFIG'
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-WithUsers "true";
Unattended-Upgrade::Automatic-Reboot-Time "04:00";
CONFIG

run_quiet systemctl enable --now unattended-upgrades.service
done_msg "Automatic updates enabled; required reboots are scheduled for 04:00"
