---
name: project-navigation
description: Use when looking for, navigating to, or cloning a project or repository. Projects live under ~/Workspace/. Supports shorthand lookup by first-letter combos (e.g. "adg" resolves to "abc-def-ghi"). Clones missing repos from git@github.com:<ask for org if there are multiple> if not found locally.
---

# Project Navigation

Use this skill whenever you need to find, resolve, or clone a project repository.

**Projects root:** `~/Workspace/`
**Remote org:** `git@github.com:<ask for org if there are multiple>`

---

## Shorthand Resolution

A project shorthand is formed by taking the **first letter of each hyphen-separated segment** of the full repo name.

| Shorthand | Resolves to |
|-----------|-------------|
| `adg` | `abc-def-ghi` |
| `fe` | `foo-engine` |
| `myp` | `my-project` |

When the user refers to a project by shorthand, expand it before searching.

---

## Step 1 — Resolve the project name

Given a shorthand (e.g. `adg`), list all directories under `~/Workspace/` and find candidates whose segment initials match:

```bash
ls ~/Workspace/
```

For each directory name, split on `-`, take the first character of each part, and join. Compare that string to the shorthand (case-insensitive).

**Example resolution logic:**
```bash
# Find all repos whose initials match the shorthand "adg"
ls ~/Workspace/ | awk -F'-' '{
  initials=""
  for(i=1;i<=NF;i++) initials=initials substr($i,1,1)
  if (tolower(initials) == tolower("adg")) print $0
}'
```

If **exactly one match** is found → use it.
If **multiple matches** are found → list them and ask the human which one.
If **no match** is found → do NOT guess or infer from workspace contents. Proceed to Step 1a to search GitHub.

### Step 1a — Search GitHub when no local match

When no local match is found for the shorthand or name, search GitHub:

```bash
gh search repos "<query>" --owner <org> --limit 10 --json name,description | jq '.[].name'
```

- Present the list of matching repos to the human.
- Ask the human to confirm which repo to use.
- **Do NOT proceed to clone without explicit human confirmation.**

If GitHub search also returns no results:
- Tell the human no repo was found locally or on GitHub.
- Ask: "Do you know the exact repository name or URL?"

---

## Step 2 — Verify the local path exists

Once the full repo name is **confirmed by the human**, check if it exists locally:

```bash
ls ~/Workspace/<repo-name>
```

If it exists → the project path is `~/Workspace/<repo-name>`. Proceed to Step 3.
If it does not exist → proceed to clone (Step 2a).

### Step 2a — Clone from GitHub

```bash
git clone git@github.com:<org>/<repo-name>.git ~/Workspace/<repo-name>
```

If the clone fails (repo not found on remote):
- Inform the human: the repo was not found locally or on GitHub.
- Ask: "Do you know the exact repository name or URL?"

---

## Step 3 — Confirm and return the path

Once the repo exists locally, return the absolute path:

```bash
echo ~/Workspace/<repo-name>
# or
realpath ~/Workspace/<repo-name>
```

This path is what other skills (e.g. `story-workflow`) use as `<repo-path>`.

---

## Full Resolution Flow

```
User provides name or shorthand
  └─ Expand shorthand → full repo name
  └─ Scan ~/Workspace/ for match
       ├─ One match found      → use it
       ├─ Multiple matches     → ask human to disambiguate
       └─ No local match found
            └─ Search GitHub: gh search repos "<name>" --owner <org>
                 ├─ Results found   → present list → ask human to confirm
                 └─ No results      → ask human for exact name/URL
            └─ Human confirms repo name
                 └─ Clone from git@github.com:<org>/<repo-name>.git
                      ├─ Clone succeeds → use ~/Workspace/<repo-name>
                      └─ Clone fails    → ask human for correct name/URL
```

---

## Examples

| User says | Resolved repo | Local path |
|-----------|--------------|------------|
| `adg` | `abc-def-ghi` | `~/Workspace/abc-def-ghi` |
| `myp` | `my-project` | `~/Workspace/my-project` |
| `xyz` (not found locally) | clone `<org>/xyz` | `~/Workspace/xyz` |

---

## Notes

- Matching is **case-insensitive**.
- If the user provides the full repo name (no shorthand), skip resolution and go straight to Step 2.
- If the user provides a partial name that does not match as a shorthand, **do NOT fuzzy-match or infer** from workspace contents. Go to Step 1a and search GitHub instead.
- **Never assume a repo from the workspace without explicit human confirmation.** Inferring from surrounding directories is forbidden.
- After cloning, do not assume branch state — the `story-workflow` skill handles branch setup.
