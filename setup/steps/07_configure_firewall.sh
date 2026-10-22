#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/common.sh"
standalone_header "Firewall"
require_root
require_command curl
require_command docker
require_command sshd
require_command ufw

UFW_DOCKER_URL=${UFW_DOCKER_URL:-https://raw.githubusercontent.com/chaifeng/ufw-docker/master/ufw-docker}
ssh_port=$(effective_ssh_port)
[[ -n "$ssh_port" ]] || fail "Could not determine the effective SSH port"

if command -v ufw-docker >/dev/null 2>&1; then
  done_msg "Docker-aware UFW integration is already installed"
else
  status "Installing Docker-aware UFW integration"
  tmp_file=$(mktemp)
  trap 'rm -f "$tmp_file"' EXIT
  run_quiet curl -fsSL "$UFW_DOCKER_URL" -o "$tmp_file"
  install -m 0755 "$tmp_file" /usr/local/bin/ufw-docker
fi

ufw_status=$(ufw status verbose)
if grep -q 'Default: deny (incoming), allow (outgoing)' <<< "$ufw_status"; then
  done_msg "Firewall default policies are already configured"
else
  status "Configuring firewall default policies"
  run_quiet ufw default deny incoming
  run_quiet ufw default allow outgoing
fi

ensure_rule() {
  local port=$1
  local protocol=$2
  local comment=$3
  local rule="${port}/${protocol}"

  local status_output
  status_output=$(ufw status)
  if grep -Eq "^[[:space:]]*${rule//\//\/}[[:space:]].*ALLOW" <<< "$status_output"; then
    done_msg "Firewall rule already allows $rule ($comment)"
  else
    status "Allowing $rule ($comment)"
    run_quiet ufw allow "$rule" comment "$comment"
  fi
}

ensure_rule "$ssh_port" tcp SSH
ensure_rule 80 tcp HTTP
ensure_rule 443 tcp HTTPS
ensure_rule 443 udp 'HTTPS HTTP/3'

warn_unexpected_allow_ports() {
  local status_output line target destination port normalized_line
  local found=false

  status_output=$(ufw status)
  while IFS= read -r line; do
    [[ "$line" =~ [[:space:]]ALLOW([[:space:]]|$) ]] || continue

    target=${line%%ALLOW*}
    target=$(sed 's/^[[:space:]]*//;s/[[:space:]]*$//' <<< "$target")
    target=${target%" (v6)"}

    # Normal host rules start with the destination port. ufw-docker forwarding
    # rules start with a container IP followed by the destination port.
    read -r first second _ <<< "$target"
    if [[ "$first" == */* && "$first" != *.*/* ]]; then
      destination=$first
    elif [[ "$first" =~ ^[0-9]+$ ]]; then
      destination=$first
    else
      destination=$second
    fi

    port=${destination%%/*}
    case "$port" in
      "$ssh_port"|80|443)
        continue
        ;;
    esac

    normalized_line=$(sed 's/^[[:space:]]*//;s/[[:space:]]*$//;s/[[:space:]][[:space:]]*/ /g' <<< "$line")
    warn "Unexpected inbound firewall port: $normalized_line"
    found=true
  done <<< "$status_output"

  if [[ "$found" == false ]]; then
    done_msg "No unexpected inbound firewall ports found"
  fi
}

warn_unexpected_allow_ports

if ufw-docker check >/dev/null 2>&1; then
  done_msg "Docker-aware UFW rules are already configured"
else
  status "Configuring Docker-aware UFW rules"
  run_quiet ufw-docker install
fi

ufw_status=$(ufw status)
if grep -q '^Status: active$' <<< "$ufw_status"; then
  done_msg "Firewall is already enabled"
else
  status "Enabling firewall"
  run_quiet ufw --force enable
fi

done_msg "Firewall enabled; required inbound rules are configured for SSH, HTTP, and HTTPS"
