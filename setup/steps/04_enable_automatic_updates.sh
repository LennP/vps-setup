#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/common.sh"
standalone_header "Automatic updates"
require_root

config_20=/etc/apt/apt.conf.d/20auto-upgrades-vps-setup
config_52=/etc/apt/apt.conf.d/52unattended-upgrades-vps-setup

desired_20='APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";'
desired_52='Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-WithUsers "true";
Unattended-Upgrade::Automatic-Reboot-Time "04:00";'

package_installed=false
dpkg-query -W -f='${Status}' unattended-upgrades 2>/dev/null | grep -qx 'install ok installed' && package_installed=true

if $package_installed \
  && [[ -f "$config_20" ]] && cmp -s "$config_20" <(printf '%s\n' "$desired_20") \
  && [[ -f "$config_52" ]] && cmp -s "$config_52" <(printf '%s\n' "$desired_52") \
  && systemctl is-enabled --quiet unattended-upgrades.service \
  && systemctl is-active --quiet unattended-upgrades.service; then
  done_msg "Automatic updates are already enabled; required reboots are scheduled for 04:00"
  exit 0
fi

if ! $package_installed; then
  status "Installing unattended-upgrades"
  apt_install unattended-upgrades
fi

if [[ ! -f "$config_20" ]] || ! cmp -s "$config_20" <(printf '%s\n' "$desired_20"); then
  status "Enabling automatic package-list refresh and unattended upgrades"
  printf '%s\n' "$desired_20" > "$config_20"
fi

if [[ ! -f "$config_52" ]] || ! cmp -s "$config_52" <(printf '%s\n' "$desired_52"); then
  status "Enabling automatic reboot when an update requires it"
  printf '%s\n' "$desired_52" > "$config_52"
fi

run_quiet systemctl enable --now unattended-upgrades.service
done_msg "Automatic updates enabled; required reboots are scheduled for 04:00"
