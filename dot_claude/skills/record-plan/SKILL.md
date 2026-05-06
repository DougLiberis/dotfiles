---
name: record-plan
description: Record an implementation plan, design doc, or investigation writeup as a new entry in the user's Notion "Claude Planning Log" database. Use when the user asks to "log this plan", "save this to Notion", "record this in the planning log", or wants the current plan/design persisted.
argument-hint: "[plan-title-or-database-name-override]"
disable-model-invocation: true
allowed-tools:
  - "mcp__claude_ai_Notion__notion-search"
  - "mcp__claude_ai_Notion__notion-fetch"
  - "mcp__claude_ai_Notion__notion-create-pages"
  - "mcp__claude_ai_Notion__notion-query-data-sources"
  - "Bash(git remote:*)"
  - "Bash(git rev-parse:*)"
  - "Bash(basename:*)"
  - "Bash(pwd)"
---

# Record Plan to Notion

Persist a plan, design doc, or investigation writeup from the current conversation as a new page in the user's Notion planning database. Default target database is **"Claude Planning Log"**. The user may pass a different name via `$ARGUMENTS`.

## Input

`$ARGUMENTS` is optional. If non-empty, treat it as either:

- A **page title** (use it for the new entry's `Title` property), or
- A **database name override** if it looks like a database name (e.g. ends in "Log", "Journal", "Database") and the user said something like "use the X log".

When ambiguous, ask the user briefly which they meant.

If empty, derive the title from the plan content (first H1, or a concise summary of the topic).

## Step 1 — Resolve the target database

Search Notion for the database:

```
mcp__claude_ai_Notion__notion-search
  query: "<database-name>"   # default: "Claude Planning Log"
  query_type: internal
  filters: {}
  page_size: 5
```

From the results, find the entry whose `metadata.type` is `database` and whose title matches. Fetch it to get the data source id:

```
mcp__claude_ai_Notion__notion-fetch
  id: <database-url-or-id>
```

The fetch result lists `<data-sources>` with one or more `<data-source url="collection://<id>">` entries. Extract the `<id>` portion — this is the `data_source_id` you'll pass to `notion-create-pages`.

If the database has multiple data sources, pick the one whose title matches the database name (or ask the user). Single-source databases (the common case) — use the only one.

**Cache the schema** from this fetch result. The `<data-source-state>` block contains the property definitions and their allowed values — you need these for Step 3.

## Step 2 — Determine plan content

The "plan" is whatever planning material the user has produced or asked you to record. This is typically:

- An implementation plan you just produced (multi-phase strategy)
- A design doc / architecture rationale
- An investigation writeup (root cause analysis)
- Documentation of a tool, skill, or process

Format it as **Notion-flavored Markdown** for the page body. Preserve:

- Heading structure (`##`, `###`)
- Code blocks with language hints (` ```c# `, ` ```bash `, etc.)
- Tables (use the `<table header-row="true">` HTML form Notion supports — see the existing `BCA Migration — Cohort 2` entry as a reference)
- Linear / Notion / GitHub URLs as inline links
- Lists, blockquotes, callouts

Do **not** include the page title at the top of the content — it goes in the `Title` property.

If the plan has not yet been written down in the conversation, ask the user to either paste it or point you to where it lives. Don't fabricate plan content.

## Step 3 — Resolve properties

Read the schema you fetched in Step 1 and fill these properties. Defaults shown were derived from the user's existing entries.

| Property | Type | Default | How to resolve |
|---|---|---|---|
| `Title` | title | — | From `$ARGUMENTS` or first H1 of plan; otherwise summarise. **Required.** |
| `Status` | select | `Draft` | `Draft` for new plans not yet acted on; `Approved` after the user has signed off; `Implemented` for retrospective documentation of completed work; `Superseded` / `Archived` only when explicitly requested. |
| `Reference` | text | repo name | Run `git remote get-url origin` in the working dir; parse the repo name (e.g. `LiberisFinance/merchant-graph-services` → `merchant-graph-services`). If not a git repo, use `basename "$(pwd)"`. The schema description says "Repository name (for git repos) or top-level folder name (for non-git repos). Plain text identifier — not a filesystem path." |
| `Project` | select | first option | Read available options from the schema. If only one option exists, use it. If multiple exist, pick the one matching the repo / domain the plan touches; ask if unclear. |
| `Tags` | multi-select | inferred | Pick from the schema's allowed options based on plan content. See guidance below. Pass as a JSON array string, e.g. `"[\"architecture\",\"planning\"]"`. |

### Tag inference

Map plan content to tags from the schema. Common cases (against the current schema's options):

- Multi-phase implementation strategy with rationale → `architecture`, `planning`
- Migration / cohort / cutover plan → `migration` (often + `architecture`, `planning`)
- Code-shape change without behaviour change → `refactor`
- Root-cause analysis, debugging diagnostic, log walkthrough → `investigation`
- Time-boxed exploration / prototype → `spike`
- Documentation of a tool or skill (no code change planned) → `investigation`

Pick **1–3 tags**. Don't add tags whose option name doesn't appear in the schema — Notion will reject them.

### Icon

Choose an emoji that matches the plan's character. Examples from existing entries:

- 🔶 — strategy / migration plan
- 🩺 — diagnostic / investigation tool
- 🏗️ — architecture proposal
- 🔧 — refactor
- 🧪 — spike / experiment
- 📋 — generic plan

Pass via the `icon` field on the page.

## Step 4 — Preview and confirm

Before calling `notion-create-pages`, show the user a short preview:

```
About to create:
  Database: Claude Planning Log
  Title:    <title>
  Status:   <status>
  Project:  <project>
  Reference:<reference>
  Tags:     [<tag>, <tag>]
  Icon:     <emoji>
  Body:     <N> lines, <M> headings, <K> code blocks
```

Ask: *"Post this to Notion? (y / edit / cancel)"*

- `y` → proceed to Step 5
- `edit` → take corrections (e.g. "change tags to architecture+refactor", "title should be Y") and re-preview
- `cancel` → abort

**Skip the confirmation only** if the user has already explicitly said "post it" / "save it now" in the same turn that triggered the skill.

## Step 5 — Create the page

```
mcp__claude_ai_Notion__notion-create-pages
  parent: { type: data_source_id, data_source_id: "<id-from-step-1>" }
  pages: [{
    icon: "<emoji>",
    properties: {
      Title: "<title>",
      Status: "<status>",
      Reference: "<reference>",
      Project: "<project>",
      Tags: "[<json-array-of-tag-strings>]"
    },
    content: "<plan-body-as-notion-markdown>"
  }]
```

The tool returns `{ pages: [{ url, id, properties }] }`. Capture the `url`.

## Step 6 — Report back

Reply with one line:

```
Logged: <title> → <notion-url>
```

If the user asked you to also do follow-up work (e.g. "and link it from the Linear ticket"), continue. Otherwise stop.

## Failure modes

- **Database not found:** the search returned no matching database. Tell the user the name you searched for and ask them to share the URL or correct the name.
- **Multiple databases match:** list the candidates with their URLs and ask which one.
- **Schema rejects a tag:** the option name doesn't exist in the multi-select. Drop it (or, if the user explicitly asked for it, surface that the tag option doesn't exist and offer to skip it — do not silently create new tag options without asking).
- **Title too long / empty:** Notion accepts long titles but truncates in views. If empty, fall back to a date-stamped placeholder like `Plan — 2026-05-06` and flag that you guessed.
- **Body has Notion-incompatible markdown:** Notion's flavoured markdown spec is at the MCP resource `notion://docs/enhanced-markdown-spec` if needed for tricky cases (tables, callouts, toggle blocks). Fetch it via `read_resource` only if a first attempt fails to render a specific construct.

## Notes

- The default database, "Claude Planning Log", currently has database id `ee65621df68e45caacac4ac04954fe69` and data source id `82dc2286-3ccf-40b1-9503-73f5bb8a4a41`. **Do not hardcode these** — re-resolve via search every time. The hint is here only so you can sanity-check the result of Step 1.
- The `Project` select currently has only one option (`merchant-graph-services`). When new options are added, the schema will show them — adapt automatically.
- Keep the tag list conservative. The user has a small fixed set; inventing new ones requires schema changes.
- Don't over-summarise the plan content when copying it to Notion — preserve the structure the user produced. The whole point of logging it is to keep the detail.
