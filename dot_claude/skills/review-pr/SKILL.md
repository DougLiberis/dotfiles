---
name: review-pr
description: Review a GitHub PR against its linked Linear ticket
argument-hint: "[pr-url-or-number]"
disable-model-invocation: true
allowed-tools:
  - "Bash(gh pr view:*)"
  - "Bash(gh pr diff:*)"
  - "Bash(gh pr review:*)"
  - "Bash(gh api:*)"
  - "Bash(gh pr list:*)"
  - "Bash(git rev-parse:*)"
  - "Bash(git remote:*)"
  - "Bash(git branch:*)"
  - "mcp__plugin_linear_linear__get_issue"
  - "mcp__plugin_linear_linear__list_comments"
---

# Review PR against Linear Ticket

You are a senior code reviewer. Review the given pull request thoroughly against its linked Linear ticket.

## Input

The user argument is: $ARGUMENTS

This can be:
- A full PR URL (e.g., `https://github.com/LiberisFinance/partner-hub/pull/123`)
- `owner/repo#123` format
- `#123` or a bare number (uses current repo context)
- Empty / no argument (find the PR for the current branch)

## Step 1: Resolve the PR

**If a full URL is provided**, extract owner, repo, and PR number from it. The URL format is `https://github.com/{owner}/{repo}/pull/{number}`.

**If `owner/repo#123`** format, parse directly.

**If `#123` or bare number**, detect the current repo:
```bash
git remote get-url origin
```
Extract owner/repo from the remote URL.

**If no argument**, find the PR for the current branch:
```bash
gh pr list --head "$(git branch --show-current)" --json number,url --limit 1
```

Once you have `owner/repo` and the PR number, proceed.

## Step 2: Fetch PR metadata

Run this command to get PR details (substitute the real owner, repo, and number):
```bash
gh pr view {NUMBER} --repo {OWNER}/{REPO} --json title,body,headRefName,baseRefName,state,author,labels,commits,additions,deletions,changedFiles,reviews,url
```

Store the title, body, branch name, and commit messages for later.

## Step 3: Fetch the diff

```bash
gh pr diff {NUMBER} --repo {OWNER}/{REPO} --patch
```

If the diff is extremely large (5000+ lines), note this and focus your review on the most critical files. You can fetch specific files if needed:
```bash
gh api repos/{OWNER}/{REPO}/pulls/{NUMBER}/files --paginate
```

## Step 4: Extract Linear ticket ID

Search for a Linear ticket reference matching the pattern `[A-Z]{1,10}-\d+` (e.g., `PARTNER-905`, `FUND-4099`, `CLOUD-42`). Check these sources in priority order:

1. **PR title**
2. **PR body**
3. **Branch name** (normalize to uppercase — branches often use lowercase like `partner-905-some-description`)
4. **Commit messages**

The ticket ID is the FIRST match found. If multiple distinct ticket IDs are found, note them all but use the one from the highest-priority source as primary.

**Important**: Branch names often contain the ticket ID in lowercase (e.g., `feature/partner-905-add-widget`). Convert to uppercase (`PARTNER-905`) before querying Linear.

If NO ticket reference is found at all, skip to Step 6 and perform a code-quality-only review (note that no Linear ticket was linked).

## Step 5: Fetch Linear ticket

Use the Linear MCP tools to get the ticket details:

1. Call `mcp__plugin_linear_linear__get_issue` with the ticket identifier (e.g., `PARTNER-905`). Set `includeRelations: true`.
2. Call `mcp__plugin_linear_linear__list_comments` with the issue ID from the result above.

Extract from the ticket:
- **Title** and **description** (requirements/scope)
- **Acceptance criteria** (often in the description or comments)
- **Labels/priority/status**
- **Any linked sub-issues or parent issues** for additional context

If the ticket is not found in Linear, report this and continue with a code-quality-only review.

## Step 6: Produce the review

Write a thorough, structured review with these sections:

### Review header
```
## PR Review: {PR_TITLE}
**PR:** {PR_URL}
**Linear:** {TICKET_ID} — {TICKET_TITLE} (or "No linked ticket")
**Author:** {AUTHOR}
**Branch:** {HEAD} -> {BASE}
**Size:** +{ADDITIONS} -{DELETIONS} across {CHANGED_FILES} files
```

### 1. Scope Alignment
Compare the PR changes against the Linear ticket requirements **requirement by requirement**. For each requirement or acceptance criterion in the ticket:
- Is it addressed by the PR? (Yes / Partially / No)
- Where in the code is it implemented?

### 2. Missing Requirements
List any requirements from the Linear ticket that are **not addressed** by this PR. Be specific — quote the requirement and explain what's missing.

### 3. Out-of-Scope Changes
List any changes in the PR that are **not related** to the Linear ticket. These aren't necessarily bad (cleanup, small refactors) but should be called out. Flag anything that looks like it should be a separate PR.

### 4. Code Quality & Potential Bugs
Review the diff for:
- Logic errors or potential bugs
- Error handling gaps
- Security concerns (injection, auth, data exposure)
- Performance issues (N+1 queries, unnecessary allocations, missing indexes)
- Naming, readability, and maintainability
- Adherence to patterns visible in the existing code

For each issue found, reference the specific file and line/hunk.

### 5. Test Coverage
Assess:
- Are there new/modified tests for the changes?
- Do the tests cover the happy path and key edge cases?
- Are there any untested code paths that should have tests?
- Do existing tests need updating due to the changes?

### 6. Acceptance Criteria Check
If the Linear ticket has explicit acceptance criteria, evaluate each one:

| Criterion | Status | Notes |
|-----------|--------|-------|
| {criterion text} | Met / Partially Met / Not Met | {explanation} |

### Summary

Provide a summary table:

| Area | Rating |
|------|--------|
| Scope alignment | Good / Partial / Poor |
| Code quality | Good / Some issues / Needs work |
| Test coverage | Good / Partial / Missing |
| Acceptance criteria | All met / Partial / Not met |

**Overall assessment:** One of:
- **Approve** — PR looks good, minor nits only
- **Approve with suggestions** — PR is solid but has improvement opportunities
- **Request changes** — PR has issues that should be fixed before merging
- **Needs discussion** — PR raises questions that need team input

End with a prioritized list of action items if any changes are requested.

## Step 7: Posting the review to GitHub (only if requested)

The Step 6 write-up is for the conversation. Only post anything to GitHub if the user explicitly asks (e.g. "approve this", "request changes", "leave a comment", "post this review"):

```bash
gh pr review {NUMBER} --repo {OWNER}/{REPO} --approve|--request-changes|--comment --body "..."
```

**The posted body must not restate what the PR does or list what was checked/verified** — no recapping scope alignment, no "confirmed X", no "ran the build/tests and they passed". That's already in the conversation and in the PR description; repeating it on GitHub is redundant noise for the author.

The posted body should contain only:
- The verdict itself, if it needs any qualification beyond the approve/request-changes state
- Nits — minor, non-blocking suggestions — as short comments

If there's nothing nit-worthy, post with an empty or near-empty body. Keep it short.
