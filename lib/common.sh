#!/usr/bin/env bash
set -Eeuo pipefail

COMMON_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_DIR=$(cd -- "$COMMON_DIR/.." && pwd)
SCRIPT_NAME=$(basename "${BASH_SOURCE[1]:-$0}")
LOG_DIR=${LOG_DIR:-/var/log/vps-setup}
STATE_DIR=${STATE_DIR:-/var/lib/vps-setup}

if [[ -t 1 && -z ${NO_COLOR:-} ]]; then
  RESET='\033[0m'
  BOLD='\033[1m'
  GREY='\033[90m'
  GREEN='\033[32m'
  YELLOW='\033[33m'
  RED='\033[31m'
  CYAN='\033[36m'
else
  RESET=''
  BOLD=''
  GREY=''
  GREEN=''
  YELLOW=''
  RED=''
  CYAN=''
fi

section() {
  printf '\n%b%s%b\n' "${BOLD}${CYAN}" "$*" "$RESET"
}

standalone_header() {
  [[ ${VPS_SETUP_ORCHESTRATED:-0} == 1 ]] || section "$*"
}

status() {
  printf '  %b→%b %b%s%b\n' "$GREY" "$RESET" "$GREY" "$*" "$RESET"
}

info() {
  printf '  %b%s%b\n' "$GREY" "$*" "$RESET"
}

done_msg() {
  printf '  %b✓%b %s\n' "$GREEN" "$RESET" "$*"
}

warn() {
  printf '  %b!%b %s\n' "$YELLOW" "$RESET" "$*" >&2
}

action() {
  printf '  %b?%b %s\n' "$YELLOW" "$RESET" "$*"
}

fail() {
  printf '  %b✗%b %s\n' "$RED" "$RESET" "$*" >&2
  exit 1
}

require_root() {
  [[ ${EUID} -eq 0 ]] || fail "Run this script as root, for example: sudo $0"
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "Required command is missing: $1"
}

prepare_log() {
  require_root
  mkdir -p "$LOG_DIR"
  LAST_LOG="$LOG_DIR/${SCRIPT_NAME%.sh}.log"
  if [[ ${LOG_PREPARED:-0} != 1 ]]; then
    : > "$LAST_LOG"
    LOG_PREPARED=1
  fi
}

run_quiet() {
  prepare_log
  {
    printf '\n$'
    printf ' %q' "$@"
    printf '\n'
  } >> "$LAST_LOG"
  "$@" >> "$LAST_LOG" 2>&1
}

apt_install() {
  export DEBIAN_FRONTEND=noninteractive
  run_quiet apt-get update
  run_quiet apt-get install -y "$@"
}

on_error() {
  local exit_code=$?
  local line_no=${1:-unknown}

  printf '\n  %b✗%b %s failed' "$RED" "$RESET" "$SCRIPT_NAME" >&2
  [[ $line_no != unknown ]] && printf ' at line %s' "$line_no" >&2
  printf '.\n' >&2

  if [[ -n ${LAST_LOG:-} && -s ${LAST_LOG:-} ]]; then
    printf '  %bLast output:%b\n' "$GREY" "$RESET" >&2
    tail -n 10 "$LAST_LOG" | sed 's/^/    /' >&2
    printf '  %bLog: %s%b\n' "$GREY" "$LAST_LOG" "$RESET" >&2
  fi

  exit "$exit_code"
}
trap 'on_error $LINENO' ERR

setup_user() {
  if [[ -n ${SUDO_USER:-} && ${SUDO_USER} != root ]]; then
    printf '%s' "$SUDO_USER"
  else
    printf 'root'
  fi
}

user_home() {
  getent passwd "$1" | cut -d: -f6
}

effective_ssh_port() {
  sshd -T 2>/dev/null | awk '$1 == "port" && !found { print $2; found=1 }'
}

save_state() {
  require_root
  mkdir -p "$STATE_DIR"
  chmod 700 "$STATE_DIR"

  local file="$STATE_DIR/$1"
  local value=$2
  if [[ ! -f "$file" ]] || [[ "$(cat "$file")" != "$value" ]]; then
    printf '%s\n' "$value" > "$file"
  fi
  chmod 600 "$file"
}

read_state() {
  local file="$STATE_DIR/$1"
  [[ -r "$file" ]] && cat "$file"
}

run_child() {
  local script=$1
  local exit_code

  if bash "$script"; then
    return 0
  else
    exit_code=$?
    exit "$exit_code"
  fi
}

configure_dokploy_firewall() {
  require_command ufw-docker
  require_command docker

  if ! docker inspect dokploy-traefik >/dev/null 2>&1; then
    return 0
  fi

  if [[ "$(docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null)" == "active" ]]; then
    if docker service inspect ufw-docker-agent >/dev/null 2>&1 && ufw-docker check >/dev/null 2>&1; then
      done_msg "Docker Swarm firewall integration is already configured"
    else
      status "Configuring Docker-aware firewall integration for Docker Swarm"
      run_quiet ufw-docker install
    fi
  fi

  local rules
  rules=$(ufw-docker list dokploy-traefik 2>/dev/null || true)

  if grep -qE '(^|[^0-9])80/tcp([^0-9]|$)' <<< "$rules" \
    && grep -qE '(^|[^0-9])443/tcp([^0-9]|$)' <<< "$rules" \
    && grep -qE '(^|[^0-9])443/udp([^0-9]|$)' <<< "$rules"; then
    done_msg "Traefik HTTP/HTTPS firewall rules are already configured; Dokploy port 3000 remains private"
    return 0
  fi

  status "Allowing Dokploy Traefik through the Docker-aware firewall"
  grep -qE '(^|[^0-9])80/tcp([^0-9]|$)' <<< "$rules" || run_quiet ufw-docker allow dokploy-traefik 80/tcp
  grep -qE '(^|[^0-9])443/tcp([^0-9]|$)' <<< "$rules" || run_quiet ufw-docker allow dokploy-traefik 443/tcp
  grep -qE '(^|[^0-9])443/udp([^0-9]|$)' <<< "$rules" || run_quiet ufw-docker allow dokploy-traefik 443/udp
  run_quiet ufw-docker reload
  done_msg "Traefik HTTP/HTTPS ports are allowed; Dokploy port 3000 remains private"
}

run_numbered_scripts() {
  local directory=$1
  local title=$2
  local script
  local found=false

  section "$title"
  export VPS_SETUP_ORCHESTRATED=1

  for script in "$directory"/[0-9][0-9]_*.sh; do
    [[ -e "$script" ]] || continue
    found=true
    run_child "$script"
  done

  $found || fail "No numbered scripts found in $directory"
}
