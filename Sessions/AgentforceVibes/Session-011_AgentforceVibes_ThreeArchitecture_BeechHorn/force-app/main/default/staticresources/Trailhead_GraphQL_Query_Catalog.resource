{
  "queries": [
    {
      "name": "getTrailblazerRank",
      "label": "Trailblazer Rank",
      "description": "Primary profile lookup used by the sync orchestrator. Uses slug lookup to retrieve canonical profile id + slug (the older profile(id:) query shape is not supported by the current Trailhead schema).",
      "upstreamPath": "https://github.com/nabondance/Trailhead-Banner/blob/main/src/graphql/queries/getTrailblazerRank.js",
      "usedBy": [
        "TrailheadApiService.fetchRankData"
      ],
      "query": "query GetTrailblazerRank($slug: String!, $hasSlug: Boolean!) {\n  profile(slug: $slug) @include(if: $hasSlug) {\n    __typename\n    ... on PublicProfile {\n      id\n      slug\n    }\n    ... on PrivateProfile {\n      __typename\n    }\n  }\n}"
    },
    {
      "name": "resolveTrailblazerProfileIdBySlug",
      "label": "Resolve Trailblazer Profile ID by Slug",
      "description": "Lookup a Trailhead profile by slug (username) and return the canonical profile id/slug. Used to populate Trailblazer_Profile__c.Trailhead_Id__c when only Trailhead_Username__c is known.",
      "upstreamPath": "local",
      "usedBy": [
        "TrailheadApiService.resolveTrailheadIdFromUsername"
      ],
      "query": "query ResolveTrailblazerProfileIdBySlug($slug: String!, $hasSlug: Boolean!) {\n  profile(slug: $slug) @include(if: $hasSlug) {\n    __typename\n    ... on PublicProfile {\n      id\n      slug\n    }\n    ... on PrivateProfile {\n      __typename\n    }\n  }\n}"
    },
    {
      "name": "getTrailheadBadges",
      "label": "Trailhead Badges",
      "description": "Trailhead badge query using earnedAwards and TrailheadProfileStats; used to materialize Badge__c records and rollups.",
      "upstreamPath": "https://github.com/nabondance/Trailhead-Banner/blob/main/src/graphql/queries/getTrailheadBadges.js",
      "usedBy": [
        "TrailheadApiService.fetchBadges"
      ],
      "query": "fragment EarnedAward on EarnedAwardBase {  __typename  id  award {    __typename    id    title    type    icon    content {      __typename      webUrl      description    }  }} fragment EarnedAwardSelf on EarnedAwardSelf {  __typename  id  award {    __typename    id    title    type    icon    content {      __typename      webUrl      description    }  }  earnedAt  earnedPointsSum} fragment StatsBadgeCount on TrailheadProfileStats {  __typename  earnedBadgesCount  superbadgeCount} fragment ProfileBadges on PublicProfile {  __typename  trailheadStats {    ... on TrailheadProfileStats {      ...StatsBadgeCount    }  }  earnedAwards(first: $count, after: $after, awardType: $filter) {    edges {      node {        ... on EarnedAwardBase {          ...EarnedAward        }        ... on EarnedAwardSelf {          ...EarnedAwardSelf        }      }    }    pageInfo {      ...PageInfoBidirectional    }  }} fragment PageInfoBidirectional on PageInfo {  __typename  endCursor  hasNextPage  startCursor  hasPreviousPage} query GetTrailheadBadges($slug: String, $hasSlug: Boolean!, $count: Int = 8, $after: String = null, $filter: AwardTypeFilter = null) {  profile(slug: $slug) @include(if: $hasSlug) {    __typename    ... on PublicProfile {      ...ProfileBadges    }  }}"
    },
    {
      "name": "getUserCertifications",
      "label": "User Certifications",
      "description": "Legacy certifications query from Trailhead-Banner. (Current Trailhead schema in this project does not expose PublicProfile.certifications, so this query must be updated before enabling certification sync.)",
      "upstreamPath": "https://github.com/nabondance/Trailhead-Banner/blob/main/src/graphql/queries/getUserCertifications.js",
      "usedBy": [
        "TrailheadApiService.fetchCertifications"
      ],
      "query": "query GetUserCertifications($trailheadId: ID!, $queryProfile: Boolean!) {\n  profile(id: $trailheadId) @include(if: $queryProfile) {\n    certifications {\n      id\n      name\n      status\n      earnedOn\n      expiresOn\n    }\n  }\n}"
    },
    {
      "name": "getAgentblazerRank",
      "label": "Agentblazer Rank",
      "description": "Reference query from Trailhead-Banner for learner status levels and Agentblazer progression.",
      "upstreamPath": "https://github.com/nabondance/Trailhead-Banner/blob/main/src/graphql/queries/getAgentblazerRank.js",
      "usedBy": [
        "TrailheadApiService.fetchAgentblazerRank"
      ],
      "query": "fragment LearnerStatusLevel on LearnerStatusLevel {\n  __typename\n  statusName\n  title\n  level\n  imageUrl\n  completedAt\n  progress\n  edition\n  medalImageUrl\n  active\n}\n\nfragment PublicProfile on PublicProfile {\n  __typename\n  trailheadStats {\n    __typename\n    learnerStatusLevels {\n      ...LearnerStatusLevel\n    }\n  }\n}\n\nquery GetAgentblazerStatus($slug: String, $hasSlug: Boolean!) {\n  profile(slug: $slug) @include(if: $hasSlug) {\n    ... on PublicProfile {\n      ...PublicProfile\n    }\n    ... on PrivateProfile {\n      __typename\n    }\n  }\n}"
    },
    {
      "name": "getMvpStatus",
      "label": "MVP Status",
      "description": "Legacy MVP query from Trailhead-Banner. (Current Trailhead schema in this project does not expose Query.profileData, so this query must be updated before enabling MVP checks.)",
      "upstreamPath": "https://github.com/nabondance/Trailhead-Banner/blob/main/src/graphql/queries/getMvpStatus.js",
      "usedBy": [
        "TrailheadApiService.fetchMvpStatus"
      ],
      "query": "query GetTbcMvpContext($userSlug: ID!, $queryMvp: Boolean!) {\n  profileData(userSlug: $userSlug) @include(if: $queryMvp) {\n    isMvp\n  }\n}"
    },
    {
      "name": "getStamps",
      "label": "Earned Stamps",
      "description": "Legacy stamps query from Trailhead-Banner. (Current Trailhead schema in this project does not expose Query.earnedStamps, so this query must be updated before enabling stamps sync.)",
      "upstreamPath": "https://github.com/nabondance/Trailhead-Banner/blob/main/src/graphql/queries/getStamps.js",
      "usedBy": [
        "TrailheadApiService.fetchStamps"
      ],
      "query": "query EarnedStamps($slug: String!, $first: Int, $after: String) {\n  earnedStamps(slug: $slug, first: $first, after: $after) {\n    ...EarnedStamps\n    __typename\n  }\n}\n\nfragment EarnedStamps on StampEarnedConnection {\n  __typename\n  count\n  totalCount\n  edges {\n    __typename\n    cursor\n    node {\n      ...EarnedStamp\n      __typename\n    }\n  }\n  pageInfo {\n    endCursor\n    hasNextPage\n    __typename\n  }\n}\n\nfragment EarnedStamp on StampEarned {\n  __typename\n  rewardId\n  kind\n  apiName\n  name\n  description\n  eventDate\n  eventLocation\n  iconUrl\n  linkUrl\n}"
    }
  ]
}
