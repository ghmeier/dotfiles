#!/usr/bin/env bash
# PreToolUse hook on Edit, MultiEdit, and Write: refuse new code comments that use any word
# in $banned below.
#
# Agents reach for these words as vague metaphors instead of saying what the code does.
# Only comment lines the edit adds are checked, so touching a file whose existing comments
# use these words is not blocked.

set -euo pipefail

# One jq call, NUL-separated, because each extra jq process costs several milliseconds and
# this runs on every edit.
{
  IFS= read -r -d '' tool_name
  IFS= read -r -d '' file_path
  IFS= read -r -d '' old_text
  IFS= read -r -d '' new_text
} < <(jq -j '.tool_input as $in | [
    .tool_name,
    ($in.file_path // ""),
    ([$in.old_string // empty, ($in.edits // [])[].old_string] | join("\n")),
    ([$in.content // empty, $in.new_string // empty, ($in.edits // [])[].new_string] | join("\n"))
  ] | map(. + "\u0000") | add')

case "$file_path" in
  *.py|*.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs|*.sh|*.yml|*.yaml|*.toml|*.css|*.scss|*.sql|*.html) ;;
  *) exit 0 ;;
esac

if [[ "$tool_name" == "Write" && -f "$file_path" ]]; then
  old_text=$(<"$file_path")
fi

banned='\b(carry|carries|carried|owns|owned)\b'
offending=$(
  grep -Fxv -f <(printf '%s\n' "$old_text") <<<"$new_text" |
    grep -iE \
      -e "^[[:space:]]*(#|//|/\*|\*|\{/\*|<!--|\"\"\"|''').*$banned" \
      -e "(^|[[:space:]])(#|//)[[:space:]].*$banned" ||
    true
)

if [[ -z "$offending" ]]; then
  exit 0
fi

{
  echo "Blocked: new comments use carry/carries/carried or owns/owned:"
  sed 's/^[[:space:]]*/  /' <<<"$offending"
  echo "Rewrite each comment in plain, literal words that say what the code does and why"
  echo '(for example "stores", "passes", "is responsible for", "creates"), or delete it if it'
  echo "restates the code."
} >&2
exit 2
