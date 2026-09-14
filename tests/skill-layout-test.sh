#!/bin/sh

set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
count=0

fail()
{
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

for skill_file in "$repo_dir"/skills/*/SKILL.md; do
    [ -f "$skill_file" ] || fail 'no portable skills found'
    count=$((count + 1))

    skill_dir=$(basename -- "$(dirname -- "$skill_file")")
    skill_name=$(sed -n 's/^name:[[:space:]]*//p' "$skill_file" | head -n 1)
    description=$(sed -n 's/^description:[[:space:]]*//p' "$skill_file" | head -n 1)

    [ "$skill_name" = "$skill_dir" ] ||
        fail "$skill_file name does not match its directory"
    [ -n "$description" ] || fail "$skill_file has no description"
    description_length=$(printf '%s' "$description" | wc -c | tr -d ' ')
    [ "$description_length" -le 1024 ] ||
        fail "$skill_file description exceeds 1024 characters"
done

[ "$count" -eq 4 ] || fail "expected 4 portable skills, found $count"

if find "$repo_dir/claude/skills" -type f -name '*.md' -print -quit 2>/dev/null |
    grep . >/dev/null; then
    fail 'legacy flat Claude skills remain'
fi

printf 'PASS: portable skill layout\n'
