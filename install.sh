#!/usr/bin/env bash
# install.sh — Install ai-work-flow skills for your AI coding agent
#
# Usage:
#   ./install.sh                          # interactive mode
#   ./install.sh --agent opencode         # install for a specific agent
#   ./install.sh --agent opencode --local # install locally (into current repo)
#   ./install.sh --agent all              # install for all supported agents
#   ./install.sh --help

set -e

SKILLS_SRC="$(cd "$(dirname "$0")/skills" && pwd)"

# ── helpers ───────────────────────────────────────────────────────────────────

print_header() {
  echo ""
  echo "  ai-work-flow installer"
  echo "  ──────────────────────"
  echo ""
}

print_usage() {
  echo "  Usage: ./install.sh [--agent <agent>] [--local] [--help]"
  echo ""
  echo "  Agents:"
  echo "    opencode   ~/.opencode/skills/<name>/SKILL.md"
  echo "    claude     ~/.claude/skills/<name>/SKILL.md"
  echo "    cursor     .cursor/rules/<name>.mdc  (local only)"
  echo "    cline      ~/Documents/Cline/Rules/<name>.md"
  echo "    windsurf   .devin/rules/<name>.md    (local only)"
  echo "    copilot    .github/instructions/<name>.instructions.md (local only)"
  echo "    all        install for every supported agent"
  echo ""
  echo "  Flags:"
  echo "    --local    install into current repo instead of global config"
  echo "    --help     show this message"
  echo ""
}

