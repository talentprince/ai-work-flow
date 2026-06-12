---
name: story-workflow
description: Use when an engineer wants to start working on a Jira ticket, Confluence story, or GitHub issue/file. Guides the full workflow: read the ticket, clarify requirements, locate the repo, branch from latest main/master, plan tasks, understand codebase patterns, implement, verify tests pass, and leave changes for human review.
---

# Story Workflow

This skill guides engineers through the full end-to-end flow of picking up a story and delivering implementation-ready changes for human review.

**Never make assumptions or hypotheses about requirements.** If anything is unclear, ask. If any context is missing, ask. Only implement what is explicitly stated or confirmed.

---

## Phase 1 — Read and Understand the Ticket

**CRITICAL: Load the correct skill FIRST, then fetch. Never use WebFetch for GitHub or Atlassian URLs — always delegate to the appropriate skill below before making any fetch call.**

Determine the source of the story from the URL or reference provided, then fetch accordingly:

### If the link is an Atlassian URL (Jira or Confluence)

Load and use the `acli-jira-confluence` skill to fetch the content.

- If a **Jira issue key** is provided (e.g. `PROJ-123`) or the URL contains `atlassian.net/browse/`: fetch with `acli jira issue get PROJ-123`
- If a **Confluence page URL** is provided (URL contains `atlassian.net/wiki/` or `/confluence/`): fetch with `acli confluence page get <PAGE_ID>`

### If the link is a GitHub URL

**You MUST invoke the `skill` tool with `name=github-gh` first. Do not call WebFetch or any other tool before the skill is loaded.**

Once the `github-gh` skill is loaded, follow its setup instructions (check `gh` is installed and authenticated), then run the appropriate command:

- **GitHub file** (URL contains `/blob/`): parse `<org>`, `<repo>`, `<branch>`, and `<path>` from the URL, then run:
  ```bash
  gh api "repos/<org>/<repo>/contents/<path>?ref=<branch>" --jq '.content' | base64 -d
  ```
- **GitHub issue** (URL contains `/issues/`): run `gh issue view <N> --repo <org>/<repo>`
- **GitHub PR** (URL contains `/pull/`): run `gh pr view <N> --repo <org>/<repo>`
- **GitHub repo info**: run `gh repo view <org>/<repo>`

**WebFetch is strictly forbidden for any `github.com` URL. Always use `gh` CLI.**

Read the full content carefully, including:
- Title and description
- Acceptance criteria
- Linked tickets or dependencies
- Attachments or referenced pages (fetch those too if relevant)

---

## Phase 2 — Clarify Requirements

After reading, identify **anything that is ambiguous, missing, or could be interpreted in more than one way**.

Ask the human all unclear questions **before proceeding**. Do not bundle assumptions into implementation. Keep asking follow-up questions until you are confident every requirement is unambiguous.

Examples of things to clarify:
- Scope: what is explicitly in/out of this story?
- Behaviour: edge cases, error handling, defaults
- Integration: which services, APIs, or data models are involved?
- UI/UX: exact copy, layout, or interaction details if applicable
- Non-functional: performance, security, or compatibility constraints

**Do not move to Phase 3 until all questions are resolved.**

---

## Phase 3 — Identify the Target Repository

**CRITICAL: Always use the `project-navigation` skill for this phase. Do not attempt to locate, resolve, or clone repos manually.**

Steps — execute in this exact order, do not skip or reorder:

**Step 1 — Infer and confirm with the human (MANDATORY STOP)**

Try to infer the repo name from the ticket content (mentions of repo name, service name, team, tech stack, Jira project key, etc.).

Then use the `question` tool to ask the human to confirm or correct the inferred repo name. **Do not run any navigation or git commands before the human has answered.**

> Example question: "I believe the target repo is `<inferred-name>`. Is that correct, or should I use a different repo?"

**Proceeding without explicit human confirmation of the repo is a violation of this workflow, even if the repo seems obvious from the URL or working directory.**

**Step 2 — Locate the repo using the project-navigation skill**

Only after the human has confirmed the repo name: invoke the `skill` tool with `name=project-navigation` and follow its instructions to resolve shorthand, verify the local path, and clone from GitHub if it is missing.

**Do not proceed to Phase 4 until the `project-navigation` skill has returned a confirmed local path.**

---

## Phase 4 — Prepare the Branch

Navigate into the repo and sync the default branch to the latest remote state:

```bash
cd <repo-path>

# Detect default branch (main or master)
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")

git checkout $DEFAULT_BRANCH
git pull origin $DEFAULT_BRANCH
```

