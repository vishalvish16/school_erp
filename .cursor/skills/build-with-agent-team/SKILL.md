---
name: build-with-agent-team
description: Build a project using Claude Code Agent Teams with tmux split panes. Takes a plan document path and optional team size. Use when you want multiple agents collaborating on a build.
argument-hint: [plan-path] [num-agents]
disable-model-invocation: true
---

# Build with Agent Team

You are coordinating a build using Claude Code Agent Teams. Read the plan document, determine the right team structure, spawn teammates, and orchestrate the build.

## Arguments

- **Plan path**: `$ARGUMENTS[0]` - Path to a markdown file describing what to build
- **Team size**: `$ARGUMENTS[1]` - Number of agents (optional)

## Step 1: Read the Plan

Read the plan document at `$ARGUMENTS[0]`. Understand:
- What are we building?
- What are the major components/layers?
- What technologies are involved?
- What are the dependencies between components?

## Step 2: Determine Team Structure

If team size is specified (`$ARGUMENTS[1]`), use that number of agents.

If NOT specified, analyze the plan and determine the optimal team size based on:
- **Number of independent components** (frontend, backend, database, infra, etc.)
- **Technology boundaries** (different languages/frameworks = different agents)
- **Parallelization potential** (what can be built simultaneously?)

**Guidelines:**
- 2 agents: Simple projects with clear frontend/backend split
- 3 agents: Full-stack apps (frontend, backend, database/infra)
- 4 agents: Complex systems with additional concerns (testing, DevOps, docs)
- 5+ agents: Large systems with many independent modules

For each agent, define:
1. **Name**: Short, descriptive (e.g., "frontend", "backend", "database")
2. **Ownership**: What files/directories they own exclusively
3. **Does NOT touch**: What's off-limits (prevents conflicts)
4. **Key responsibilities**: What they're building

## Step 3: Set Up Agent Team

Enable tmux split panes so each agent is visible:

```
teammateMode: "tmux"
```

## Step 4: Define Contracts

Before spawning agents, the lead reads the plan and defines the integration contracts between layers. This focused upfront work is what enables all agents to spawn in parallel without diverging on interfaces. Agents that build in parallel will diverge on endpoint URLs, response shapes, trailing slashes, and data storage semantics unless they start with agreed-upon contracts.

### Map the Contract Chain

Identify which layers need to agree on interfaces:

```
Database → function signatures, data shapes → Backend
Backend → API contract (URLs, response shapes, SSE format) → Frontend
```

### Author the Contracts

From the plan, define each integration contract with enough specificity that agents can build to it independently:

**Database → Backend contract:**
- Function signatures (create, read, update, delete)
- Pydantic model definitions
- Data shapes and types

**Backend → Frontend contract:**
- Exact endpoint URLs (including trailing slash conventions)
- Request/response JSON shapes (exact structures, not prose descriptions)
- Status codes for success and error cases
- SSE event types with exact JSON format
- Response envelopes (flat vs nested — e.g., `{"session": {...}, "messages": [...]}`)

### Identify Cross-Cutting Concerns

Some behaviors span multiple agents and will fall through the cracks unless explicitly assigned. Identify these from the plan and assign ownership to one agent:

Common cross-cutting concerns:
- **Streaming data storage**: If backend streams chunks to frontend, should chunks be stored individually in the DB or accumulated into one row? (Affects how frontend renders on reload)
- **URL conventions**: Trailing slashes, path parameters, query params — both sides must match exactly
- **Response envelopes**: Flat objects vs nested wrappers — both sides must agree
- **Error shapes**: How errors are returned (status codes, error body format)
- **UI accessibility**: Interactive elements need aria-labels for automated testing

Assign each concern to one agent with instructions to coordinate with others.

### Contract Quality Checklist

