#!/usr/bin/env bash
set -euo pipefail

SLUG="${1:-beech}"
COUNT="${2:-20}"
AFTER="${3:-null}"
FILTER="${4:-null}" # null = no filter

curl -sS 'https://profile.api.trailhead.com/graphql' \
  -H 'content-type: application/json' \
  --data-raw "$(jq -nc --arg slug "$SLUG" --argjson count "$COUNT" --arg after "$AFTER" --arg filter "$FILTER" '{
    query: "fragment EarnedAward on EarnedAwardBase {  __typename  id  award {    __typename    id    title    type    icon    content {      __typename      webUrl      description    }  }} fragment EarnedAwardSelf on EarnedAwardSelf {  __typename  id  award {    __typename    id    title    type    icon    content {      __typename      webUrl      description    }  }  earnedAt  earnedPointsSum} fragment StatsBadgeCount on TrailheadProfileStats {  __typename  earnedBadgesCount  superbadgeCount} fragment ProfileBadges on PublicProfile {  __typename  trailheadStats {    ... on TrailheadProfileStats {      ...StatsBadgeCount    }  }  earnedAwards(first: $count, after: $after, awardType: $filter) {    edges {      node {        ... on EarnedAwardBase {          ...EarnedAward        }        ... on EarnedAwardSelf {          ...EarnedAwardSelf        }      }    }    pageInfo {      ...PageInfoBidirectional    }  }} fragment PageInfoBidirectional on PageInfo {  __typename  endCursor  hasNextPage  startCursor  hasPreviousPage} query GetTrailheadBadges($slug: String, $hasSlug: Boolean!, $count: Int = 8, $after: String = null, $filter: AwardTypeFilter = null) {  profile(slug: $slug) @include(if: $hasSlug) {    __typename    ... on PublicProfile {      ...ProfileBadges    }  }}",
    variables: {
      slug: $slug,
      hasSlug: true,
      count: $count,
      after: (if $after == "null" then null else $after end),
      filter: (if $filter == "null" then null else $filter end)
    }
  }')"

