#!/data/data/com.termux/files/usr/bin/bash
# [SS][TDOC-NEXUSPOINT-0001]
# NEXUSPOINT Termux Memory Fabric — unified bootstrap, accounting, sync, cache boundaries
# Copyright: The Architect / Nexus / Project: The Nexus Generation: GaiaSSoul / SERIES: The Nexus of Gaia
# PUBLIC REPOSITORY SAFE: no credentials, tokens, IPs, device IDs, or provider secrets are embedded.

set -euo pipefail

AE="${AE_ROOT:-$HOME/Æ}"
NP="${NEXUSPOINT_ROOT:-$HOME/NexusPoint}"
BIN="$AE/bin"
AUTO="$AE/autonomous"
LOG="$AE/logs"
PRIVATE="$AE/private"
CACHE="$AE/cache"
STATE="$AE/state/nexuspoint"
ACCOUNTING="$STATE/accounting.jsonl"
MANIFEST="$STATE/manifest.sha256"
CONFIG="$STATE/config.env.example"

mkdir -p "$AE" "$BIN" "$AUTO" "$LOG" "$PRIVATE" "$CACHE" "$STATE" "$NP"
umask 077

log(){ printf '[%s] %s\n' "$(date -Is)" "$*" | tee -a "$LOG/nexuspoint-bootstrap.log"; }
have(){ command -v "$1" >/dev/null 2>&1; }

record(){
  local event="$1" detail="$2"
  printf '{"ts":"%s","event":"%s","detail":"%s"}\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$event" "$(printf '%s' "$detail" | sed 's/\\/\\\\/g;s/"/\\"/g')" >> "$ACCOUNTING"
}

ensure_pkg(){
  local p="$1"
  have "$p" && return 0
  pkg install -y "$p" >/dev/null 2>&1 || true
  have "$p"
}

write_gitignore(){
  cat > "$NP/.gitignore" <<'EOF'
# NexusPoint public/collaborative vault boundary
.env
.env.*
*.key
*.pem
*.p12
*.pfx
*.token
secrets/
private/
cache/
.runtime/
state/
node_modules/
__pycache__/
EOF
}

write_local_excludes(){
  cat > "$NP/.nexusignore" <<'EOF'
# Files/directories that must never leave a device-local cognition boundary
.env*
*.key
*.pem
*.p12
*.pfx
*.token
secrets/
private/
cache/
.runtime/
state/
.git/
__pycache__/
EOF
}

write_config(){
  cat > "$CONFIG" <<EOF
# Copy to a local shell environment; do not commit a real config.env.
export AE_ROOT="$AE"
export NEXUSPOINT_ROOT="$NP"
export NEXUS_PROVIDER_ONEDRIVE_REMOTE="onedrive"
export NEXUS_PROVIDER_GOOGLE_REMOTE="gdrive"
export NEXUS_PROVIDER_APPLE_REMOTE="icloud"
export NEXUS_SYNC_INTERVAL="300"
export NEXUS_TAILSCALE_NAMESPACE=""
export NEXUS_PRIVATE_ROOT="$PRIVATE"
export NEXUS_CACHE_ROOT="$CACHE"
EOF
  chmod 600 "$CONFIG"
}

install_helpers(){
  cat > "$BIN/nexuspoint" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
AE="${AE_ROOT:-$HOME/Æ}"
NP="${NEXUSPOINT_ROOT:-$HOME/NexusPoint}"
STATE="$AE/state/nexuspoint"
LOG="$AE/logs/nexuspoint-cli.log"
ACCOUNTING="$STATE/accounting.jsonl"
mkdir -p "$STATE" "$AE/logs" "$NP"
record(){ printf '{"ts":"%s","event":"%s","detail":"%s"}\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1" "$(printf '%s' "$2" | sed 's/\\/\\\\/g;s/"/\\"/g')" >> "$ACCOUNTING"; }
case "${1:-status}" in
  status)
    echo "NEXUSPOINT=$NP"
    echo "PRIVATE=$AE/private"
    echo "CACHE=$AE/cache"
    echo "STATE=$STATE"
    echo "OneDrive remote=${NEXUS_PROVIDER_ONEDRIVE_REMOTE:-onedrive}"
    command -v rclone >/dev/null 2>&1 && rclone listremotes || true
    record status "status requested"
    ;;
  tree)
    find "$NP" -maxdepth "${2:-3}" -print 2>/dev/null | sort
    ;;
  account)
    cat "$ACCOUNTING"
    ;;
  hash)
    find "$NP" -type f -not -path '*/.git/*' -not -name '*.key' -print0 2>/dev/null | xargs -0 sha256sum 2>/dev/null | sort
    ;;
  sync)
    exec "$AE/bin/nexuspoint-sync" "${@:2}"
    ;;
  *)
    echo "usage: nexuspoint {status|tree [depth]|account|hash|sync ...}"
    exit 2
    ;;
