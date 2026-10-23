#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/common.sh"
standalone_header "Back up recovery secret"
require_root

secret_name="dokploy_auth_secret"
output_dir="$STATE_DIR/backup"
output_file="$output_dir/${secret_name}.enc"

status "Locating Docker Swarm secret"

docker secret inspect "$secret_name" >/dev/null 2>&1 \
  || fail "Docker Swarm secret '$secret_name' not found"

container_id=""
secret_path=""

# Find the Swarm service that uses the secret.
while IFS= read -r service; do
  secret_path=$(docker service inspect "$service" \
    --format '{{json .Spec.TaskTemplate.ContainerSpec.Secrets}}' \
    | jq -r --arg name "$secret_name" \
      '[.[]? | select(.SecretName == $name) |
        "/run/secrets/" + .File.Name][0] // empty')

  [[ -n "$secret_path" ]] || continue

  container_id=$(docker ps -q \
    --filter "label=com.docker.swarm.service.name=$service" \
    | head -1)

  [[ -n "$container_id" ]] && break
done < <(docker service ls --format '{{.Name}}')

[[ -n "$container_id" ]] \
  || fail "No running Swarm container exposes '$secret_name'"

status "Encrypting recovery secret"

mkdir -p "$output_dir"
chmod 700 "$output_dir"
umask 077

docker exec "$container_id" cat "$secret_path" \
  | openssl enc -aes-256-cbc -pbkdf2 -iter 600000 -salt \
      -out "$output_file"

chmod 600 "$output_file"

done_msg "Encrypted recovery secret saved to $output_file"