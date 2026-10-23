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

# Docker does not expose secret values through docker secret inspect.
# Find a running container with the secret mounted.
container_id=""
secret_path=""

while IFS= read -r id; do
  mounts=$(docker inspect "$id" \
    --format '{{json .Mounts}}')

  path=$(jq -r --arg name "$secret_name" \
    '[.[] | select(.Destination | endswith("/" + $name)) | .Destination][0] // empty' \
    <<< "$mounts")

  if [[ -n "$path" ]]; then
    container_id="$id"
    secret_path="$path"
    break
  fi
done < <(docker ps -q)

[[ -n "$container_id" ]] \
  || fail "No running container exposes '$secret_name'"

status "Encrypting recovery secret"

mkdir -p "$output_dir"
chmod 700 "$output_dir"

umask 077

openssl enc -aes-256-cbc -pbkdf2 -iter 600000 -salt \
  -in <(docker exec "$container_id" cat "$secret_path") \
  -out "$output_file"

chmod 600 "$output_file"

done_msg "Encrypted recovery secret saved to $output_file"