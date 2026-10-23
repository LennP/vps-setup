#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/common.sh"
standalone_header "Back up recovery secret"
require_root

secret_name="dokploy_auth_secret"

status "Locating Docker Swarm secret"

docker secret inspect "$secret_name" >/dev/null 2>&1 \
  || fail "Docker Swarm secret '$secret_name' not found"

container_id=""
secret_path=""

while IFS= read -r service; do
  secret_path=$(docker service inspect "$service" \
    --format '{{json .Spec.TaskTemplate.ContainerSpec.Secrets}}' \
    | jq -r --arg name "$secret_name" \
      '[.[]? | select(.SecretName == $name) |
        .File.Name][0] // empty')

  [[ -n "$secret_path" ]] || continue
  [[ "$secret_path" == /* ]] || secret_path="/run/secrets/$secret_path"

  container_id=$(docker ps -q \
    --filter "label=com.docker.swarm.service.name=$service" \
    | head -1)

  [[ -n "$container_id" ]] && break
done < <(docker service ls --format '{{.Name}}')

[[ -n "$container_id" ]] \
  || fail "No running Swarm container exposes '$secret_name'"

docker exec "$container_id" test -s "$secret_path" \
  || fail "Docker Swarm secret is empty or inaccessible"

status "Encrypting recovery secret"

printf '\n'
printf 'Enter a passphrase to encrypt the recovery secret:\n'

encrypted=$(docker exec "$container_id" cat "$secret_path" \
  | openssl enc -aes-256-cbc -pbkdf2 -iter 600000 -salt \
  | base64 -w 0)

[[ -n "$encrypted" ]] || fail "Encryption failed"

printf '\n'
printf '%s\n' '--- BEGIN ENCRYPTED DOKPLOY SECRET ---'
printf '%s\n' "$encrypted"
printf '%s\n' '--- END ENCRYPTED DOKPLOY SECRET ---'
printf '\n'

done_msg "Copy and store this encrypted secret somewhere safe"