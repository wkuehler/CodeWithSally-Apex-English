#!/usr/bin/env bash
set -euo pipefail

SLUG="${1:-beech}"

curl -sS 'https://profile.api.trailhead.com/graphql' \
  -H 'content-type: application/json' \
  --data-raw "$(jq -nc --arg slug "$SLUG" '{
    query: "fragment LearnerStatusLevel on LearnerStatusLevel { __typename statusName title level imageUrl completedAt progress edition medalImageUrl active }\n\nfragment PublicProfile on PublicProfile { __typename trailheadStats { __typename learnerStatusLevels { ...LearnerStatusLevel } } }\n\nquery GetAgentblazerStatus($slug: String, $hasSlug: Boolean!) { profile(slug: $slug) @include(if: $hasSlug) { ... on PublicProfile { ...PublicProfile } ... on PrivateProfile { __typename } } }",
    variables: { slug: $slug, hasSlug: true }
  }')"

