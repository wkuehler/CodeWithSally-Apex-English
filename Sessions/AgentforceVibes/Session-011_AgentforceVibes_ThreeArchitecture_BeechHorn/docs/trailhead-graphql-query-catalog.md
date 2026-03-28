## Trailhead GraphQL Query Catalog

This project keeps the Trailhead GraphQL integration source-of-truth in three places:

- `force-app/main/default/namedCredentials/Trailhead_API.namedCredential-meta.xml`
- `force-app/main/default/customMetadata/API_Endpoint__mdt.Trailhead_API.md-meta.xml`
- `force-app/main/default/staticresources/Trailhead_GraphQL_Query_Catalog.resource`

`TrailheadApiService` reads the named credential and GraphQL path from `API_Endpoint__mdt`, then loads the query documents from the catalog static resource. That keeps the live integration from hardcoding GraphQL strings in Apex while preserving a deployable, repo-owned definition of every supported query.

### Active Queries

`getTrailblazerRank`

- Source reference: [Trailhead-Banner `getTrailblazerRank.js`](https://github.com/nabondance/Trailhead-Banner/blob/main/src/graphql/queries/getTrailblazerRank.js)
- Used by: `TrailheadApiService.fetchRankData()`
- Purpose: load rank, points, badges, superbadges, certifications, and last badge date for a Trailblazer profile sync

`getTrailheadBadges`

- Source reference: [Trailhead-Banner `getTrailheadBadges.js`](https://github.com/nabondance/Trailhead-Banner/blob/main/src/graphql/queries/getTrailheadBadges.js)
- Used by: `TrailheadApiService.fetchBadges()`
- Purpose: page through Trailhead badges with `hasNextPage` and `endCursor`

`getUserCertifications`

- Source reference: [Trailhead-Banner `getUserCertifications.js`](https://github.com/nabondance/Trailhead-Banner/blob/main/src/graphql/queries/getUserCertifications.js)
- Used by: `TrailheadApiService.fetchCertifications()`
- Purpose: load certification data for sync and rollups

### Available Reference Queries

`getAgentblazerRank`

- Source reference: [Trailhead-Banner `getAgentblazerRank.js`](https://github.com/nabondance/Trailhead-Banner/blob/main/src/graphql/queries/getAgentblazerRank.js)
- Available through: `TrailheadApiService.fetchAgentblazerRank()`
- Purpose: expose Agentblazer learner status levels for future gamification work

`getMvpStatus`

- Source reference: [Trailhead-Banner `getMvpStatus.js`](https://github.com/nabondance/Trailhead-Banner/blob/main/src/graphql/queries/getMvpStatus.js)
- Available through: `TrailheadApiService.fetchMvpStatus()`
- Purpose: expose Trailblazer Community MVP status for future profile enrichment

`getStamps`

- Source reference: [Trailhead-Banner `getStamps.js`](https://github.com/nabondance/Trailhead-Banner/blob/main/src/graphql/queries/getStamps.js)
- Available through: `TrailheadApiService.fetchStamps()`
- Purpose: expose earned stamps and stamp pagination for future achievement expansion

### Notes

- The active sync pipeline still uses the current repo's response-shape expectations for rank, badge, and certification parsing.
- The query catalog preserves the upstream query identities and documentation so the solution can evolve without moving integration logic back into hardcoded Apex strings.
- The public Trailhead GraphQL endpoint remains read-only and is accessed through the `Trailhead_API` named credential.
