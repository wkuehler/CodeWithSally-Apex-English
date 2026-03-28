#!/usr/bin/env bash
set -euo pipefail

SLUG="${1:-beech}"

# Current schema note: This attempts a likely legacy shape to see what the API returns.
curl -sS 'https://profile.api.trailhead.com/graphql' \
  -H 'content-type: application/json' \
  --data-raw "$(jq -nc --arg slug "$SLUG" '{
    query: "query GetUserCertifications_Legacy($slug: String!) { profile(slug: $slug) { __typename ... on PublicProfile { certifications { id name status earnedOn expiresOn } } } }",
    variables: { slug: $slug }
  }')"

