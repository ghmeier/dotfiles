#!/usr/bin/env bash
# PostToolUse hook: after any `git push`, fetch the remote and verify the
# pushed ref actually landed. On mismatch, block with the local/remote SHAs
# so the model must re-push instead of claiming success.
#
# Handles: plain `git push`, rtk-prefixed rewrites, `git -C <dir> push`,
# and `make wtx name=<branch> cmd="git push ..."` (runs inside the worktree).
# Fails open (exit 0) on anything it can't parse — this gate must never
# invent a failure.
#
# Wired in ~/.claude/settings.json under hooks.PostToolUse.

set -uo pipefail

input=$(cat)
command=$(jq -r '.tool_input.command // empty' <<<"$input")
cwd=$(jq -r '.cwd // empty' <<<"$input")

[[ -z "$command" ]] && exit 0

# Strip the rtk proxy prefix so parsing sees the real command.
command="${command#rtk }"

# Only care about pushes; skip deletes/tags (nothing to SHA-compare).
[[ "$command" != *"git push"* && "$command" != *" push"* ]] && exit 0
case "$command" in
  *--delete*|*--tags*|*" tag "*) exit 0 ;;
esac
[[ "$command" != *push* ]] && exit 0

repo_dir="$cwd"

# make wtx name=<branch> cmd="..." runs inside the named worktree.
if [[ "$command" =~ make\ wtx\ .*name=([^[:space:]]+) ]]; then
  wt="${BASH_REMATCH[1]}"
  [[ -d "$cwd/worktrees/$wt" ]] && repo_dir="$cwd/worktrees/$wt"
fi

# git -C <dir> push runs against <dir>.
if [[ "$command" =~ git\ -C\ ([^[:space:]]+)\ .*push ]]; then
  repo_dir="${BASH_REMATCH[1]}"
fi

git -C "$repo_dir" rev-parse --git-dir >/dev/null 2>&1 || exit 0

branch=$(git -C "$repo_dir" branch --show-current 2>/dev/null)
# Explicit refspec (git push origin foo or origin local:remote) overrides.
if [[ "$command" =~ push\ +(-u\ +)?origin\ +([^[:space:]:]+)(:([^[:space:]]+))? ]]; then
  explicit="${BASH_REMATCH[2]}"
  [[ "$explicit" != -* && "$explicit" != HEAD ]] && branch="$explicit"
fi
[[ -z "$branch" ]] && exit 0

# Small, bounded network cost; on fetch failure, fail open.
git -C "$repo_dir" fetch origin "$branch" --quiet 2>/dev/null || exit 0

local_sha=$(git -C "$repo_dir" rev-parse "$branch" 2>/dev/null)
remote_sha=$(git -C "$repo_dir" rev-parse "origin/$branch" 2>/dev/null)

[[ -z "$local_sha" ]] && exit 0

if [[ "$local_sha" == "$remote_sha" ]]; then
  jq -n --arg b "$branch" --arg s "${local_sha:0:10}" '{
    hookSpecificOutput: {
      hookEventName: "PostToolUse",
      additionalContext: ("verify-push: confirmed origin/" + $b + " is at " + $s + " (matches local). Safe to report this push as landed.")
    }
  }'
  exit 0
fi

jq -n --arg b "$branch" --arg l "${local_sha:0:10}" --arg r "${remote_sha:-<missing>}" '{
  decision: "block",
  reason: ("verify-push: local " + $b + " is at " + $l + " but origin/" + $b + " is at " + ($r | .[0:10]) + ". The push did NOT land. Re-push (check for rejection/auth output above) and do not report this branch as pushed until this hook confirms the SHAs match.")
}'
exit 0