Create a new branch. Determine the branch name using the following priority rules:

1. **Jira ticket** (source is a Jira issue, e.g. `PROJ-123`): use the Jira issue key as the prefix.
   ```bash
   git checkout -b feature/PROJ-123
   ```

2. **File with a ticket-style name** (source is a file whose name matches the pattern `XX-<number>`, e.g. `PROJ-456.md`, `AB-12-some-title.md`): extract the ticket-style prefix from the filename.
   ```bash
   # e.g. file is "PROJ-456-some-description.md" → prefix is "PROJ-456"
   git checkout -b feature/PROJ-456
   ```

3. **Any other source** (Confluence page, GitHub file with a generic name, etc.): slugify the document title — lowercase, replace spaces and special characters with hyphens, strip leading/trailing hyphens.
   ```bash
   # e.g. title "User Login Redesign" → slug "user-login-redesign"
   git checkout -b feature/user-login-redesign
   ```

Branch naming convention: `feature/<prefix-or-slug>`. Use `bugfix/` prefix if the story is a bug fix, `chore/` for maintenance tasks.

---

## Phase 5 — Understand the Codebase

### Read AGENTS.md or README

```bash
# Check for AGENTS.md first (preferred — contains agent/AI-specific conventions)
cat AGENTS.md 2>/dev/null || cat agents.md 2>/dev/null

# Fall back to README
cat README.md 2>/dev/null || cat README 2>/dev/null
```

Read and internalize:
- Project structure and architecture
- Coding conventions and patterns
- How to run the project locally
- How to run tests
- Any domain-specific rules or constraints

### If AGENTS.md does not exist — generate one

If neither `AGENTS.md` nor `agents.md` exists in the repo root, generate one by exploring the codebase:

1. Understand the tech stack, directory structure, and key patterns
2. Note how tests are run, how the app is built/started, and any important conventions
3. Write `AGENTS.md` at the repo root covering at minimum:
   - **Project overview**: what the project does
   - **Directory structure**: key folders and their purpose
   - **Tech stack**: languages, frameworks, key libraries
   - **Development setup**: how to install dependencies and run locally
   - **Testing**: how to run the test suite
   - **Conventions**: naming, architecture patterns, PR/commit style
   - **Key files**: entry points, config files, important modules

```markdown
# AGENTS.md template

## Project Overview
<one paragraph describing what this project does>

## Directory Structure
<tree of key directories with descriptions>

## Tech Stack
<languages, frameworks, major dependencies>

## Development Setup
<commands to install deps and run locally>

## Testing
<command(s) to run tests>

## Conventions
<coding style, naming conventions, architecture patterns>

## Key Files
<entry points, config files, important modules>
```

Commit the generated `AGENTS.md` on the feature branch before implementing the story tasks.

---

## Phase 6 — Plan the Tasks

Based **only** on the confirmed requirements (Phase 2), break the story into a concrete, ordered task list using the TodoWrite tool.

Rules for planning:
- **No hypotheses.** Only include tasks directly traceable to a stated requirement.
- Each task should be a single, testable unit of work.
- **Every implementation task must have a paired test task.** Tests are not optional and are not an afterthought — they are a delivery requirement. A feature task with no corresponding test task is incomplete.
- If a task depends on another, note the dependency.
- Do not start implementing until the plan is written and visible.

**Test coverage requirements by task type:**

| Task type | Required tests |
|-----------|---------------|
| New UI component or page | Render test asserting key content is present; snapshot or accessibility check |
| New API endpoint | Integration test covering success response and at least one error case |
| New business logic / utility | Unit tests covering happy path and all documented edge cases |
| Data model change | Unit tests for validation rules; migration tested in isolation if applicable |
| Bug fix | Regression test that would have caught the original bug |

Example task breakdown:
```
1. Add <X> field to <Model>
2. Write unit tests for <X> validation rules
3. Write migration for <X>
4. Expose <X> via <API endpoint>
5. Write integration tests for <API endpoint> (success + error cases)
6. Update AGENTS.md if new patterns are introduced
```

**After writing the plan, STOP. Do not write any code or make any file changes.**

Present the full task list clearly to the human, then use the `question` tool to ask for explicit approval:

> "The branch is ready and the task plan is above. Shall I start implementing?"

**Phase 7 must not begin until the human responds with approval. Proceeding without confirmation is a violation of this workflow.**

---

## Phase 7 — Implement

Work through the task list in order. For each task:

