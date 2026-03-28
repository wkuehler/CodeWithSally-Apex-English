#!/usr/bin/env bash
set -euo pipefail

SLUG="${1:-beech}"
FIRST="${2:-5}"
AFTER="${3:-}"

curl -sS 'https://profile.api.trailhead.com/graphql' \
  -H 'content-type: application/json' \
  --data-raw "$(jq -nc --arg slug "$SLUG" --argjson first "$FIRST" --arg after "$AFTER" '{
    query: "query EarnedStamps($slug: String!, $first: Int, $after: String) { earnedStamps(slug: $slug, first: $first, after: $after) { __typename count totalCount edges { __typename cursor node { __typename rewardId kind apiName name description eventDate eventLocation iconUrl linkUrl } } pageInfo { __typename endCursor hasNextPage } } }",
    variables: { slug: $slug, first: $first, after: (if $after == "" then null else $after end) }
  }')"

