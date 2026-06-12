---
name: github-gh
description: Use when reading or fetching GitHub data such as repos, issues, pull requests, releases, workflows, or any GitHub resource. Handles gh CLI installation via brew if missing, and runs gh auth login if not authenticated.
---

# GitHub via gh CLI

Use this skill whenever the user wants to read or fetch data from GitHub (repos, issues, PRs, releases, actions/workflows, users, etc.).

## Setup Workflow

Always follow this order before running any `gh` command:

### 1. Check if `gh` is installed

```bash
which gh
```

If not found, install via Homebrew:

```bash
brew install gh
```

### 2. Check authentication status

```bash
gh auth status
```

If the output contains `not logged in` or returns a non-zero exit code, run the interactive login flow:

```bash
gh auth login
```

Follow the prompts (select GitHub.com, HTTPS or SSH, authenticate via browser or token).

### 3. Run the requested `gh` command

Once installed and authenticated, use `gh` to read the requested data. Common patterns:

#### Repos
```bash
gh repo view <owner>/<repo>
gh repo list <owner>
```

#### Issues
```bash
gh issue list --repo <owner>/<repo>
gh issue view <number> --repo <owner>/<repo>
```

#### Pull Requests
```bash
gh pr list --repo <owner>/<repo>
gh pr view <number> --repo <owner>/<repo>
```

#### Releases
```bash
gh release list --repo <owner>/<repo>
gh release view <tag> --repo <owner>/<repo>
```

#### GitHub Actions / Workflows
```bash
gh workflow list --repo <owner>/<repo>
gh run list --repo <owner>/<repo>
gh run view <run-id> --repo <owner>/<repo>
```

#### Search
```bash
gh search repos <query>
gh search issues <query>
gh search prs <query>
```

#### Raw API calls (when `gh` subcommands don't cover the need)
```bash
gh api repos/<owner>/<repo>
gh api repos/<owner>/<repo>/issues
gh api /users/<username>
```

## Notes

- Always prefer `gh` subcommands over raw `gh api` calls for readability.
- Use `--json` and `--jq` flags for structured output when parsing is needed.
- `gh` operates on the authenticated user's token scope — if a resource returns 404, the token may lack the required permission. In that case, re-run `gh auth login` and request additional scopes.
- Never store tokens in files; let `gh` manage credentials in its keychain.
