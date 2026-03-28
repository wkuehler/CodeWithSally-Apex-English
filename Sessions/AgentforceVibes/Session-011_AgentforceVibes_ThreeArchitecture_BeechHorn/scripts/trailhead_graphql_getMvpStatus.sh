#!/usr/bin/env bash
set -euo pipefail

# The MVP query takes "userSlug" but it is typed as ID in the legacy query.
# We'll try with the slug (username) by default; pass a second arg to override.
USER_SLUG="${2:-${1:-beech}}"

curl -sS 'https://profile.api.trailhead.com/graphql' \
  -H 'content-type: application/json' \
  --data-raw "$(jq -nc --arg userSlug "$USER_SLUG" '{
    query: "query GetTbcMvpContext($userSlug: ID!, $queryMvp: Boolean!) { profileData(userSlug: $userSlug) @include(if: $queryMvp) { isMvp } }",
    variables: { userSlug: $userSlug, queryMvp: true }
  }')"

