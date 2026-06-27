#!/usr/bin/env bash
# Install AI agent rules into a NestJS app — no git clone required.
#
# Usage (from your app root):
#   One command (downloads from GitHub):
#     curl -fsSL https://raw.githubusercontent.com/AliJabbar034/nestjs-feature-architecture/main/scripts/install.sh | bash -s -- --all
#
#   Local copy (you already have the guide folder):
#     /path/to/nestjs-feature-architecture/scripts/install.sh --all --source /path/to/nestjs-feature-architecture
#
#   Pick agents:
#     bash install.sh --cursor --claude --copilot
#
set -euo pipefail

# ── Config (override with env) ───────────────────────────────────────────────
GITHUB_REPO="${GITHUB_REPO:-AliJabbar034/nestjs-feature-architecture}"
GITHUB_BRANCH="${GITHUB_BRANCH:-main}"
REPO_RAW="https://raw.githubusercontent.com/${GITHUB_REPO}/${GITHUB_BRANCH}"

TARGET_DIR="$(pwd)"
SOURCE_DIR=""
USE_REMOTE=0

INSTALL_CURSOR=0
INSTALL_CLAUDE=0
INSTALL_COPILOT=0
INSTALL_WINDSURF=0
INSTALL_GEMINI=0
INSTALL_CODEX=0
INSTALL_CONTINUE=0
INSTALL_AIDER=0
INSTALL_JUNIE=0

usage() {
  cat << 'EOF'
Install NestJS Feature Architecture rules into your app.

Usage:
  install.sh [options]

Options:
  --all                 Install every supported agent
  --cursor              Cursor (.cursor/rules/)
  --claude              Claude Code (CLAUDE.md + AGENTS.md)
  --copilot             GitHub Copilot (.github/copilot-instructions.md)
  --windsurf            Windsurf (.windsurfrules)
  --gemini              Gemini (GEMINI.md)
  --codex               Codex / generic (AGENTS.md)
  --continue            Continue.dev (.continue/rules/)
  --aider               Aider (CONVENTIONS.md)
  --junie               JetBrains Junie (.junie/guidelines.md)
  --target <dir>        App directory (default: current directory)
  --source <dir>        Local guide repo path (skip download)
  --remote              Force download from GitHub (default if no --source)
  -h, --help            Show this help

Examples:
  # One-liner from GitHub:
  curl -fsSL https://raw.githubusercontent.com/AliJabbar034/nestjs-feature-architecture/main/scripts/install.sh | bash -s -- --all

  # Copy from a folder you downloaded (zip) or shared — no clone:
  ./install.sh --all --source ~/Downloads/nestjs-feature-architecture-main

  # Only Cursor + Claude into another app:
  ./install.sh --cursor --claude --target ../my-nest-app
EOF
}

log() { printf '→ %s\n' "$*"; }
die() { printf 'Error: %s\n' "$*" >&2; exit 1; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all)       INSTALL_CURSOR=1; INSTALL_CLAUDE=1; INSTALL_COPILOT=1; INSTALL_WINDSURF=1
                 INSTALL_GEMINI=1; INSTALL_CODEX=1; INSTALL_CONTINUE=1; INSTALL_AIDER=1; INSTALL_JUNIE=1 ;;
    --cursor)    INSTALL_CURSOR=1 ;;
    --claude)    INSTALL_CLAUDE=1 ;;
    --copilot)   INSTALL_COPILOT=1 ;;
    --windsurf)  INSTALL_WINDSURF=1 ;;
    --gemini)    INSTALL_GEMINI=1 ;;
    --codex)     INSTALL_CODEX=1 ;;
    --continue)  INSTALL_CONTINUE=1 ;;
    --aider)     INSTALL_AIDER=1 ;;
    --junie)     INSTALL_JUNIE=1 ;;
    --target)    shift; TARGET_DIR="${1:?--target requires a path}" ;;
    --source)    shift; SOURCE_DIR="${1:?--source requires a path}" ;;
    --remote)    USE_REMOTE=1 ;;
    -h|--help)   usage; exit 0 ;;
    *)           die "Unknown option: $1 (try --help)" ;;
  esac
  shift
done

if [[ "$INSTALL_CURSOR$INSTALL_CLAUDE$INSTALL_COPILOT$INSTALL_WINDSURF$INSTALL_GEMINI$INSTALL_CODEX$INSTALL_CONTINUE$INSTALL_AIDER$INSTALL_JUNIE" == "000000000" ]]; then
  die "Pick at least one agent (--all, --cursor, --claude, …) or run --help"
fi

[[ -d "$TARGET_DIR" ]] || die "Target directory does not exist: $TARGET_DIR"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