1. Mark it `in_progress` in the todo list
2. Implement the change following the conventions in `AGENTS.md` / `README`
3. Write tests alongside the implementation — not after. Tests for a feature live in the same todo task or the immediately following one; never defer them to the end
4. Mark it `completed` only after both the implementation **and** its tests are written

Key constraints:
- Follow existing code patterns; do not introduce new patterns without asking
- Do not add dependencies without confirming with the human first
- Do not modify unrelated files
- **Do NOT make any git commits.** Leave all changes unstaged/staged but uncommitted for the human to review.

**Testing is non-negotiable.** If the repo has no test framework set up, stop and ask the human which testing library to install before proceeding. Do not skip tests because the project is new or empty. Every acceptance criterion from Phase 2 must be covered by at least one test.

### Scaffolding a new framework into an existing repo

When the target repo is empty or has no framework yet and you need to scaffold (e.g. `create-next-app`, `create-react-app`, `npx nuxi init`, etc.), follow this pattern to avoid corrupting the repo's git state:

1. **Scaffold into a temp directory** (never scaffold directly into the repo):
   ```bash
   npx create-next-app@latest /tmp/scaffold-temp --yes [other flags]
   ```

2. **Copy files excluding `.git`** using `rsync`, not `cp -r`. Plain `cp -r` will copy the scaffold tool's `.git` folder and silently overwrite the real repo's git history, remote, and branches:
   ```bash
   # CORRECT — excludes .git
   rsync -a --exclude='.git' /tmp/scaffold-temp/ ~/Workspace/<repo>/

   # WRONG — overwrites .git, destroys branches and remote
   # cp -r /tmp/scaffold-temp/. ~/Workspace/<repo>/
   ```

3. **Verify the branch and remote are intact** after copying:
   ```bash
   cd ~/Workspace/<repo>
   git remote -v          # remote must still be present
   git branch             # feature branch must still exist
   git status             # should show new/modified files, not a detached HEAD
   ```

   If the remote or branch is missing, it means `.git` was overwritten. Restore with:
   ```bash
   git remote add origin <remote-url>
   git checkout -b feature/<branch-name>
   ```

4. **Empty repo caveat**: In a repo with no commits, a branch created with `git checkout -b` has no backing ref until the first commit. If `.git` is ever overwritten before any commit, the branch is lost. Always verify with `git branch` immediately after scaffolding.

---

## Phase 8 — Verify Tests Pass

Once all tasks are complete, run the full test suite:

```bash
# Run whatever test command is documented in AGENTS.md / README
# Common examples:
npm test
pytest
go test ./...
./gradlew test
bundle exec rspec
```

If any tests fail:
1. Fix the failure before proceeding
2. Do not skip or comment out tests to make them pass
3. If a pre-existing test is broken and unrelated to your changes, flag it to the human

All tests must be green before leaving changes for review.

---

## Phase 9 — Leave for Human Review

**MANDATORY before this phase:** Phase 8 (run tests) must be completed and all tests must be green. Never skip straight to leaving changes without running the test suite first.

Do **not** commit, push, open a PR, or merge. Leave the changes on the feature branch — files modified but **not committed** — in the local repository for the human to review.

Provide a summary to the human:

```
Branch: feature/<ticket-or-slug>
Repo: <repo-path>

Changes made:
- <concise bullet list of what was changed and why>

Tests added:
- <list each test file and what it covers>

Test suite: all passing

Ready for your review.
```

If you generated an `AGENTS.md`, call that out explicitly in the summary so the human is aware.

---

## Full Workflow Checklist

- [ ] Source URL identified (Atlassian → acli-jira-confluence skill; GitHub → github-gh skill)
- [ ] Ticket/page/file read via appropriate skill
- [ ] All requirements clarified — no open questions
- [ ] Human explicitly confirmed the target repo via `question` tool **before** any navigation commands ran
- [ ] Target repo located via `project-navigation` skill and confirmed accessible
- [ ] Default branch pulled to latest
- [ ] Feature branch created with correct naming
- [ ] AGENTS.md / README read (or AGENTS.md generated if missing)
- [ ] Task plan written with TodoWrite — no hypotheses
- [ ] All tasks implemented following repo conventions
- [ ] Every implementation task has a paired test task in the plan
- [ ] Tests written alongside implementation — not deferred to the end
- [ ] Every acceptance criterion from Phase 2 is covered by at least one test
- [ ] Full test suite passes (mandatory — must run before leaving for review)
- [ ] No git commits made — changes left unstaged/staged but uncommitted
- [ ] Changes left on branch for human review with summary