install_skills() {
  local dest="$1"
  local mode="$2"   # "opencode-style" | "flat-md" | "flat-mdc" | "flat-instructions"
  local ext="${3:-.md}"

  mkdir -p "$dest"
  local count=0

  for skill_dir in "$SKILLS_SRC"/*/; do
    local skill_name
    skill_name="$(basename "$skill_dir")"
    local skill_file="$skill_dir/SKILL.md"

    if [ ! -f "$skill_file" ]; then
      continue
    fi

    if [ "$mode" = "opencode-style" ]; then
      # Preserve full skill directory structure (OpenCode / Claude Code)
      local target_dir="$dest/$skill_name"
      mkdir -p "$target_dir"
      cp "$skill_file" "$target_dir/SKILL.md"
      echo "  [+] $skill_name → $target_dir/SKILL.md"
    else
      # Flatten to a single file per skill (Cursor, Cline, Windsurf, Copilot)
      local filename
      case "$ext" in
        .mdc)         filename="${skill_name}.mdc" ;;
        .instructions.md) filename="${skill_name}.instructions.md" ;;
        *)            filename="${skill_name}.md" ;;
      esac
      cp "$skill_file" "$dest/$filename"
      echo "  [+] $skill_name → $dest/$filename"
    fi

    count=$((count + 1))
  done

  echo ""
  echo "  $count skill(s) installed."
}

# ── argument parsing ───────────────────────────────────────────────────────────

AGENT=""
LOCAL=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --agent) AGENT="$2"; shift 2 ;;
    --local) LOCAL=true; shift ;;
    --help|-h) print_header; print_usage; exit 0 ;;
    *) echo "Unknown option: $1"; print_usage; exit 1 ;;
  esac
done

# ── interactive mode ───────────────────────────────────────────────────────────

print_header

if [ -z "$AGENT" ]; then
  echo "  Which AI agent are you installing for?"
  echo ""
  echo "    1) OpenCode"
  echo "    2) Claude Code"
  echo "    3) Cursor"
  echo "    4) Cline"
  echo "    5) Windsurf"
  echo "    6) GitHub Copilot"
  echo "    7) All of the above"
  echo ""
  read -rp "  Enter number [1-7]: " choice
  echo ""
  case "$choice" in
    1) AGENT="opencode" ;;
    2) AGENT="claude" ;;
    3) AGENT="cursor" ;;
    4) AGENT="cline" ;;
    5) AGENT="windsurf" ;;
    6) AGENT="copilot" ;;
    7) AGENT="all" ;;
    *) echo "  Invalid choice."; exit 1 ;;
  esac
fi

if [ "$LOCAL" = false ] && [[ "$AGENT" =~ ^(cursor|windsurf|copilot)$ ]]; then
  echo "  Note: $AGENT only supports local (repo-level) installation."
  LOCAL=true
fi

if [ "$LOCAL" = false ] && [ "$AGENT" != "all" ]; then
  echo "  Install globally or locally into the current repo?"
  echo ""
  echo "    1) Global  (applies to all projects)"
  echo "    2) Local   (applies to this repo only)"
  echo ""
  read -rp "  Enter number [1-2]: " scope_choice
  echo ""
  [[ "$scope_choice" == "2" ]] && LOCAL=true
fi

# ── install ────────────────────────────────────────────────────────────────────

do_install() {
  local agent="$1"
  local local_mode="$2"

  case "$agent" in

    opencode)
      if [ "$local_mode" = true ]; then
        dest=".opencode/skills"
      else
        dest="$HOME/.opencode/skills"
      fi
      echo "  Installing for OpenCode → $dest"
      echo ""
      install_skills "$dest" "opencode-style"
      echo "  Restart OpenCode to load the new skills."
      ;;

    claude)
      if [ "$local_mode" = true ]; then
        dest=".claude/skills"
      else
        dest="$HOME/.claude/skills"
      fi
      echo "  Installing for Claude Code → $dest"
      echo ""
      install_skills "$dest" "opencode-style"
      echo "  Skills are auto-loaded by Claude Code on next session."
      ;;

    cursor)
      dest=".cursor/rules"
      echo "  Installing for Cursor → $dest  (local only)"
      echo ""
      install_skills "$dest" "flat" ".mdc"
      echo "  Rules are auto-loaded by Cursor in this repo."
      ;;

    cline)
      if [ "$local_mode" = true ]; then
        dest=".clinerules"
      else
        if [[ "$OSTYPE" == "darwin"* || "$OSTYPE" == "linux"* ]]; then
          dest="$HOME/Documents/Cline/Rules"
        else
          dest="$USERPROFILE/Documents/Cline/Rules"
        fi
      fi
      echo "  Installing for Cline → $dest"
      echo ""
      install_skills "$dest" "flat" ".md"
      echo "  Rules are loaded by Cline automatically."
      ;;

    windsurf)
      dest=".devin/rules"
      echo "  Installing for Windsurf → $dest  (local only)"
      echo ""
      install_skills "$dest" "flat" ".md"
      echo "  Rules are auto-loaded by Windsurf in this repo."
      ;;

    copilot)
      dest=".github/instructions"
      echo "  Installing for GitHub Copilot → $dest  (local only)"
      echo ""
      install_skills "$dest" "flat" ".instructions.md"
      echo "  Instructions are auto-loaded by Copilot in this repo."
      ;;

    all)
      # Global agents
      echo "  ── OpenCode (global) ──────────────────────────────"
      install_skills "$HOME/.opencode/skills" "opencode-style"

      echo "  ── Claude Code (global) ───────────────────────────"
      install_skills "$HOME/.claude/skills" "opencode-style"

      echo "  ── Cline (global) ─────────────────────────────────"
      if [[ "$OSTYPE" == "darwin"* || "$OSTYPE" == "linux"* ]]; then
        install_skills "$HOME/Documents/Cline/Rules" "flat" ".md"
      else
        install_skills "$USERPROFILE/Documents/Cline/Rules" "flat" ".md"
      fi

      # Local-only agents (always go into current repo)
      echo "  ── Cursor (local) ─────────────────────────────────"
      install_skills ".cursor/rules" "flat" ".mdc"

      echo "  ── Windsurf (local) ───────────────────────────────"
      install_skills ".devin/rules" "flat" ".md"

      echo "  ── GitHub Copilot (local) ─────────────────────────"
      install_skills ".github/instructions" "flat" ".instructions.md"
      ;;

    *)
      echo "  Unknown agent: $agent"
      print_usage
      exit 1
      ;;
  esac
}

do_install "$AGENT" "$LOCAL"

echo ""
