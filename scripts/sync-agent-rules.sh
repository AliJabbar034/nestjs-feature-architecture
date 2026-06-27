#!/usr/bin/env bash
# Regenerate all agent rule files from rules/core-rules.md
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CORE="$ROOT/rules/core-rules.md"

if [[ ! -f "$CORE" ]]; then
  echo "Missing $CORE"
  exit 1
fi

echo "Syncing from $CORE ..."

# Cursor
{
  printf '%s\n' '---' 'alwaysApply: true' '---'
  cat "$CORE"
} > "$ROOT/agents/cursor/.cursor/rules/nestjs-feature-architecture.mdc"

# Claude
{
  cat << 'HDR'
# NestJS Feature Architecture

> Synced from `rules/core-rules.md`. Run `./scripts/sync-agent-rules.sh` after edits.

HDR
  cat "$CORE"
} > "$ROOT/agents/claude/CLAUDE.md"

cat > "$ROOT/agents/claude/AGENTS.md" << 'EOF'
@CLAUDE.md
EOF

# GitHub Copilot
{
  cat << 'HDR'
# NestJS Feature Architecture — Copilot Instructions

Apply these rules to all suggestions in this repository.

HDR
  cat "$CORE"
} > "$ROOT/agents/github-copilot/.github/copilot-instructions.md"

# Windsurf
{ echo "# NestJS Feature Architecture — Windsurf Rules"; echo; cat "$CORE"; } > "$ROOT/agents/windsurf/.windsurfrules"

# Gemini
{ echo "# NestJS Feature Architecture — Gemini Instructions"; echo; cat "$CORE"; } > "$ROOT/agents/gemini/GEMINI.md"

# Codex
{ echo "# NestJS Feature Architecture — Codex / Agent Instructions"; echo; cat "$CORE"; } > "$ROOT/agents/codex/AGENTS.md"

# Continue
{
  cat << 'HDR'
---
name: NestJS Feature Architecture
description: Shared NestJS engineering standards
alwaysApply: true
---

HDR
  cat "$CORE"
} > "$ROOT/agents/continue/.continue/rules/nestjs-feature-architecture.md"

# Aider
{ echo "# NestJS Feature Architecture — Aider Conventions"; echo; cat "$CORE"; } > "$ROOT/agents/aider/CONVENTIONS.md"

# JetBrains Junie
{ echo "# NestJS Feature Architecture — Junie Guidelines"; echo; cat "$CORE"; } > "$ROOT/agents/jetbrains-junie/.junie/guidelines.md"

echo "Done. Agent files updated."
