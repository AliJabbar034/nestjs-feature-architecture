# AGENTS.md

## Project Stack

### Core

* Framework: **NestJS 11+**
* Language: TypeScript (strict mode)
* Runtime: Node.js 20+ LTS
* HTTP: REST API (default); GraphQL only when explicitly in stack
* Validation: **class-validator** + **class-transformer** on DTOs (default Nest pattern)
* Configuration: `@nestjs/config` + validated env schema
* Authentication: **Passport** + JWT — default **`@nestjs/jwt`**; on greenfield auth work **ask** if the user prefers **[jose](https://www.npmjs.com/package/jose)** instead (see **Authentication Rules**)
* API docs: **@nestjs/swagger** (OpenAPI)
* Package Manager: follow **Package manager** rules below

### Data & persistence — ask before choosing

Before adding ORM, migrations, or cache:

| Layer | Options | Agent rule |
| --- | --- | --- |
| **ORM** | TypeORM, Prisma, MikroORM, Drizzle | **Ask** which is in use or requested; match existing repo |
| **Database** | PostgreSQL (default recommendation), MySQL, MongoDB | **Ask** if not configured |
| **Cache / queue** | Redis, BullMQ, `@nestjs/bullmq` | **Ask** before adding |

Do not introduce a second ORM or query layer in the same project without explicit approval.

### Code quality (required in every clone)

* **ESLint** — `@nestjs/eslint-plugin` + TypeScript ESLint
* **Prettier** — consistent formatting
* **eslint-config-prettier** — no conflicting format rules
* **Husky** — git hooks via `prepare` script
* **lint-staged** — ESLint + Prettier on staged files in pre-commit

If any of the above is missing, set it up before feature work (see **Code Quality Rules**).

### Documentation (required)

* **README.md** — install, scripts, env vars, module structure, API base URL
* **Agent rules file** — architecture and agent rules (canonical copy — update all agent folders from `rules/core-rules.md`)
* **Swagger** — document public controllers when `@nestjs/swagger` is in stack

### Environment & config

* Env validation: `src/config/env.schema.ts` or `src/config/configuration.ts` (single source for `process.env`)
* Never read `process.env.*` directly outside config module
* Provide **`.env.example`** with all required keys (no secrets)

### Not in stack — ask before adding

Do **not** install or introduce these without explicit approval:

**Data & infra**

* A second ORM or raw SQL layer competing with the chosen one
* GraphQL (`@nestjs/graphql`) when the project is REST-only
* Alternative validation libraries (Zod-only DTOs, Joi-only) if class-validator is already standard — or vice versa
* Message brokers, search engines, or caches not already in the project

**Auth & security**

* Alternative auth stacks (Auth0 SDK in controllers, custom JWT without Passport, session stores) when Passport JWT is established
* Storing refresh tokens in client-accessible storage (mobile/web clients must use HttpOnly cookies or secure token exchange — document the chosen flow)

**Tooling**

* Extra formatters, linters, or commit hooks beyond **ESLint + Prettier + Husky + lint-staged**
* Competing test runners without team agreement (Nest default is **Jest**)

**Architecture**

* Business logic in controllers or guards instead of services
* Cross-module imports that bypass the module system (import another feature’s internals instead of its public module exports)
* Global mutable singletons outside Nest DI

### API style — confirm first

Before new endpoints, confirm:

| Style | Use when |
| --- | --- |
| **REST** (default) | Standard CRUD, public HTTP API, Swagger docs |
| **GraphQL** | Project already uses `@nestjs/graphql` and schema is defined |
| **Microservice transport** | TCP/Redis/NATS/Kafka handlers — separate from HTTP controllers |
| **WebSocket gateway** | Real-time features (chat, notifications, live updates) |

**Ask** if the task needs GraphQL, gRPC, or microservice handlers and the repo is REST-only.

---

# Architecture Principles

* Prefer consistency over cleverness.
* Prefer existing patterns over introducing new ones.
* Match existing **file and data-type naming** in project-owned code; on greenfield or inconsistent repos, **ask** the user which convention to use (see **Naming Rules**).
* Prefer **thin controllers** — HTTP concerns only; business logic in **services**.
* Prefer **Nest modules** for feature boundaries — one module per domain.
* Prefer built-in Nest patterns (pipes, guards, filters, interceptors) over ad-hoc middleware.
* Keep modules small and composable.
* Keep business logic isolated inside feature services (and repositories when used).

---

# Folder Structure

```text
src/
│
├── main.ts
├── app.module.ts
├── config/                 # Env schema, configuration factory
├── common/                 # Cross-cutting (shared across modules)
│   ├── decorators/
│   ├── filters/
│   ├── guards/
│   ├── interceptors/
│   ├── pipes/
│   ├── dto/                # Shared DTOs (pagination, api response)
│   └── utils/
├── modules/                # Feature modules (preferred name)
│   └── users/
│       ├── users.module.ts
│       ├── users.controller.ts
│       ├── users.service.ts
│       ├── dto/
│       ├── entities/       # TypeORM / MikroORM entities (if applicable)
│       ├── repositories/   # Optional repository wrappers
│       └── interfaces/
└── database/               # Migrations, seeds, data source (if applicable)
```

Use `modules/` or `features/` — **follow the name already used in the repo**. On greenfield, default to **`modules/`** unless the user chooses otherwise.

---

# Feature Module Structure

Every feature must be isolated as a Nest module.

```text
modules/
└── users/
    ├── users.module.ts
    ├── users.controller.ts
    ├── users.service.ts
    ├── dto/
    │   ├── create-user.dto.ts
    │   ├── update-user.dto.ts
    │   └── query-users.dto.ts
    ├── entities/
    │   └── user.entity.ts
    └── interfaces/
        └── user.interface.ts
```

Rules:

* **`*.module.ts`** — imports, providers, controllers, exports public providers only
* **`*.controller.ts`** — routes, guards, Swagger decorators, delegates to service
* **`*.service.ts`** — business logic, transactions, calls repositories/other services
* **`dto/`** — request/response validation classes
* Export only what other modules need from `UsersModule` — hide internal providers

Example module:

```ts
@Module({
  imports: [TypeOrmModule.forFeature([User])],
  controllers: [UsersController],
  providers: [UsersService],
  exports: [UsersService],
})
export class UsersModule {}
```

Register feature modules in `AppModule` (or a domain import module) — do not register providers globally unless truly cross-cutting.

---

# Controller Rules

Controllers handle **HTTP only**:

* Route definitions (`@Get`, `@Post`, `@Patch`, `@Delete`)
* Guard and role decorators (`@UseGuards`, `@Roles`)
* Swagger metadata (`@ApiTags`, `@ApiOperation`, `@ApiResponse`)
* Parse params/query/body via DTOs and pipes
* Return standardized response shape (see **API Response Format**)
* **No** database queries, **no** business rules, **no** direct ORM calls

Preferred:

```ts
@Post()
create(@Body() dto: CreateUserDto): Promise<ApiResponse<UserResponseDto>> {
  return this.usersService.create(dto);
}
```

Forbidden in controllers:

* Raw `process.env` access
* Complex branching business logic
* Direct `Repository` / `PrismaClient` usage (belongs in service or repository layer)

---

# Service Rules

Services own **business logic**:

* Validate domain rules beyond DTO shape (uniqueness, state transitions, permissions)
* Coordinate repositories, other services, and external APIs
* Throw Nest HTTP exceptions (`NotFoundException`, `ConflictException`, …) or domain errors mapped by filters
* Use `@Injectable()` and constructor injection only — no manual `new Service()`
* One primary service per feature (`UsersService`); split into sub-services only when the file grows unwieldy

Never:

* Put HTTP-specific types (`Request`, `Response`) in services unless abstracted
* Bypass the module system with static imports of another feature’s private files

---

# DTO Rules

All incoming HTTP data must use DTO classes with validation.

Default stack:

* **class-validator** decorators on DTO properties
* **class-transformer** for `@Type`, `@Exclude`, `@Expose`
* Global **`ValidationPipe`** in `main.ts`:

```ts
app.useGlobalPipes(
  new ValidationPipe({
    whitelist: true,
    forbidNonWhitelisted: true,
    transform: true,
    transformOptions: { enableImplicitConversion: false },
  }),
);
```

Required DTO types per resource:

* **Create** — `CreateXDto`
* **Update** — `UpdateXDto` (often `PartialType(CreateXDto)` from `@nestjs/swagger`)
* **Query / list** — `QueryXDto` with pagination, search, sort, filters
* **Response** — `XResponseDto` when exposing entities (never return raw ORM entities with sensitive fields)

Example:

```ts
export class CreateUserDto {
  @IsEmail()
  email: string;

  @IsString()
  @MinLength(8)
  password: string;
}
```

If the project uses **Zod** instead of class-validator, follow the existing Zod pipe/schema pattern — do not mix both in the same module without reason.

---

# Validation Rules

Required validation surfaces:

* Request body, query, and params (DTOs + ValidationPipe)
* Environment variables (config schema on boot)
* Webhook payloads (dedicated DTOs per provider)

Never trust client input. Always whitelist DTO fields (`whitelist: true`).

---

# Authentication Rules

## JWT library — ask on greenfield auth

When adding or wiring **JWT auth** and the project has **no established token library**:

* **Ask the user** which approach to use:
  * **`@nestjs/jwt`** (default Nest stack) — integrates with Passport, familiar Nest patterns
  * **[jose](https://www.npmjs.com/package/jose)** — modern JOSE/JWT library (sign, verify, JWK, edge-friendly); use in a custom auth service/guard instead of `@nestjs/jwt`
* If the repo **already uses** one of these, **follow it** — do not introduce the other without approval.
* Do not install both `@nestjs/jwt` and `jose` for the same token flow unless explicitly requested.

When the user chooses **jose**:

* Centralize sign/verify in `common/auth/` or `modules/auth/` (e.g. `jwt.service.ts` using `jose`)
* Keep guards thin — validate in guard, business rules in auth service
* Still use Passport guards/strategies only if the user wants Passport; otherwise custom `JwtAuthGuard` calling `jose`

When the user chooses **`@nestjs/jwt`** (default):

* Use `@nestjs/passport`, `passport-jwt`, and `@nestjs/jwt` as usual
* Register `JwtModule` with config from validated env

## Default stack (when `@nestjs/jwt` is chosen or already in repo)

Use:

* Access token (short-lived)
* Refresh token (long-lived) with rotation when the product requires it
* `@UseGuards(JwtAuthGuard)` on protected routes
* Role/permission guards in `common/guards/` when RBAC is needed

Requirements:

* Validate JWT in a **guard** or auth service — not ad hoc in every controller method
* Never log tokens or passwords
* Hash passwords with **bcrypt** (or the algorithm already used in the repo)
* Store refresh token hashes server-side when using refresh rotation
* Document whether clients receive tokens in JSON body vs HttpOnly cookies — **ask** on greenfield

Authentication flow:

```text
Login
 ↓
Access Token Issued (+ Refresh Token if applicable)
 ↓
Access Token Expires
 ↓
Refresh Token Exchange
 ↓
New Access Token
```

---

# Authorization Rules

* Use guards for authentication and authorization — not inline checks scattered in controllers
* Prefer `@Roles()` / custom `@Permissions()` decorators + guard
* Fail closed — missing guard on sensitive routes is a bug
* Document public routes explicitly (`@Public()` decorator or allowlist in guard)

---

# Database Rules

**Ask** which ORM and database the project uses before writing persistence code.

## Migrations — ask to set up if missing

Before creating or changing entities/schema, check whether **migrations are configured**:

| ORM | Migrations present when… |
| --- | --- |
| **TypeORM** | `database/migrations/` (or configured migrations path) exists **and** `synchronize: false` in production config |
| **Prisma** | `prisma/migrations/` exists with at least an initial migration |

If **migrations are not set up** (empty/missing folder, only `synchronize: true`, or schema changes with no migration history):

1. **Ask the user** whether to set up migrations before proceeding.
2. Explain briefly: migrations are required for safe schema changes in production.
3. If the user **agrees**, scaffold the migration workflow for the chosen ORM (see below) before adding/changing entities.
4. If the user **declines**, do not silently enable `synchronize: true` for production — document the limitation and stop short of destructive schema assumptions.

**Do not** apply entity or Prisma schema changes that require DB updates until migrations are agreed and configured (or the repo already has a working migration flow).

### TypeORM migration setup (when user agrees)

* Set `synchronize: false` in production (and prefer false in dev once migrations exist)
* Add `database/data-source.ts` (or project’s existing TypeORM CLI config)
* Add npm scripts, e.g. `migration:generate`, `migration:run`, `migration:revert`
* Store migrations in `database/migrations/`
* Generate an initial migration from current entities if the DB already exists

### Prisma migration setup (when user agrees)

* Ensure `prisma/schema.prisma` and datasource are configured
* Run `prisma migrate dev` for local initial migration (document the command for the user)
* Commit `prisma/migrations/` — never rely on `db push` alone for production-bound projects unless the user explicitly chooses it

## TypeORM (when in stack)

* Entities in `modules/<feature>/entities/`
* Use repositories via `@InjectRepository` in services
* Migrations in `database/migrations/` — never rely on `synchronize: true` in production
* Relations defined on entities; avoid N+1 — use `relations` or QueryBuilder intentionally

## Prisma (when in stack)

* Schema in `prisma/schema.prisma`
* Inject `PrismaService` from a shared database module
* Use transactions for multi-step writes
* Run `prisma migrate` for schema changes — do not hand-edit production DB

## General

* No raw SQL in controllers
* Pagination at database level — not in-memory filtering of large lists
* Soft deletes only when the domain requires them — match existing pattern

---

# API Response Format

Success:

```json
{
  "success": true,
  "data": {}
}
```

Error:

```json
{
  "success": false,
  "message": "",
  "errors": []
}
```

Implement via:

* **`TransformInterceptor`** or response wrapper in `common/interceptors/`
* **`HttpExceptionFilter`** in `common/filters/` for consistent error bodies

Do not return ad-hoc shapes per controller unless the repo already standardizes differently — in that case **follow the repo**.

---

# Pagination & Query Rules

List endpoints must support server-side pagination and filtering via **query DTOs**:

```text
?page=1&limit=20&search=ali&sort=createdAt&order=desc&status=active
```

* Validate query params in `QueryXDto`
* Enforce sensible `limit` max (e.g. 100)
* Return pagination metadata in `data`:

```json
{
  "success": true,
  "data": {
    "items": [],
    "meta": { "page": 1, "limit": 20, "total": 100, "totalPages": 5 }
  }
}
```

---

# Swagger / OpenAPI Rules

When `@nestjs/swagger` is in stack:

* `@ApiTags()` on controllers
* `@ApiOperation()` on non-obvious routes
* `@ApiBearerAuth()` on protected routes
* Use `@ApiProperty()` on DTOs (or plugin if configured)
* Keep Swagger setup in `main.ts` or `swagger.config.ts`

Do not expose internal/admin endpoints in public Swagger without `@ApiExcludeController` or environment gating.

---

# Exception & Logging Rules

* Use Nest built-in HTTP exceptions in services: `NotFoundException`, `BadRequestException`, `ConflictException`, `UnauthorizedException`, `ForbiddenException`
* Map unknown errors in a global **`ExceptionFilter`** — do not leak stack traces in production
* Never use `console.log()` — use Nest **`Logger`** or the project’s logger (Pino, Winston)

```ts
private readonly logger = new Logger(UsersService.name);
this.logger.log('User created');
this.logger.error('Failed to create user', err.stack);
```

---

# Forbidden Patterns

Never:

* Put business logic in controllers
* Access `process.env` outside config module
* Return ORM entities with password/hash fields
* Skip DTO validation on HTTP inputs
* Register feature providers in `AppModule` providers array instead of the feature module
* Call `ModuleRef` or static singletons to bypass DI
* Use `any` for DTOs or service method signatures

Forbidden:

```ts
@Get()
findAll(@Req() req: Request) {
  return this.connection.query(`SELECT * FROM users WHERE id = ${req.query.id}`);
}
```

Preferred:

```ts
@Get()
findAll(@Query() query: QueryUsersDto) {
  return this.usersService.findAll(query);
}
```

---

# Guards, Interceptors, Pipes, Filters

| Type | Purpose | Location |
| --- | --- | --- |
| **Guard** | Auth, roles, throttling | `common/guards/` |
| **Interceptor** | Response transform, logging, timeout | `common/interceptors/` |
| **Pipe** | Param validation, parsing | `common/pipes/` or global ValidationPipe |
| **Filter** | Exception mapping | `common/filters/` |

Register global pipes/filters/interceptors in `main.ts` or `AppModule` — not per-controller unless scoped intentionally.

---

# Module Import Rules

* Feature modules import only what they need
* Shared module (`CommonModule`) exports cross-cutting providers — import once
* Avoid **circular imports** — use `forwardRef()` only when necessary and document why
* Cross-feature calls go through **exported services** of the other module — never import private DTOs/entities across features without a shared contract

---

# WebSocket & SSE Rules

Use **Gateway** classes for WebSockets:

```text
modules/
└── notifications/
    ├── notifications.gateway.ts
    └── notifications.module.ts
```

Use WebSockets for: chat, notifications, presence, collaborative editing, live dashboards.

Use **SSE** or streaming HTTP when one-way server → client is enough (AI streaming, job progress, export status).

**Ask** before adding Socket.io or ws adapter if not in stack.

---

# Queue & Background Jobs

When BullMQ / `@nestjs/bullmq` is in stack:

* Processors in `modules/<feature>/processors/`
* Enqueue from services — not controllers (unless fire-and-forget HTTP trigger)
* Idempotent job handlers where retries are possible

**Ask** before adding queue infrastructure.

---

# Testing Rules

## After completing a feature or command

When an agent or contributor **finishes implementing** a feature, endpoint, service, or other non-trivial change:

1. **Check** whether **unit tests already exist** for that scope (e.g. `users.service.spec.ts` next to `users.service.ts`, or the project’s equivalent `*.test.ts` / `*.spec.ts` for the same module, action, or utility).

### If unit tests already exist for that scope

* **Update or extend** the existing test file(s) to cover the new or changed behavior.
* Do **not** ask first — keeping tests in sync with code is expected when tests are already part of the project.
* Do **not** create duplicate test files for the same unit — edit the existing spec.

### If no unit tests exist for that scope

1. **Ask the user** whether they want unit tests written for that work.
2. **Do not** add tests automatically unless the user says yes.
3. **Do not** skip the question.

If the user **declines**, stop — no tests required for that task.

If the user **accepts**:

* Add tests only for the **completed scope**
* Use **Jest** (Nest default) unless the repo uses another runner
* If no test runner is configured yet, **ask before installing** (see **Dependency Rules**)

Example prompt when **no tests exist yet**:

> Implementation is complete. There are no unit tests for this yet. Do you want me to add them?

Example when **tests already exist** (no ask — proceed):

> Updating `users.service.spec.ts` to cover the new validation paths.

## What to test (priority)

1. Services (business logic)
2. Guards and auth flows
3. DTO validation (edge cases)
4. Controllers (e2e or integration with `TestingModule`)
5. Utilities and pipes

## Test file conventions

* `*.spec.ts` next to source (Nest CLI default) — match existing project pattern
* E2E tests in `test/` — `*.e2e-spec.ts`
* Match the project’s **file naming convention** for new test files

## Do not

* Write trivial tests that only assert the obvious
* Add tests for unchanged, unrelated code
* Ask to add tests when a spec file already exists for that unit — **update it instead**
* Block delivery unless the user asked for tests upfront (when none exist yet)

---

# Code Quality Rules

Every clone must include ESLint, Prettier, Husky, and lint-staged.

If any are missing, install and wire them before feature work.

## Scripts (typical)

```bash
pnpm lint              # ESLint check
pnpm lint:fix          # ESLint auto-fix
pnpm format            # Prettier write
pnpm format:check      # Prettier check (CI-friendly)
pnpm test              # Unit tests
pnpm test:e2e          # E2E tests
```

## Git hooks (Husky)

* **`prepare`** runs `husky` after install
* **`pre-commit`** runs `lint-staged` on staged files
* Do not skip hooks (`--no-verify`) unless explicitly requested

## Agent / contributor rules

* Run lint and format check before opening a PR when touching many files
* Fix lint issues in changed files — do not disable rules to bypass them
* Do not add competing formatters or duplicate pre-commit tools

---

# Dependency Rules

Before installing a package:

* Check existing dependencies first — reuse what the project already has
* Prefer Nest official packages (`@nestjs/*`)
* **Ask before adding new dependencies** (see **Not in stack — ask before adding**)
* Avoid duplicate libraries

## Package manager

**If the project is already initialized** — use the **same package manager** as the repo.

Detect from (in order):

1. `"packageManager"` field in `package.json`
2. Lockfile: `pnpm-lock.yaml` → pnpm, `package-lock.json` → npm, `yarn.lock` → yarn, `bun.lockb` → bun

**If greenfield** — **ask the user** which package manager they want.

## Installing new packages — use latest stable

When adding a **new** approved dependency:

```bash
pnpm add <package>@latest
pnpm add -D <package>@latest
```

* Keep `@nestjs/*` packages on aligned major versions
* Verify compatibility with Nest 11 and TypeScript strict before committing

## Do not

* Mix package managers or create a second lockfile
* Add outdated packages when a current stable release exists
* Install packages globally

---

# Naming Rules

## Detect and follow the project convention

Before creating **project-owned** files, folders, or types, determine what naming convention this repo already uses.

1. **Scan** `src/modules/` (or `src/features/`), `src/common/`, `src/config/`, DTOs, entities, and tests.
2. **Identify** the dominant pattern for **files and folders** — kebab-case, camelCase, PascalCase, snake_case, or other.
3. **Identify** the dominant pattern for **data types** — classes, interfaces, enums, DTO names.

### Existing / established projects

If the codebase already follows a clear convention:

* Use the **same file and folder casing** for all new project-owned paths.
* Use the **same data-type naming style** for new classes, interfaces, enums, and DTOs.
* Match the pattern in the **same module** when in doubt.
* Do **not** introduce a different casing style.

### Greenfield or inconsistent naming

If the project is new, mostly empty, or uses mixed casing with no clear pattern:

* **Ask the user** before creating project-owned files or types:
  * **Files and folders:** kebab-case, camelCase, PascalCase, snake_case, or other?
  * **Data types / classes:** PascalCase (Nest/TS default), camelCase, or other?
* Record the choice once (README or team convention) and apply consistently.
* Do **not** guess or silently pick a convention without asking.

**Does not apply to:**

* NestJS CLI-generated names you must keep for convention (`main.ts`, `app.module.ts`)
* `node_modules` and third-party packages
* Framework-required suffixes: `*.module.ts`, `*.controller.ts`, `*.service.ts`, `*.gateway.ts`, `*.spec.ts`

## Examples (Nest CLI default: kebab-case files)

If the user chooses **kebab-case** for project-owned files (Nest CLI default), typical paths:

```text
users.module.ts
users.controller.ts
users.service.ts
create-user.dto.ts
update-user.dto.ts
query-users.dto.ts
user.entity.ts
users.service.spec.ts
jwt-auth.guard.ts
http-exception.filter.ts
```

## Class and symbol naming (typical Nest — follow repo if different)

* Modules / controllers / services / gateways: **PascalCase** — `UsersModule`, `UsersController`, `UsersService`
* DTOs: **PascalCase** with suffix — `CreateUserDto`, `QueryUsersDto`
* Entities: **PascalCase** — `User`
* Methods and properties: **camelCase**
* Constants: **UPPER_SNAKE_CASE** or project convention

## Do not mix conventions

* Do not use a different file casing than the rest of the project (or the user’s chosen convention).
* Do not use a different class/DTO naming style than the rest of the project.

---

# AI Agent Rules

AI agents must:

* Follow existing architecture and module boundaries.
* Verify **required stack tooling** exists (ESLint, Prettier, Husky, lint-staged, README) — install if missing.
* **Ask before adding** anything listed under **Not in stack — ask before adding**.
* **Ask which ORM, database, and API style** apply before designing persistence or new transport layers.
* **Check for migrations** before entity/schema work — if missing, **ask the user** to set up migrations first (see **Database Rules**).
* On greenfield **JWT auth**, **ask** whether to use **`@nestjs/jwt`** or **[jose](https://www.npmjs.com/package/jose)** before installing either.
* Use the **project’s package manager** if initialized; if greenfield, **ask the user** which to use.
* When installing **new approved** dependencies, use **`@latest` stable** and verify Nest compatibility.
* **Inspect existing file and data-type naming** before creating project-owned paths or types; follow the repo’s convention when one exists.
* On greenfield or inconsistent repos, **ask the user** for file/folder and data-type casing before adding files.
* Keep controllers thin and logic in services.
* Validate all HTTP input with DTOs and ValidationPipe.
* **After completing a feature or command**, follow **Testing Rules**: **update existing unit tests** when a spec already exists for that scope; **ask the user** only when no unit tests exist yet.

AI agents must never:

* Put business logic in controllers.
* Access `process.env` outside the config module.
* Return raw entities with sensitive fields.
* Skip DTO validation.
* Add dependencies without approval.
* Enable `synchronize: true` in production or apply schema changes without migrations when none exist — **ask to set up migrations first**.
* Install `@nestjs/jwt` and `jose` for the same auth flow without user approval.
* Introduce a second ORM or competing architecture.
* Introduce a **new** file, folder, or type casing style that conflicts with the established convention (or the user’s chosen convention).
* Skip asking when **no unit tests exist** for the completed scope (unless the user already requested tests upfront).
* Create a duplicate test file when a spec already exists for the same unit — update the existing file.
* Run a different package manager than the one the repo uses.

When uncertain:

* Follow current project patterns.
* **Ask** before major changes — especially ORM/database choice, **migrations setup**, **JWT library (`@nestjs/jwt` vs jose)**, auth model, queue/cache addition, package manager (greenfield), file/data-type naming (greenfield or inconsistent repos), and new dependencies.
* Prioritize maintainability and consistency.
