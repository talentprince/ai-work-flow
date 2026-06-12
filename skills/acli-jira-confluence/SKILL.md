---
name: acli-jira-confluence
description: Use when the user wants to read, fetch, or view Jira issues or Confluence pages. Always use acli as the primary method; fall back to curl with an API token only if acli does not support the specific operation. If the user explicitly says to use Playwright, switch to the Playwright skill instead. Handles acli installation and SSO login if missing or not authenticated.
---

# Atlassian CLI (acli) — Read Jira & Confluence

**Rule: Always use `acli` first.** Only fall back to `curl` + API token when acli explicitly does not support the operation (e.g. an endpoint acli has no subcommand for). Never skip acli just because curl seems simpler.

**Exception: If the user explicitly says to use Playwright** to read a Jira issue or Confluence page, skip acli entirely and follow the Playwright section below.

---

## Step 1 — Ensure acli is installed

```bash
which acli || command -v acli
```

If **not found**, install it:

### macOS (Homebrew)
```bash
brew tap atlassian/homebrew-acli
brew trust --formula atlassian/acli/acli
brew install acli
```

Verify after install:
```bash
acli --version
```

---

## Step 2 — Ensure acli is authenticated

```bash
acli auth status
```

### Not logged in → login

```bash
acli auth login
```

This opens a browser, completes the authentication flow, and saves the session automatically. Confirm afterwards:

```bash
acli auth status
```

---

## Step 3 — Read a Jira Issue (use acli)

```bash
# Get a Jira issue by key
acli jira issue get <ISSUE_KEY>

# JSON output for structured parsing
acli jira issue get <ISSUE_KEY> --output json

# List issues in a project
acli jira issue list --project <PROJECT_KEY>

# Search with JQL
acli jira issue list --jql "project = PROJ AND status = 'In Progress'"
```

### Fallback: curl (only if acli does not support the operation)

```bash
curl -u "YOUR_EMAIL:YOUR_API_TOKEN" \
  "https://<your-domain>.atlassian.net/rest/api/3/issue/<ISSUE_KEY>"
```

---

## Step 4 — Read a Confluence Page (use acli)

```bash
# Get a page by ID
acli confluence page get <PAGE_ID>

# Get by space key and title
acli confluence page get --space <SPACE_KEY> --title "Page Title"

# JSON output
acli confluence page get <PAGE_ID> --output json

# Extract body text only
acli confluence page get <PAGE_ID> --output json | jq '.body.storage.value'

# List pages in a space
acli confluence page list --space <SPACE_KEY>

# Search by title
acli confluence page list --space <SPACE_KEY> --title "search term"
```

### Fallback: curl (only if acli does not support the operation)

```bash
# Fetch page with rendered body
curl -u "YOUR_EMAIL:YOUR_API_TOKEN" \
  "https://<your-domain>.atlassian.net/wiki/rest/api/content/<PAGE_ID>?expand=body.view,title"

# Strip HTML and print readable text
curl -u "YOUR_EMAIL:YOUR_API_TOKEN" \
  "https://<your-domain>.atlassian.net/wiki/rest/api/content/<PAGE_ID>?expand=body.view,title" \
  | python3 -c "
import sys, json, re
d = json.load(sys.stdin)
print('Title:', d['title'])
print()
text = re.sub(r'<[^>]+>', '', d['body']['view']['value'])
print(re.sub(r'\n{3,}', '\n\n', text).strip())
"
```

---

## Playwright — Browser-based reading (explicit user request only)

Use this section **only when the user explicitly asks to use Playwright** to read a Jira or Confluence page.

### Step 0 — Defer to the Playwright skill

First, load the **Playwright skill** if it exists. It provides detailed, up-to-date instructions for browser automation in this environment. Use `skill tool` to load it:

```
skill: playwright
```

If the Playwright skill is not found, continue with the instructions below.

### Step 1 — Ensure playwright-cli is installed

```bash
which playwright-cli || command -v playwright-cli
```

If **not found**, install it via npm:

