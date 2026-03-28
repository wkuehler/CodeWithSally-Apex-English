#!/usr/bin/env bash
set -euo pipefail

SLUG="${1:-beech}"

# Note: The original catalog query uses profile(id:), which the current Trailhead schema rejects.
# This script uses a schema-valid slug lookup and returns the canonical profile id + slug.
curl -sS 'https://profile.api.trailhead.com/graphql' \
  -H 'content-type: application/json' \
  --data-raw "$(jq -nc --arg slug "$SLUG" '{
    query: "query GetTrailblazerRank($slug: String!, $hasSlug: Boolean!) { profile(slug: $slug) @include(if: $hasSlug) { __typename ... on PublicProfile { id slug } ... on PrivateProfile { __typename } } }",
    variables: { slug: $slug, hasSlug: true }
  }')"

