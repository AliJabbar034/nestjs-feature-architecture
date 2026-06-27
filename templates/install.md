# Install checklist

Three ways — **no full clone required** for methods 1 and 2.

---

## Method 1 — One command (from app root)

```bash
curl -fsSL https://raw.githubusercontent.com/AliJabbar034/nestjs-feature-architecture/main/scripts/install.sh | bash -s -- --all
```

Pick agents:

```bash
curl -fsSL https://raw.githubusercontent.com/AliJabbar034/nestjs-feature-architecture/main/scripts/install.sh | bash -s -- --cursor --claude
```

---

## Method 2 — Copy folder / ZIP (no clone)

1. Download ZIP from GitHub **Code → Download ZIP**, or copy the shared folder
2. Run:

```bash
GUIDE=~/Downloads/nestjs-feature-architecture-main   # adjust path
cd /path/to/your-nestjs-app
$GUIDE/scripts/install.sh --all --source "$GUIDE"
```

---

## Method 3 — Manual copy

Set `GUIDE` to the guide repo root (unzipped folder or clone):

```bash
GUIDE=/path/to/nestjs-feature-architecture
cd /path/to/your-nestjs-app
```

| Tool | Command |
| --- | --- |
| **All (script)** | `$GUIDE/scripts/install.sh --all --source "$GUIDE"` |
| **Cursor** | `mkdir -p .cursor/rules && cp $GUIDE/agents/cursor/.cursor/rules/nestjs-feature-architecture.mdc .cursor/rules/` |
| **Claude** | `cp $GUIDE/agents/claude/CLAUDE.md $GUIDE/agents/claude/AGENTS.md .` |
| **Copilot** | `mkdir -p .github && cp $GUIDE/agents/github-copilot/.github/copilot-instructions.md .github/` |
| **Windsurf** | `cp $GUIDE/agents/windsurf/.windsurfrules .` |
| **Gemini** | `cp $GUIDE/agents/gemini/GEMINI.md .` |
| **Codex** | `cp $GUIDE/agents/codex/AGENTS.md .` |
| **Continue** | `mkdir -p .continue/rules && cp $GUIDE/agents/continue/.continue/rules/nestjs-feature-architecture.md .continue/rules/` |
| **Aider** | `cp $GUIDE/agents/aider/CONVENTIONS.md .` |
| **Junie** | `mkdir -p .junie && cp $GUIDE/agents/jetbrains-junie/.junie/guidelines.md .junie/` |

---

## After install

- [ ] Commit rule files in your app repo
- [ ] Customize ORM (TypeORM / Prisma), database, and auth
- [ ] Add validated config and `.env.example`
- [ ] Ensure ESLint + Prettier + Husky (see rules)
- [ ] Share this guide repo link with the team for updates
