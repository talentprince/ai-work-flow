```
 █████╗ ██╗    ██╗ ██████╗ ██████╗ ██╗  ██╗    ███████╗██╗      ██████╗ ██╗    ██╗
██╔══██╗██║    ██║██╔═══██╗██╔══██╗██║ ██╔╝    ██╔════╝██║     ██╔═══██╗██║    ██║
███████║██║    ██║██║   ██║██████╔╝█████╔╝     █████╗  ██║     ██║   ██║██║ █╗ ██║
██╔══██║██║    ██║██║   ██║██╔══██╗██╔═██╗     ██╔══╝  ██║     ██║   ██║██║███╗██║
██║  ██║██║    ██║╚██████╔╝██║  ██║██║  ██╗    ██║     ███████╗╚██████╔╝╚███╔███╔╝
╚═╝  ╚═╝╚═╝    ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝     ╚══════╝ ╚═════╝  ╚══╝╚══╝
```

> A skills library that teaches AI coding agents to work like disciplined engineers —
> read the ticket, write the tests, never commit without human review.

## Why This Exists

We are living through a remarkable era — the early days of AI agents that can genuinely write code and ship features. This project is a small homage to that moment.

It's also a practical reference for engineers who are new to agentic programming and want to understand how it works in practice. Rather than abstract explanations, this repo shows a real, working setup: structured skills that guide an AI agent through the same workflow a disciplined engineer would follow — read the ticket, understand the codebase, implement with tests, and leave changes for human review.

If you've ever wondered "how do I actually get an AI agent to do useful work on my project?", this is a good place to start.

Once you grasp how the pieces fit together — skills, context, structured instructions — you'll find that building your own flows is straightforward. Automate your code review process, your deployment checklist, your onboarding steps, your team's specific conventions. The patterns here are intentionally simple so they're easy to copy, adapt, and own. The real payoff isn't this workflow; it's the one you build for yourself.

## Get Started

**Option 1 — via npx (recommended):**

```bash
npx skills add talentprince/ai-work-flow
```

**Option 2 — clone and run the installer:**

```bash
git clone https://github.com/talentprince/ai-work-flow.git
cd ai-work-flow
./install.sh
```

The installer asks which agent you use (OpenCode, Claude Code, Cursor, Cline, Windsurf, or Copilot) and whether to install globally or into the current repo. That's it.

## Skills Included

| Skill | What it does |
|-------|-------------|
| `story-workflow` | Pick up a Jira/GitHub ticket and implement it end-to-end |
| `project-navigation` | Find and clone repos by name or shorthand |
| `acli-jira-confluence` | Read Jira issues and Confluence pages |
| `github-gh` | Read GitHub repos, issues, PRs, and workflows |

## Purely Skills, No MCP Required

This entire workflow is built with skills alone — no MCP servers, no plugins, no extra tooling. If your environment doesn't support MCP or you simply don't want the overhead, this is a great way to get a fully capable agent workflow up and running.

Skills are also easy to extend and customise. Pair with your agent to tweak any part of the workflow to fit your team's needs.

## Philosophy

> *Read before code. Test everything. Never commit without review.*

## Your First Agentic Task

Once installed, the simplest way to experience agentic programming is to hand your agent a ticket and let it work:

```
start work on <ticket url>
```

For example:

```
start work on https://github.com/your-org/your-repo/issues/42
```

```
start work on https://your-org.atlassian.net/browse/PROJ-123
```