```bash
npm install -g playwright-cli
```

Verify after install:

```bash
playwright-cli --version
```

### Step 1b — Download the Playwright skill

After confirming `playwright-cli` is available, download the Playwright skill so it can be loaded:

```bash
playwright-cli install --skills
```

### Step 2 — Launch mode priority

**Priority 1 — Dev mode (preferred)**

Launch Playwright with `devtools: true`. This opens the browser with Chrome DevTools attached, giving full CDP access and making it easier to debug selector issues or inspect page structure during content extraction.

```js
const { chromium } = require('playwright');

const browser = await chromium.launch({
  channel: 'chrome',
  headless: false,
  devtools: true,       // <-- preferred: opens DevTools panel automatically
  args: ['--no-sandbox']
});

const page = await browser.newPage();
await page.goto('<URL>', { waitUntil: 'domcontentloaded', timeout: 60000 });

// Wait for content to settle
await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => {});
```

If the page redirects to an SSO/login screen, devtools mode lets the user complete login in the visible browser window. Wait for the user to confirm they are on the target page before extracting content.

**Priority 2 — Profile mode (fallback)**

If devtools mode cannot authenticate (e.g. automated environment with no user present), fall back to launching with the user's existing Chrome profile to reuse the active Atlassian session:

```js
const browser = await chromium.launchPersistentContext(
  `${process.env.HOME}/Library/Application Support/Google/Chrome`,
  {
    channel: 'chrome',
    headless: false,
    devtools: true,
    args: ['--profile-directory=Default', '--no-sandbox']
  }
);
```

> If the profile directory is locked (Chrome already running), copy it to a temp location first:
> ```bash
> cp -r "$HOME/Library/Application Support/Google/Chrome/Default" /tmp/chrome-profile-copy/Default
> ```
> Then point `launchPersistentContext` at `/tmp/chrome-profile-copy`.

### Content extraction

After the page has fully loaded, extract:
- **Page title** — `page.title()`
- **Main body text** — try these selectors in order, use the first that matches:
  1. `#main-content`
  2. `.wiki-content`
  3. `[data-testid="confluence-ui-kit-renderer"]`
  4. `.ak-renderer-document`
  5. `#content-body`
  6. Fallback: strip `nav, header, footer, [role="navigation"]` then return `document.body.innerText`
- **Linked tickets or pages** mentioned in the content

Return the extracted content as clean readable text.

---

## Decision flow

```
Need to read a Jira issue or Confluence page?
  │
  ├─ User said "use Playwright"?
  │     Yes → load Playwright skill (if available)
  │           └─ playwright-cli installed?   No  → playwright-cli install --skills
  │           └─ Try dev mode (devtools: true) first
  │                 └─ SSO wall hit? → user completes login in browser window
  │           └─ Dev mode fails / no user? → profile mode fallback
  │                 └─ Profile locked? → copy profile to temp dir, relaunch
  │
  └─ No → use acli
       └─ Is acli installed?       No  → install acli (Step 1)
       └─ Is acli authenticated?   No  → acli auth login (Step 2)
       └─ Does acli support this?  Yes → use acli (Steps 3–4)
                                    No → use curl fallback (Steps 3–4)
```

---

## Common acli flags

| Flag | Description |
|------|-------------|
| `--output json` | Machine-readable JSON output |
| `--site <url>` | Override configured site URL |
| `--no-color` | Disable ANSI color codes |

---

## Troubleshooting

- **403 / "not permitted"**: Org enforces SSO — run `acli auth login --site https://<your-domain>.atlassian.net`.
- **401 Unauthorized**: Session expired — re-run `acli auth login`, or regenerate API token at `id.atlassian.com`.
- **404 Not Found**: Wrong issue key / page ID, or insufficient permissions.
- **acli: command not found after install**: Add the install directory (`/usr/local/bin` or `~/.local/bin`) to your `$PATH`.
- **SSL / proxy errors**: Set `HTTPS_PROXY` env var before running acli or curl.