Before including a contract in agent prompts, verify:
- Are URLs exact, including trailing slashes? (e.g., `POST /api/sessions/` vs `POST /api/sessions`)
- Are response shapes explicit JSON, not prose descriptions? (e.g., `{"session": {...}, "messages": [...]}` not "returns session with messages")
- Are all SSE event types documented with exact JSON?
- Are error responses specified? (404 body, 422 body, etc.)
- Are storage semantics clear? (accumulated vs per-chunk)

## Step 5: Spawn All Agents in Parallel

With contracts defined, spawn all agents simultaneously. Each agent receives the full context they need to build independently from the start. This is the whole point of agent teams — parallel work across boundaries.

Enter **Delegate Mode** (Shift+Tab) before spawning. You should not implement code yourself — your role is coordination.

### Spawn Prompt Structure

```
You are the [ROLE] agent for this build.

## Your Ownership
- You own: [directories/files]
- Do NOT touch: [other agents' files]

## What You're Building
[Relevant section from plan]

## Contracts

### Contract You Produce
[Include the lead-authored contract this agent is responsible for]
- Build to match this exactly
- If you need to deviate, message the lead and wait for approval before changing

### Contract You Consume
[Include the lead-authored contract this agent depends on]
- Build against this interface exactly — do not guess or deviate

### Cross-Cutting Concerns You Own
[Explicitly list integration behaviors this agent is responsible for]

## Coordination
- Message the lead if you discover something that affects a contract
- Ask before deviating from any agreed contract
- Flag cross-cutting concerns that weren't anticipated
- Share with [other agent] when: [trigger]
- Challenge [other agent]'s work on: [integration point]

## Before Reporting Done
Run these validations and fix any failures:
1. [specific validation command]
2. [specific validation command]
Do NOT report done until all validations pass.
```

## Step 6: Facilitate Collaboration

All agents are working in parallel. Your job as lead is to keep them aligned and unblock them.

### During Implementation

- Relay messages between agents when they flag contract issues
- If an agent needs to deviate from a contract, evaluate the change, update the contract, and notify all affected agents
- Unblock agents waiting on decisions
- Track progress through the shared task list

### Pre-Completion Contract Verification

Before any agent reports "done", run a contract diff:
- "Backend: what exact curl commands test each endpoint?"
- "Frontend: what exact fetch URLs are you calling with what request bodies?"
- Compare and flag mismatches before integration testing

### Cross-Review
Each agent reviews another's work:
- Frontend reviews Backend API usability
- Backend reviews Database query patterns
- Database reviews Frontend data access patterns

## Collaboration Patterns

**Anti-pattern: Parallel spawn without contracts** (agents diverge)
```
Lead spawns all 3 agents simultaneously without defining interfaces
Each agent builds to their own assumptions
Integration fails on URL mismatches, response shape mismatches ❌
```

**Anti-pattern: Fully sequential spawning** (defeats purpose of agent teams)
```
Lead spawns database agent → waits for contract → spawns backend → waits → spawns frontend
Only one agent works at a time, no parallelism ❌
```

