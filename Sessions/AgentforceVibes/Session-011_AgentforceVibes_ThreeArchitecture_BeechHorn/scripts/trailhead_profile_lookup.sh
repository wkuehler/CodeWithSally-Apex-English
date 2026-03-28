#!/usr/bin/env bash
set -euo pipefail

SLUG="${1:-beech}"

curl -sS 'https://profile.api.trailhead.com/graphql' \
  -H 'content-type: application/json' \
  --data-raw "$(jq -nc --arg slug "$SLUG" '{
    query: "query ProfileBySlug($slug: String!) { profile(slug: $slug) { __typename ... on PublicProfile { id slug } ... on PrivateProfile { __typename } } }",
    variables: { slug: $slug }
  }')"

