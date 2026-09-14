#!/bin/sh

set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/sync-agent-skills-test.XXXXXX")
trap 'rm -rf "$test_dir"' EXIT HUP INT TERM

mkdir -p "$test_dir/bin"

cat > "$test_dir/bin/npx" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "$AGENT_SKILLS_TEST_LOG"
[ "${AGENT_SKILLS_TEST_FAIL:-false}" != true ]
EOF
chmod +x "$test_dir/bin/npx"

fail()
{
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

assert_line_count()
{
    expected=$1
    actual=$(wc -l < "$AGENT_SKILLS_TEST_LOG" | tr -d ' ')
    [ "$actual" = "$expected" ] || fail "expected $expected installer calls, got $actual"
}

assert_log_contains()
{
    grep -F -- "$1" "$AGENT_SKILLS_TEST_LOG" >/dev/null ||
        fail "installer invocation does not contain: $1"
}

export AGENT_SKILLS_TEST_LOG="$test_dir/invocations.log"
export AGENT_SKILLS_HOME="$test_dir/home"
export PATH="$test_dir/bin:$PATH"

mkdir -p "$AGENT_SKILLS_HOME/.claude/skills"
ln -s "$repo_dir/claude/skills/create-branch.md" \
    "$AGENT_SKILLS_HOME/.claude/skills/create-branch.md"
ln -s "$test_dir/unmanaged.md" \
    "$AGENT_SKILLS_HOME/.claude/skills/unmanaged.md"

: > "$AGENT_SKILLS_TEST_LOG"
"$repo_dir/scripts/sync-agent-skills.sh"
assert_line_count 2
assert_log_contains "--yes skills@1.5.26 add $repo_dir --global --skill * --yes --agent claude-code --agent codex"
assert_log_contains "skills@1.5.26 add addyosmani/agent-skills --global --skill * --agent claude-code --agent codex"
[ ! -L "$AGENT_SKILLS_HOME/.claude/skills/create-branch.md" ] ||
    fail 'legacy dotfiles-managed Claude symlink remains'
[ -L "$AGENT_SKILLS_HOME/.claude/skills/unmanaged.md" ] ||
    fail 'unmanaged Claude symlink was removed'

ln -s "$repo_dir/claude/skills/create-branch.md" \
    "$AGENT_SKILLS_HOME/.claude/skills/create-branch.md"
if AGENT_SKILLS_TEST_FAIL=true "$repo_dir/scripts/sync-agent-skills.sh" 2>/dev/null; then
    fail 'installer failure was ignored'
fi
[ -L "$AGENT_SKILLS_HOME/.claude/skills/create-branch.md" ] ||
    fail 'legacy link was removed before its replacement installed'
rm "$AGENT_SKILLS_HOME/.claude/skills/create-branch.md"

: > "$AGENT_SKILLS_TEST_LOG"
"$repo_dir/scripts/sync-agent-skills.sh" --offline
assert_line_count 1
assert_log_contains "--offline --yes skills@1.5.26 add $repo_dir"

: > "$AGENT_SKILLS_TEST_LOG"
"$repo_dir/scripts/sync-agent-skills.sh" --local
assert_line_count 1
assert_log_contains "skills@1.5.26 add $repo_dir"

: > "$AGENT_SKILLS_TEST_LOG"
if AGENT_SKILLS_AGENTS='codex --copy' "$repo_dir/scripts/sync-agent-skills.sh" 2>/dev/null; then
    fail 'an option-like agent value was accepted'
fi
assert_line_count 0

if "$repo_dir/scripts/sync-agent-skills.sh" --local unexpected 2>/dev/null; then
    fail 'unexpected extra arguments were accepted'
fi

printf '%s\n' '--copy' > "$test_dir/invalid.sources"
: > "$AGENT_SKILLS_TEST_LOG"
if AGENT_SKILLS_SOURCES_FILE="$test_dir/invalid.sources" \
    "$repo_dir/scripts/sync-agent-skills.sh" 2>/dev/null; then
    fail 'an option-like source value was accepted'
fi
assert_line_count 1

printf 'PASS: sync-agent-skills\n'
