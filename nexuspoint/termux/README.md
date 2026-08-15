# NexusPoint Termux Integration

This directory is the canonical Termux bootstrap for the NexusPoint memory fabric.

## Scope

It consolidates the design direction represented by the earlier GAIA scripts:

- GAIA cloud mount / OneDrive integration
- cloud hybrid sync daemon
- GAIA MemoryLink bridge
- policy-gate and accounting concepts
- GAIA command index / Architect CLI
- GAIA Ω SyncFabric heartbeat
- NEXUS MINDSTONE local-first runtime

The implementation intentionally does **not** copy secrets or device-specific network details into GitHub.

## Install

From Termux:

```bash
curl -fsSL https://raw.githubusercontent.com/NexusCryptic/Welcome-Sentience/agent/nexuspoint-termux-memory-fabric/nexuspoint/termux/nexuspoint-bootstrap.sh | bash
```

For a higher-assurance install, download the file first, inspect it, then execute it locally rather than piping remote content directly to a shell.

## Result

The bootstrap creates:

```text
$HOME/NexusPoint/
$HOME/Æ/private/
$HOME/Æ/cache/
$HOME/Æ/state/nexuspoint/
$HOME/Æ/bin/nexuspoint
$HOME/Æ/bin/nexuspoint-sync
$HOME/Æ/bin/nexuspoint-backup
$HOME/Æ/bin/nexuspoint-audit
```

The cloud mapping is environment-driven. The default OneDrive remote name is `onedrive`; the remote and root can be overridden without changing the script.

## First-run sequence

```bash
nexuspoint status
nexuspoint tree 2
nexuspoint-sync dry-run
nexuspoint-sync push
nexuspoint-audit
nexuspoint-backup
```

`pull` and `push` are deliberately explicit. Do not run bidirectional destructive sync until the provider topology and conflict policy have been verified.

## Local cognition boundary

Do not place `.env`, OAuth tokens, private keys, model credentials, raw device inventories, or private runtime caches inside NexusPoint. Keep them under the local Æ private/cache/state roots. The repository's `.gitignore` and `.nexusignore` reinforce this boundary but are not a substitute for review.
