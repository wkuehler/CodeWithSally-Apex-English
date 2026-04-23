# Conversation Summary — 2026-04-21

## Topics Covered

### LWC vs Aura (Salesforce UI Frameworks)
- **Aura**: Older proprietary Salesforce framework (~2014), verbose syntax, heavier runtime, legacy status.
- **LWC**: Modern framework built on web standards (HTML/JS/CSS), better performance, Jest testability, current recommended approach.
- Verdict: Use LWC for all new development; Aura only for legacy maintenance.

### Calling Apex from LWC
- Two approaches: `@wire` (declarative, reactive, for reads) and imperative (manual, required for DML).
- Apex methods must be annotated with `@AuraEnabled`; add `cacheable=true` for use with `@wire`.
- Methods must be `public static`.

### Judas Priest — Lead Singer
- **Rob Halford** ("The Metal God") is the lead vocalist.
- With the band since 1969; briefly replaced by Tim "Ripper" Owens (1992–2003); rejoined in 2003 and still with the band.
