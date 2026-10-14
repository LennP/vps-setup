#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
standalone_header "Verify setup"
require_root

require_command sshd
require_command ufw
require_command docker

status "Verifying SSH password authentication is disabled"
sshd_config=$(sshd -T)
grep -q '^passwordauthentication no$' <<< "$sshd_config" || fail "SSH PasswordAuthentication is not disabled"
done_msg "SSH password authentication is disabled"

status "Verifying UFW"
ufw_status=$(ufw status)
grep -q '^Status: active$' <<< "$ufw_status" || fail "UFW is not active"
done_msg "UFW is active"

status "Verifying Docker/UFW integration"
command -v ufw-docker >/dev/null 2>&1 || fail "ufw-docker is not installed"
ufw-docker check >/dev/null 2>&1 || fail "ufw-docker integration check failed"
done_msg "Docker-published ports are governed by the UFW integration"

status "Verifying unattended-upgrades"
systemctl is-active --quiet unattended-upgrades || fail "unattended-upgrades is not active"
done_msg "Automatic updates are active"

status "Verifying Fail2ban"
systemctl is-active --quiet fail2ban || fail "Fail2ban is not active"
fail2ban-client status sshd >/dev/null || fail "Fail2ban SSH jail is not active"
done_msg "Fail2ban SSH jail is active"

status "Verifying Docker"
docker info >/dev/null || fail "Docker is not healthy"
done_msg "Docker is healthy"

status "Verifying Docker Swarm"
[[ "$(docker info --format '{{.Swarm.LocalNodeState}}')" == "active" ]] || fail "Docker Swarm is not active"
done_msg "Docker Swarm is active"

status "Verifying Dokploy services"
services=$(docker service ls --format '{{.Name}}')
grep -qx 'dokploy' <<<"$services" || fail "Dokploy service was not found"
grep -qx 'dokploy-postgres' <<<"$services" || fail "Dokploy PostgreSQL service was not found"
[[ "$(docker inspect -f '{{.State.Running}}' dokploy-traefik 2>/dev/null)" == "true" ]] || fail "Dokploy Traefik container is not running"
done_msg "Dokploy services are present"

status "Verifying TUN device"
[[ -c /dev/net/tun ]] || fail "/dev/net/tun is unavailable"
done_msg "TUN device is available"

done_msg "VPS setup verification passed"
