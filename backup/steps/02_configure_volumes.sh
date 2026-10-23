#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/common.sh"
standalone_header "Configure volume backups"
require_root

require_command curl
require_command jq

[[ -n ${DOKPLOY_API_KEY:-} ]] || fail "Dokploy API key is required"

status "Retrieving Dokploy projects"

projects=$(curl -fsS \
  -H "x-api-key: $DOKPLOY_API_KEY" \
  "${DOKPLOY_URL:-http://127.0.0.1:3000}/api/project.all")

printf '%s\n' "$projects" \
  | jq '[.[] | {
      name,
      projectId,
      environments: [
        .environments[]? | {
          name,
          compose: [
            .compose[]? | {
              name,
              composeId,
              appName
            }
          ]
        }
      ]
    }]'

status "Retrieving backup destinations"

destinations=$(curl -fsS \
  -H "x-api-key: $DOKPLOY_API_KEY" \
  "${DOKPLOY_URL:-http://127.0.0.1:3000}/api/destination.all")

printf '%s\n' "$destinations" \
  | jq '[.[] | {name, destinationId, type}]'

done_msg "Retrieved Dokploy configuration"