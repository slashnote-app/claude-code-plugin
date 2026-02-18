#!/bin/bash
# git-context.sh — Collect git context for session hooks and skills
# Usage: source this file or call functions directly

get_git_branch() {
  git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown"
}

get_project_name() {
  basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || basename "$PWD"
}

get_recent_commits() {
  local count="${1:-5}"
  git log --oneline -n "$count" 2>/dev/null || echo "no commits"
}

get_commits_since() {
  local since="${1:-yesterday}"
  git log --oneline --since="$since" 2>/dev/null || echo "no commits"
}

get_uncommitted_summary() {
  local staged modified untracked
  staged=$(git diff --cached --stat 2>/dev/null | tail -1)
  modified=$(git diff --stat 2>/dev/null | tail -1)
  untracked=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')

  local parts=()
  [ -n "$staged" ] && parts+=("staged: $staged")
  [ -n "$modified" ] && parts+=("modified: $modified")
  [ "$untracked" -gt 0 ] && parts+=("$untracked untracked files")

  if [ ${#parts[@]} -eq 0 ]; then
    echo "clean working tree"
  else
    printf '%s; ' "${parts[@]}" | sed 's/; $//'
  fi
}

get_full_context() {
  local branch project commits uncommitted
  branch=$(get_git_branch)
  project=$(get_project_name)
  commits=$(get_recent_commits 5)
  uncommitted=$(get_uncommitted_summary)

  cat <<EOF
Project: $project
Branch: $branch
Uncommitted: $uncommitted
Recent commits:
$commits
EOF
}

# If called directly (not sourced), output full context
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  get_full_context
fi