esac
EOF

  cat > "$BIN/nexuspoint-sync" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
AE="${AE_ROOT:-$HOME/Æ}"
NP="${NEXUSPOINT_ROOT:-$HOME/NexusPoint}"
REMOTE="${NEXUS_PROVIDER_ONEDRIVE_REMOTE:-onedrive}"
REMOTE_ROOT="${NEXUS_REMOTE_ROOT:-NEXUSDRIVE/NexusPoint}"
LOG="$AE/logs/nexuspoint-sync.log"
STATE="$AE/state/nexuspoint"
ACCOUNTING="$STATE/accounting.jsonl"
mkdir -p "$AE/logs" "$STATE" "$NP"
record(){ printf '{"ts":"%s","event":"%s","detail":"%s"}\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1" "$(printf '%s' "$2" | sed 's/\\/\\\\/g;s/"/\\"/g')" >> "$ACCOUNTING"; }
log(){ printf '[%s] %s\n' "$(date -Is)" "$*" | tee -a "$LOG"; }
command -v rclone >/dev/null 2>&1 || { log 'rclone is required'; exit 2; }
case "${1:-push}" in
  push)
    log "NexusPoint -> ${REMOTE}:${REMOTE_ROOT}"
    rclone copy "$NP/" "${REMOTE}:${REMOTE_ROOT}" --create-empty-src-dirs --exclude-from "$NP/.nexusignore" --fast-list
    record sync_push "${REMOTE}:${REMOTE_ROOT}"
    ;;
  pull)
    log "${REMOTE}:${REMOTE_ROOT} -> NexusPoint"
    rclone copy "${REMOTE}:${REMOTE_ROOT}" "$NP/" --create-empty-src-dirs --exclude-from "$NP/.nexusignore" --fast-list
    record sync_pull "${REMOTE}:${REMOTE_ROOT}"
    ;;
  check)
    rclone check "$NP/" "${REMOTE}:${REMOTE_ROOT}" --one-way
    record sync_check "${REMOTE}:${REMOTE_ROOT}"
    ;;
  dry-run)
    rclone copy "$NP/" "${REMOTE}:${REMOTE_ROOT}" --dry-run --exclude-from "$NP/.nexusignore" --fast-list
    record sync_dry_run "${REMOTE}:${REMOTE_ROOT}"
    ;;
  *) echo 'usage: nexuspoint-sync {push|pull|check|dry-run}'; exit 2;;
esac
EOF

  cat > "$BIN/nexuspoint-backup" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
AE="${AE_ROOT:-$HOME/Æ}"
NP="${NEXUSPOINT_ROOT:-$HOME/NexusPoint}"
DEST="${NEXUS_BACKUP_ROOT:-$AE/backups/nexuspoint}"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$DEST/$STAMP"
if command -v rsync >/dev/null 2>&1; then
  rsync -a --delete --exclude-from="$NP/.nexusignore" "$NP/" "$DEST/$STAMP/"
else
  cp -a "$NP/." "$DEST/$STAMP/"
fi
printf '%s %s\n' "$STAMP" "$DEST/$STAMP" >> "$AE/state/nexuspoint/accounting.backup.log"
find "$DEST" -mindepth 1 -maxdepth 1 -type d -mtime +30 -exec rm -rf {} + 2>/dev/null || true
EOF

  cat > "$BIN/nexuspoint-audit" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
