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
export PATH="$test_dir/bin:$PATH"
export AGENT_SKILLS_HOME="$test_dir/home"
export AGENT_SKILLS_MANIFEST_FILE="$test_dir/home/.agents/.dotfiles-skills"

assert_manifest_lists()
{
    grep -Fxq -- "$1" "$AGENT_SKILLS_MANIFEST_FILE" ||
        fail "manifest does not list: $1"
}

: > "$AGENT_SKILLS_TEST_LOG"
"$repo_dir/scripts/sync-agent-skills.sh"
assert_line_count 2
assert_log_contains "--yes skills@1.5.26 add $repo_dir --global --skill * --yes --agent claude-code --agent codex"
assert_log_contains "skills@1.5.26 add addyosmani/agent-skills --global --skill * --agent claude-code --agent codex"

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

# The manifest records the skills this repo ships, so a later run can tell which
# installed skills became stale.
: > "$AGENT_SKILLS_TEST_LOG"
"$repo_dir/scripts/sync-agent-skills.sh" --local
assert_manifest_lists pr-review
assert_manifest_lists pull-request

# A skill dropped from the repo is uninstalled from every agent on the next run.
mkdir -p "$AGENT_SKILLS_HOME/.agents/skills/gone" \
    "$AGENT_SKILLS_HOME/.agents/skills/pr-review" \
    "$AGENT_SKILLS_HOME/.claude/skills"
: > "$AGENT_SKILLS_HOME/.agents/skills/gone/SKILL.md"
ln -s ../../.agents/skills/gone "$AGENT_SKILLS_HOME/.claude/skills/gone"
printf 'gone\n' >> "$AGENT_SKILLS_MANIFEST_FILE"

: > "$AGENT_SKILLS_TEST_LOG"
"$repo_dir/scripts/sync-agent-skills.sh" --local >/dev/null

[ ! -e "$AGENT_SKILLS_HOME/.agents/skills/gone" ] ||
    fail 'a removed skill was left installed'
[ ! -L "$AGENT_SKILLS_HOME/.claude/skills/gone" ] ||
    fail 'a removed skill left a dangling Claude Code link'
[ -d "$AGENT_SKILLS_HOME/.agents/skills/pr-review" ] ||
    fail 'a skill the repo still ships was pruned'
if grep -Fxq -- gone "$AGENT_SKILLS_MANIFEST_FILE"; then
    fail 'the manifest still lists a pruned skill'
fi

# Skills from external packs are never in the manifest, so they survive a prune.
mkdir -p "$AGENT_SKILLS_HOME/.agents/skills/external-pack-skill"
: > "$AGENT_SKILLS_TEST_LOG"
"$repo_dir/scripts/sync-agent-skills.sh" --local >/dev/null
[ -d "$AGENT_SKILLS_HOME/.agents/skills/external-pack-skill" ] ||
    fail 'an external pack skill was pruned'

# A Claude Code path the installer did not create is left for the user to sort out.
mkdir -p "$AGENT_SKILLS_HOME/.agents/skills/handmade" \
    "$AGENT_SKILLS_HOME/.claude/skills/handmade"
printf 'handmade\n' >> "$AGENT_SKILLS_MANIFEST_FILE"
: > "$AGENT_SKILLS_TEST_LOG"
"$repo_dir/scripts/sync-agent-skills.sh" --local >/dev/null 2>&1
[ -d "$AGENT_SKILLS_HOME/.claude/skills/handmade" ] ||
    fail 'a directory the installer did not create was deleted'

printf 'PASS: sync-agent-skills\n'