**Anti-pattern: "Tell them to talk"** (they won't reliably)
```
Lead tells backend "share your contract with frontend"
Backend sends contract but frontend already built half the app ❌
```

**Good pattern: Lead-authored contracts, parallel spawn**
```
Lead reads plan → defines all contracts upfront → spawns all agents in parallel with contracts included
All agents build simultaneously to agreed interfaces → minimal integration mismatches ✅
```

**Good pattern: Active collaboration during parallel work**
```
Agent A: "I need to add a field to the response — messaging the lead"
Lead: "Approved. Agent B, the response now includes 'metadata'. Update your fetch."
Agent B: "Got it, updating now"
```

## Task Management

Create a shared task list. Since contracts are defined upfront, agents can start building immediately — no inter-agent blocking for initial implementation work. Only block tasks that genuinely require another agent's output (like integration testing).

```
[ ] Agent A: Build UI components
[ ] Agent B: Implement API endpoints
[ ] Agent C: Build schema and data layer
[ ] Agent A + B + C: Integration testing (blocked by all implementation tasks)
```

Track progress and facilitate communication when agents need to coordinate.

## Common Pitfalls to Prevent

1. **File conflicts**: Two agents editing the same file → Assign clear ownership
2. **Lead over-implementing**: You start coding → Stay in Delegate Mode
3. **Isolated work**: Agents don't talk → Require explicit handoffs via lead relay
4. **Vague boundaries**: "Help with backend" → Specify exact files/responsibilities
5. **Missing dependencies**: Agent B waits on Agent A forever → Track blockers actively
6. **Parallel spawn without contracts**: All agents start simultaneously with no shared interfaces → Integration failures. Define contracts before spawning
7. **Implicit contracts**: "The API returns sessions" → Ambiguous. Require exact JSON shapes, URLs with trailing slashes, status codes
8. **Orphaned cross-cutting concerns**: Streaming storage, URL conventions, error shapes → Nobody owns them. Explicitly assign to one agent
9. **Per-chunk storage**: Backend stores each streamed text chunk as a separate DB row → Frontend renders N bubbles on reload. Accumulate chunks into single rows
10. **Hidden UI elements**: CSS `opacity-0` on interactive elements → Invisible to automation. Add aria-labels, ensure keyboard/focus visibility

## List screens & mobile cards (Flutter — this repo)

When the build or review touches **list / table screens** under `lib/features/**` (schools, staff, billing, super admin lists, etc.):

1. **Read** the Cursor rule **`.cursor/rules/list-screen-ui-patterns.mdc`** (search + filters, mobile card structure, pagination, breakpoints, metric KPI tiles). It is the single source of truth for list UI in this ERP.
1b. **Super Admin** (`lib/features/super_admin/**`): enforce the **“Super Admin module”** section in that rule on **all** screens in the folder (not only one list page).
2. **Reference implementation** for mobile list cards: `_buildMobileCard` in `lib/features/super_admin/presentation/screens/super_admin_schools_screen.dart`; aligned example: `lib/features/schools/presentation/views/schools_screen.dart`.
3. **Before spawning the frontend agent**, paste into their prompt the **“Code review checklist (mobile list cards)”** section from that rule (or instruct them to read the file and confirm each item).
4. **On code review**, reject work that reintroduces anti-patterns called out in the rule: e.g. **`kIsWeb`**-only desktop layout, bottom **row of `IconButton`s** on mobile instead of **⋮**, duplicate primary action in menu when **card tap** already navigates, missing **Divider**/chip zone for plan+status, unbounded lists without pagination.

### Lead checklist (quick)

- [ ] Wide vs narrow uses **`AppBreakpoints.tablet`** (not `kIsWeb`).
- [ ] Mobile uses **`MobileInfiniteScrollList`** + **`HoverPopupMenu`** for row actions where applicable.
- [ ] Entity counts and labels match backend domain (e.g. `Student`/`Staff` vs user roles).

### Search & filter row (list screens)

When the plan includes **search**, **status/plan dropdowns**, or a **Filters** control:

1. Follow **`## Search + Filters`** in **`.cursor/rules/list-screen-ui-patterns.mdc`** — **`SearchableDropdownFormField`** (`lib/widgets/common/searchable_dropdown_form_field.dart`), not raw **`DropdownButton`** for searchable / multi-option filters.
2. **`< AppBreakpoints.formMaxWidth` (600px):** dropdown options open in a **modal bottom sheet** by default; use **`useBottomSheet: true`** only when forcing that on wide layouts.
3. **Mobile filter strip (canonical — plans do not need to re-describe this):** For **narrow** list layouts, use **`lib/shared/widgets/list_screen_mobile_toolbar.dart`**: **`ListScreenMobileFilterStrip`** (tinted strip) → **`ListScreenMobilePillSearchField`** (full-width pill, search icon) → **`ListScreenMobileFilterRow`** (equal **`Expanded`** slots, 8px gap) with **`SearchableDropdownFormField`** + **`listScreenMobileFilterFieldDecoration`**, and **`ListScreenMobileMoreFiltersButton`** (**`Icons.tune`** + “Filters” + chevron → **`showModalBottomSheet`** for overflow filters). **Reference:** `_buildMobileSearchFilters` in **`super_admin_schools_screen.dart`**. Do not substitute a generic `Card` + `Wrap` unless it matches this strip visually.
4. **Wide:** filter **Card** with `Wrap` (search ~220px, filters ~140px) per the rule file.
5. On code review, use the **“Code review checklist (search + filters)”** in that rule file.

### Metric / KPI tiles (dashboards, billing, summary strips)

When the plan includes **stats cards**, **MRR/ARR**, or **KPI rows** on mobile:

1. Use **`MetricStatCard`** (`lib/shared/widgets/metric_stat_card.dart`) — same pattern as **Super Admin → Billing** (`_buildBillingStats` in `super_admin_billing_screen.dart`): white card, tinted rounded icon box, bold value, single-line label (`maxLines: 1`).
2. **`< 600px` width:** horizontal **`ListView`** of fixed-width tiles (`~148px`), not a 2×2 grid of cramped cards. **`≥ 600px`:** `Row` of `Expanded` cards.
3. Enforce the **”Metric / KPI stat cards”** and **”Code review checklist (metric cards)”** sections in **`list-screen-ui-patterns.mdc`**.

### Toast / feedback notifications

For **user-facing notifications** (save success, API errors, warnings) in Flutter screens:

1. Use **`AppToast`** (`lib/shared/widgets/app_toast.dart`) — centered top-of-screen overlay with slide-in animation and typed accent strip (success / error / warning / info).
2. **Do NOT** call `ScaffoldMessenger.showSnackBar` directly on new screens — renders at bottom-left and is easy to miss.
3. API: `AppToast.showSuccess(context, msg)` / `.showError` / `.showWarning` / `.showInfo`.
4. **`AppFeedback`** remains the API for confirmation dialogs, loading overlays, and status chips — do not replace those.

### Table row alternating colors (AppThemeTokens)

All table widgets must read **`AppThemeTokens`** for row colors so Super Admin theme settings take effect immediately:

- `t?.tableRowEvenBg` / `t?.tableRowOddBg` — alternating row backgrounds
- `t?.tableHoverBg` — hover / selected state
- Read via `Theme.of(context).extension<AppThemeTokens>()`
- Reference: `lib/shared/widgets/list_table_view.dart` (`_buildDataRow`) and `lib/shared/widgets/reusable_data_table.dart` (`themedRows` generator)
- **Never** leave non-selected row color as `null` — always resolve from tokens.

### Compact mobile list cards (billing / subscription-style screens)

For screens that show **dense lists of entities** (billing, subscriptions, any module where cards would feel heavy):

1. **Card = single tappable tile** (~60–70px tall). Wrap the card's `child` in `InkWell(onTap: () => _showDetailSheet(item))` with `clipBehavior: Clip.hardEdge` on the `Card` so the ripple stays inside the border radius.
2. **Two-line layout only:**
   - **Row 1:** entity name (`fontSize: 14, fontWeight: w600`, `maxLines: 1, overflow: ellipsis`) + status badge (small `Container` pill, `fontSize: 10, fontWeight: w700`).
   - **Row 2:** metadata joined with ` · ` separators (`fontSize: 12`, `color: onSurfaceVariant`), e.g. `Plan · ₹99/mo · 22 Mar 26`.
3. **No bottom button row.** Remove `Manage` / `View` / `Edit` buttons — the card tap is the primary action; `PopupMenuButton` (`Icons.more_vert`, `size: 18`) handles mutating actions.
4. **Card margin:** `const EdgeInsets.only(bottom: 8)` (was 12 on large cards).
5. **Reference implementation:** `_buildMobileCard` in `lib/features/super_admin/presentation/screens/super_admin_billing_screen.dart`.

**Anti-pattern to reject:**
```dart
// ❌ Large card with big headlineSmall price + icon rows + two full-width bottom buttons
Text('₹99', style: textTheme.headlineSmall)
Row([OutlinedButton('Manage'), FilledButton('View')])

// ✅ Compact tappable tile — card tap = detail, ⋮ menu = actions
InkWell(onTap: () => _showDetailSheet(s), child: Padding(…two-line layout…))
PopupMenuButton(icon: Icon(Icons.more_vert, size: 18), …)
```

### Design system imports — always explicit

**`AppColors`** is NOT automatically available just because `design_system.dart` is imported. Always add the explicit import wherever `AppColors` is used:

```dart
// ✅ Always add this alongside any other design_system import
import 'package:school_erp_admin/design_system/tokens/app_colors.dart';

// ❌ Don't assume app_colors is re-exported — it causes "isn't defined" compile errors
import 'package:school_erp_admin/design_system/tokens/app_spacing.dart'; // alone is not enough
```

This applies to every file that calls `AppColors.success500`, `AppColors.error500`, `AppColors.warning500`, etc.

### Mobile dialogs / bottom sheets with TabBar

When `showAdaptiveModal` is used for a dialog that contains a drag handle or TabBar:

1. **SafeArea**: The helper uses `SafeArea(top: false, ...)` so drag handles at the top of the content are not obscured. Keep this — do not change to `SafeArea(top: true)`.
2. **TabBar with 4+ tabs on mobile (`< 600px`)**: Use `isScrollable: false` with **icon-only** tabs; add `Tooltip(message: 'Label', child: Tab(icon: ...))` for each. On desktop use `isScrollable: true` with icon + text.
3. Detect: `final isMobile = MediaQuery.sizeOf(context).width < 600;`

### Theme preview screens (ConsumerWidget — not props)

Any widget that renders a **live theme preview** must be a `ConsumerWidget` watching the theme provider directly — not a `StatelessWidget` receiving tokens as props. `TabBarView`'s `PageView` skips rebuilds for off-screen tabs, so prop-passing silently breaks live updates. Use a stable `ValueKey` per tab child.

## Portal UI Consistency (ALL 8 Portals — MANDATORY)

> **One design system. Eight portals. Zero exceptions.**
> Every portal — Super Admin, Group Admin, School Admin, Staff, Teacher, Parent, Student, Driver — renders the **same Vidyron glassmorphism identity** and uses the **same shared widgets**. Agents building ANY portal must enforce every rule below.

| Portal | Feature folder | Shell reference |
|--------|---------------|-----------------|
| Super Admin | `lib/features/super_admin/` | `super_admin_shell.dart` |
| Group Admin | `lib/features/group_admin/` | `group_admin_shell.dart` |
| School Admin | `lib/features/school_admin/` | `school_admin_shell.dart` |
| Staff/Clerk | `lib/features/staff/` | `staff_shell.dart` |
| Teacher | `lib/features/teacher/` | `teacher_shell.dart` |
| Parent | `lib/features/parent/` | `parent_shell.dart` |
| Student | `lib/features/student/` | `student_shell.dart` |
| Driver | `lib/features/driver/` | `driver_shell.dart` |

### Rules enforced in every portal — with exact code references

**1. Shell layout** — Every `{portal}_shell.dart` copies `super_admin_shell.dart` skeleton:
- Wide: `AnimatedContainer(72/214) > ClipRect > BackdropFilter(sigmaX:24) > Container(glass)` sidebar + `ClipRect > BackdropFilter > Container(height:60)` topbar
- Narrow: `AppBar` + `BottomNavigationBar(fixed, last item = More → openDrawer)` + `Drawer(transparent) > ClipRect > BackdropFilter(sigmaX:28) > Container(glass)`
- `_NavItem`: active bg from `t?.navItemActiveBg` + 3px left bar `t?.navItemActiveIcon` + LayoutBuilder collapse (`< 100` = icon only + Tooltip)
- `_NavGroup`: section label `fontSize:10, w700, letterSpacing:1.2`, collapsible chevron

**2. List screens** — every portal list screen follows `super_admin_schools_screen.dart`:
- Mobile (`< 600px`): `ListScreenMobileFilterStrip > Column([ListScreenMobilePillSearchField, ListScreenMobileFilterRow([SearchableDropdownFormField×N, ListScreenMobileMoreFiltersButton])])`
- Wide (`≥ 600px`): `Card > Padding > Wrap > [SizedBox(220) TextField, SizedBox(140) SearchableDropdownFormField×N, TextButton clear]`
- State: `_loading`, `_loadingMore`, `_error`, `_items`, `_page=1`, `_totalPages=1`, `_total=0`, `_pageSize=15`, `_pageSizeOptions=[10,15,25,50]`, search debounce `400ms`

**3. Mobile cards** (`_buildMobileCard` pattern):
```
Card(margin:bottom:8) > InkWell(onTap:detail, borderRadius:brLg) > Padding(paddingLg) > Column([
  Row(Expanded(Text name w600/16) + HoverPopupMenu(more_vert/22, omitManage:true)),
  SizedBox(4), Text(subtitle smallMuted),
  Padding(v:10) Divider(outlineVariant.0.5),
  Row(Expanded leftCol[location?, ID, stats] + SizedBox(8) + Column rightCol[Wrap chips, SizedBox(8), date]),
])
```
Status chip colors: `AppColors.success500.0.20` active · `AppColors.error500.0.20` suspended · `AppColors.warning500.0.20` expiring · `AppColors.secondary500.0.20` trial.

**4. Desktop table**: `Center > ConstrainedBox(maxWidth) > Card > Column([Expanded(ListTableView(showSrNo:false)), ListPaginationBar])` — pagination inside same Card.

**5. Mobile list**: `MobileInfiniteScrollList(itemCount, itemBuilder, hasMore, isLoadingMore, onLoadMore)` — no `ListPaginationBar` on mobile.

**6. Dashboard KPIs**: `_buildStatsRow()` — `width >= 600` → `Row(Expanded MetricStatCard×N, SizedBox(12) gaps)` / `< 600` → `SizedBox(height:118) > ListView.separated(horizontal, SizedBox(width:148) MetricStatCard(compact:true))`.

**7. Toasts**: `AppToast.showSuccess/Error/Warning/Info(context, msg)`. `showSnackBar` forbidden.

**8. Table row colors**: `t?.tableRowEvenBg` / `t?.tableRowOddBg` from `AppThemeTokens`. Never `null` or hardcoded.

**9. Dialogs**: `showAdaptiveModal(context, widget, maxWidth: ...)`. Never `showModalBottomSheet` with opaque container (secondary filters sheet uses `showModalBottomSheet` with glass-shaped container — that is the only exception).

**10. Strings / breakpoints**: All text from `AppStrings`. Wide/narrow uses `MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet` (768). Never `kIsWeb`.

### Prompt instruction — include for every Flutter agent spawn

When spawning the Flutter agent for ANY portal module, include this in their prompt:

> "You are building the **[PORTAL NAME]** portal. Read RULE 5 (Glassmorphism), RULE 6 (All Portals), and RULE 7 (Shell Layout) in `.claude/agents/erp-flutter-dev.md`. Also read `.cursor/rules/list-screen-ui-patterns.mdc` completely. Copy `lib/features/super_admin/presentation/super_admin_shell.dart` as the shell skeleton and `lib/features/super_admin/presentation/screens/super_admin_schools_screen.dart` as the list screen skeleton. Every screen you produce must be visually identical in design-system usage to the Super Admin portal."

### Cross-portal code review checklist

When reviewing ANY portal screen, fail on:

- [ ] Shell: non-glass sidebar or topbar (missing `BackdropFilter`) → **reject**
- [ ] Shell: `_NavItem` missing active indicator bar or using hardcoded colors → **reject**
- [ ] Shell: mobile `Drawer` not transparent + BackdropFilter → **reject**
- [ ] List: mobile filter uses plain `TextField` or `Card` instead of `ListScreenMobileFilterStrip` → **reject**
- [ ] List: mobile card has bottom `IconButton` rows instead of `HoverPopupMenu` → **reject**
- [ ] List: status chip uses hardcoded `Color(0xFF...)` instead of `AppColors.*500.withValues(0.20)` → **reject**
- [ ] List: `ListPaginationBar` shown on mobile instead of `MobileInfiniteScrollList` → **reject**
- [ ] Dashboard: KPI tiles use raw `Icon + Text` instead of `MetricStatCard` → **reject**
- [ ] Any portal: `showSnackBar` used on new screens → **reject**
- [ ] Any portal: `kIsWeb` used for breakpoint → **reject**

## Definition of Done

The build is complete when:
1. All agents report their work is done
2. Each agent has validated their own domain
3. Integration points have been tested
4. Cross-review feedback has been addressed
5. The plan's acceptance criteria are met
6. **Lead agent has run end-to-end validation**

---

## Step 7: Validation

Validation happens at two levels: **agent-level** (each agent validates their domain) and **lead-level** (you validate the integrated system).

### Agent Validation

Before any agent reports "done", they must validate their work. When analyzing the plan, identify what validation each agent should run:

**Database agent** validates:
- Schema creates without errors
- CRUD operations work (create, read, update, delete)
- Foreign keys and cascades behave correctly
- Indexes exist for common queries

**Backend agent** validates:
- Server starts without errors
- All API endpoints respond correctly
- Request/response formats match the spec
- Error cases return proper status codes
- SSE streaming works (if applicable)

**Frontend agent** validates:
- TypeScript compiles (`tsc --noEmit`)
- Build succeeds (`npm run build`)
- Dev server starts
- Components render without console errors

When spawning agents, include their validation checklist:

```
## Before Reporting Done

Run these validations and fix any failures:
1. [specific validation command]
2. [specific validation command]
3. [manual check if needed]

Do NOT report done until all validations pass.
```

### Lead Validation (End-to-End)

After ALL agents return control to you, run end-to-end validation yourself. This catches integration issues that individual agents can't see.

**Your validation checklist:**

1. **Can the system start?**
   - Start all services (database, backend, frontend)
   - No startup errors

2. **Does the happy path work?**
   - Walk through the primary user flow
   - Each step produces expected results

3. **Do integrations connect?**
   - Frontend successfully calls backend
   - Backend successfully queries database
   - Data flows correctly through all layers

4. **Are edge cases handled?**
   - Empty states render correctly
   - Error states display user-friendly messages
   - Loading states appear during async operations

If validation fails:
- Identify which agent's domain contains the bug
- Re-spawn that agent with the specific issue
- Re-run validation after fix

### Validation in the Plan

Good plans include a **Validation** section with specific commands for each layer. When reading the plan:

1. Look for a Validation section
2. If present, use those exact commands when instructing agents
3. If absent, derive validation steps from the Acceptance Criteria

Example plan validation section:
```markdown
## Validation

### Database Validation
[specific commands to test schema and queries]

### Backend Validation
[specific commands to test API endpoints]

### Frontend Validation
[specific commands to test build and UI]

### End-to-End Validation
[full flow to run after integration]
```

---

## Execute

Now read the plan at `$ARGUMENTS[0]` and begin:

1. Read and understand the plan
2. Determine team size (use `$ARGUMENTS[1]` if provided, otherwise decide)
3. Define agent roles, ownership, cross-cutting concern assignments, and validation requirements
4. Map the contract chain and define all integration contracts from the plan — exact URLs, response shapes, data models, SSE formats
5. Enter Delegate Mode (Shift+Tab)
6. Spawn all agents in parallel with contracts and validation checklists included in their prompts
7. Monitor agents, relay messages, mediate contract deviations
8. Run contract diff before integration — compare backend's curl commands vs frontend's fetch URLs
9. When all agents return, run end-to-end validation yourself (start services, use agent-browser for UI testing)
10. If validation fails, re-spawn the relevant agent with the specific issue
11. Confirm the build meets the plan's requirements
