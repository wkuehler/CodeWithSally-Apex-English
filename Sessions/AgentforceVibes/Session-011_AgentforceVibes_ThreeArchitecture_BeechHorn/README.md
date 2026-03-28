# Trailhead Gamified Learning Platform

This repository contains the SFDX source for a Salesforce-native app that helps learners track progress, stay motivated, and build community around their Trailhead journey.

Phase 1 delivers the metadata-only foundation:
- six custom objects
- four Custom Metadata Types
- seed configuration metadata
- deploy and validation scripts

No Apex, LWC, Aura, FlexiPages, or permission-set rollout is included in this phase.

## Prerequisites

- Salesforce CLI (`sf`) installed
- Node.js LTS
- an authenticated target org
- a default username configured, or an org alias passed to the scripts

## Project Structure

All deployable metadata lives under `force-app/main/default/`.

- `objects/`
  - `Trailblazer_Profile__c`
  - `Badge__c`
  - `Certification__c`
  - `Discovery__c`
  - `Quest__c`
  - `Quest_Enrollment__c`
  - `Level_Definition__mdt`
  - `XP_Rule__mdt`
  - `Achievement_Definition__mdt`
  - `Streak_Config__mdt`
- `customMetadata/`
  - 12 level definitions
  - 8 XP rules
  - 20 achievement definitions
  - 1 streak config
- `tabs/`
  - `Trailblazer_Profile__c`
  - `Quest__c`

Baseline directories for later phases also exist:
- `permissionsets/`
- `applications/`
- `flexipages/`
- `staticresources/`
- `profiles/`
- `settings/`

## Scripts

- `scripts/validate.sh [target-org]`
  - runs a dry-run deploy against `force-app`
  - prints raw JSON output
  - exits non-zero if deploy success is false or test errors are reported
- `scripts/deploy.sh [target-org]`
  - runs a live deploy against `force-app`
- `scripts/setup.sh [target-org]`
  - deploys Phase 1 metadata
  - attempts to assign `Trailblazer_Admin` if it exists
  - prints the placeholder seed-data command for later phases

Make scripts executable if needed:

```bash
chmod +x scripts/*.sh
```

## Quick Start

1. Check authenticated orgs and confirm the default username:

```bash
sf org list
sf org display --target-org default
```

2. Run a dry-run validation deploy:

```bash
./scripts/validate.sh
```

3. Deploy the Phase 1 metadata:

```bash
./scripts/deploy.sh
```

4. Run the end-to-end setup flow:

```bash
./scripts/setup.sh
```

To target a non-default org, pass an alias:

```bash
./scripts/validate.sh tj-dev
./scripts/deploy.sh tj-dev
./scripts/setup.sh tj-dev
```

## Verification Checklist

After deployment, verify:
- all six custom objects exist
- the three external ID fields are present on `Trailblazer_Profile__c`, `Badge__c`, and `Certification__c`
- validation rules exist on `Certification__c`, `Discovery__c`, `Quest__c`, and `Quest_Enrollment__c`
- two custom tabs exist
- custom metadata record counts are `12`, `8`, `20`, and `1`

## Notes

- Use `sf`, not legacy `sfdx`.
- All configurable thresholds are stored in Custom Metadata Types.
- See `recording/PHASE1.md` for the authoritative Phase 1 build plan.
