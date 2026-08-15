# NEXUSPOINT MEMORY FABRIC

**TDOC:** TDOC-NEXUSPOINT-0001
**Revision:** 1.0.0
**Status:** evolving foundation

## 1. Purpose

NexusPoint is the logical root for Æ documentation, memory, project artifacts, mindstones, ledgers, and curated archives. It is a namespace, not a single cloud provider and not a single memory engine.

## 2. Storage hierarchy

```text
NEXUSPOINT/
├── canon/                  finalized documentation
├── gemini/                 Gemini instructions and context
├── mindstones/             durable memory units
├── tdoc/                   technical documents and scripts
├── ledgers/                append-only accounting artifacts
├── bibliothique/           merged/archive-readable documents
├── projects/               recovered and active projects
├── memory/                 approved shared memory material
├── nexusiosdrive/          Apple provider surface
├── nexusmicrodrive/        Microsoft provider surface
├── nexusgoogledrive/       Google provider surface
├── inbox/                  inbound material
├── outbox/                 outbound material
├── attachments/            non-secret source attachments
├── archives/               immutable/dated exports
├── configs/                sanitized configuration templates
├── scripts/                shareable automation
├── dashboards/             UI artifacts
└── telemetry/              sanitized telemetry
```

## 3. Cognitive boundary

The repository is shared knowledge. Device-local cognition remains outside it:

```text
~/Æ/private/
~/Æ/cache/
~/Æ/state/
```

These roots may contain runtime state, indexes, tokens, caches, and other material that must not enter cloud or public Git history.

## 4. Provider fabric

The current architecture permits multiple independent cloud surfaces:

- Microsoft OneDrive as the first operational provider.
- Google Drive/Vault as a secondary archive/collaboration provider.
- Apple storage as a provider surface for the Apple node.
- GitHub private repositories for curated code/document history.

No agent should hardcode a provider path. Provider names and roots are configuration values.

## 5. Synchronization

Primary local synchronization can use Syncthing over an authenticated private network. Cloud replication can use rclone. Local backups can use rsync. Git is used for versioned, sanitized canon.

The Termux implementation exposes explicit:

- `nexuspoint-sync dry-run`
- `nexuspoint-sync push`
- `nexuspoint-sync pull`
- `nexuspoint-sync check`

This is intentionally safer than an always-destructive bidirectional loop.

## 6. Accounting

Operations are recorded locally in JSONL. The accounting ledger records operation metadata, not secrets. Hashes may be generated for integrity verification without recording the underlying sensitive content.

## 7. Retrieval engines

SimpleMem is optional. It can consume the canonical NexusPoint corpus as an indexing/retrieval layer. The repository remains portable if SimpleMem is removed, replaced, or supplemented with another retrieval engine.

This is the key architectural distinction: **storage is durable; retrieval is replaceable.**

## 8. Migration rule

Older GAIA scripts are treated as migration sources. The fabric does not silently execute old daemons merely because they exist. Existing projects should be catalogued, classified, sanitized, migrated, tested, and then enabled through one canonical command surface.

## 9. Evolution

Every substantial revision should update:

1. version metadata;
2. architecture documentation;
3. accounting schema if changed;
4. migration notes;
5. validation checks;
6. recovery instructions.

The system should grow by replacing components behind stable interfaces rather than accumulating unrelated parallel roots.