# Resolve guide root
CLEANUP=""
if [[ -n "$SOURCE_DIR" ]]; then
  [[ -d "$SOURCE_DIR/agents" ]] || die "--source must point to nestjs-feature-architecture root (missing agents/)"
  GUIDE_ROOT="$(cd "$SOURCE_DIR" && pwd)"
  log "Using local guide: $GUIDE_ROOT"
elif [[ -n "${BASH_SOURCE[0]:-}" ]] && [[ -f "${BASH_SOURCE[0]}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [[ -d "$SCRIPT_DIR/../agents" ]]; then
    GUIDE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
    log "Using local guide (script location): $GUIDE_ROOT"
  else
    USE_REMOTE=1
  fi
else
  USE_REMOTE=1
fi

if [[ "$USE_REMOTE" == "1" ]] && [[ -z "${GUIDE_ROOT:-}" ]]; then
  [[ -n "$GITHUB_REPO" ]] || die "Set GITHUB_REPO=owner/nestjs-feature-architecture or use --source /path/to/guide"
  TMP="$(mktemp -d)"
  CLEANUP="$TMP"
  ZIP="$TMP/guide.zip"
  log "Downloading ${GITHUB_REPO}@${GITHUB_BRANCH} (no clone)…"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "https://github.com/${GITHUB_REPO}/archive/refs/heads/${GITHUB_BRANCH}.zip" -o "$ZIP"
  elif command -v wget >/dev/null 2>&1; then
    wget -q "https://github.com/${GITHUB_REPO}/archive/refs/heads/${GITHUB_BRANCH}.zip" -O "$ZIP"
  else
    die "Need curl or wget to download the guide"
  fi
  unzip -q "$ZIP" -d "$TMP"
  GUIDE_ROOT="$TMP/nestjs-feature-architecture-${GITHUB_BRANCH}"
  [[ -d "$GUIDE_ROOT" ]] || GUIDE_ROOT="$TMP/$(ls "$TMP" | head -1)"
  [[ -d "$GUIDE_ROOT/agents" ]] || die "Download failed or repo layout changed"
  log "Extracted to temp: $GUIDE_ROOT"
fi

AGENTS="$GUIDE_ROOT/agents"
[[ -d "$AGENTS" ]] || die "Missing agents/ in guide root"

copy_file() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  log "Created ${dest#$TARGET_DIR/}"
}

log "Installing into: $TARGET_DIR"
echo

[[ "$INSTALL_CURSOR" == "1" ]] && \
  copy_file "$AGENTS/cursor/.cursor/rules/nestjs-feature-architecture.mdc" \
            "$TARGET_DIR/.cursor/rules/nestjs-feature-architecture.mdc"

[[ "$INSTALL_CLAUDE" == "1" ]] && {
  copy_file "$AGENTS/claude/CLAUDE.md" "$TARGET_DIR/CLAUDE.md"
  copy_file "$AGENTS/claude/AGENTS.md" "$TARGET_DIR/AGENTS.md"
}

[[ "$INSTALL_COPILOT" == "1" ]] && \
  copy_file "$AGENTS/github-copilot/.github/copilot-instructions.md" \
            "$TARGET_DIR/.github/copilot-instructions.md"

[[ "$INSTALL_WINDSURF" == "1" ]] && \
  copy_file "$AGENTS/windsurf/.windsurfrules" "$TARGET_DIR/.windsurfrules"

[[ "$INSTALL_GEMINI" == "1" ]] && \
  copy_file "$AGENTS/gemini/GEMINI.md" "$TARGET_DIR/GEMINI.md"

[[ "$INSTALL_CODEX" == "1" ]] && \
  copy_file "$AGENTS/codex/AGENTS.md" "$TARGET_DIR/AGENTS.md"

[[ "$INSTALL_CONTINUE" == "1" ]] && \
  copy_file "$AGENTS/continue/.continue/rules/nestjs-feature-architecture.md" \
            "$TARGET_DIR/.continue/rules/nestjs-feature-architecture.md"

[[ "$INSTALL_AIDER" == "1" ]] && \
  copy_file "$AGENTS/aider/CONVENTIONS.md" "$TARGET_DIR/CONVENTIONS.md"

[[ "$INSTALL_JUNIE" == "1" ]] && \
  copy_file "$AGENTS/jetbrains-junie/.junie/guidelines.md" "$TARGET_DIR/.junie/guidelines.md"

[[ -n "$CLEANUP" ]] && rm -rf "$CLEANUP"

echo
log "Done. Commit the new files in your app repo."
log "Customize ORM, database, auth, and env details in the copied rules."