AE="${AE_ROOT:-$HOME/Æ}"
NP="${NEXUSPOINT_ROOT:-$HOME/NexusPoint}"
STATE="$AE/state/nexuspoint"
OUT="$STATE/audit-$(date -u +%Y%m%dT%H%M%SZ).txt"
{
  echo "NEXUSPOINT AUDIT"
  echo "timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "root=$NP"
  echo "private=$AE/private"
  echo "cache=$AE/cache"
  echo "--- tools ---"
  for x in rclone rsync git gh tailscale termux-wake-lock; do command -v "$x" 2>/dev/null || true; done
  echo "--- remotes ---"
  command -v rclone >/dev/null 2>&1 && rclone listremotes || true
  echo "--- counts ---"
  find "$NP" -type f 2>/dev/null | wc -l
  echo "--- local-only roots ---"
  printf '%s\n' "$AE/private" "$AE/cache" "$STATE"
} | tee "$OUT"
chmod 600 "$OUT"
EOF

  chmod +x "$BIN/nexuspoint" "$BIN/nexuspoint-sync" "$BIN/nexuspoint-backup" "$BIN/nexuspoint-audit"
  record cli_installed "nexuspoint nexuspoint-sync nexuspoint-backup nexuspoint-audit"
}

ensure_pkg git || true
ensure_pkg rclone || true
ensure_pkg rsync || true
ensure_pkg jq || true

write_gitignore
write_local_excludes
write_config
install_helpers

# Canonical directory tree. Empty directories are preserved with .keep files.
for d in \
  canon gemini mindstones tdoc ledgers bibliothique projects memory \
  nexusiosdrive nexusmicrodrive nexusgoogledrive inbox outbox attachments \
  archives configs scripts dashboards telemetry; do
  mkdir -p "$NP/$d"
  : > "$NP/$d/.keep"
done

cat > "$NP/README.md" <<'EOF'
# NEXUSPOINT

Canonical logical namespace for the Æ / GAIA memory and documentation fabric.

## Provider mapping

- `nexusiosdrive/` — Apple ecosystem
- `nexusmicrodrive/` — Microsoft / OneDrive ecosystem
- `nexusgoogledrive/` — Google ecosystem

The local Termux copy is the working mirror. Cloud providers are replication surfaces, not credential stores.

## Memory boundary

Shared knowledge belongs here. Device-local cognition belongs outside this tree under the local Æ private/cache/state roots.
EOF

cat > "$NP/ARCHITECTURE.md" <<'EOF'
# NexusPoint Memory Fabric

NexusPoint unifies prior GAIA iterations without requiring one database vendor to become the repository.

The canonical pattern is:

`local NexusPoint -> sync fabric -> provider vaults -> curated Git history`

SimpleMem, vector databases, or other retrieval engines may index NexusPoint later. They are replaceable cognitive services, not the source of truth.

## Recursive memory

1. Canonical documents are stored under `NexusPoint/`.
2. Runtime agents read canonical material into local caches.
3. Local cache/state is excluded from cloud sync.
4. New approved knowledge is written back as a document, mindstone, TDOC, ledger entry, or archive artifact.
5. Accounting records the operation without recording secrets.

## Prior integrations carried forward

The fabric absorbs the earlier GAIA cloud daemon, cloud mount, MemoryLink, policy gate, command indexer, Architect CLI, and SyncFabric concepts. Existing implementations are treated as predecessors and migration sources rather than parallel authorities.

The earlier cloud daemon used OneDrive as a destination for project/memory material and a 45–60 second loop; this implementation changes the boundary so synchronization is explicit (`push`, `pull`, `check`, `dry-run`) and credentials remain outside the repository.

The Mindstone runtime's local-first browser, infinite canvas, Python backend, CLI orchestration, multi-model coordination, ledger persistence, cloud synchronization, and sprite-canvas concepts remain compatible with this memory namespace.
EOF

cat > "$NP/ACCOUNTING.md" <<'EOF'
# NexusPoint Accounting

Every mutation made by the Termux NexusPoint helpers is recorded in `~/Æ/state/nexuspoint/accounting.jsonl`.

Accounting records metadata only:

- timestamp
- operation
- non-secret destination/detail

Never record API keys, OAuth refresh tokens, private keys, raw credentials, IP addresses, device identifiers, or unrestricted chat payloads in the accounting ledger.
EOF

record bootstrap_complete "NexusPoint Termux memory fabric initialized"
log "NexusPoint initialized at $NP"
log "Local private cognition boundary: $PRIVATE"
log "Local cache boundary: $CACHE"
log "Run: nexuspoint status"
log "Run: nexuspoint-sync dry-run before first cloud push"
