#!/usr/bin/env bash

DOKPLOY_URL=${DOKPLOY_URL:-http://127.0.0.1:3000}

dokploy_get() {
  curl -fsS -G \
    -H "x-api-key: $DOKPLOY_API_KEY" \
    "$DOKPLOY_URL/api/$1" \
    "${@:2}"
}

dokploy_post() {
  curl -fsS -X POST \
    -H "x-api-key: $DOKPLOY_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$2" \
    "$DOKPLOY_URL/api/$1"
}