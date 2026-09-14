#!/bin/sh

set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/agent-skills-integration-test.XXXXXX")
trap 'rm -rf "$test_dir"' EXIT HUP INT TERM

fail()
{
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

grep -F 'scripts/sync-agent-skills.sh"' "$repo_dir/fresh.sh" >/dev/null ||
    fail 'fresh.sh does not install local and external skills'

if grep -F 'scripts/sync-agent-skills.sh" --' "$repo_dir/fresh.sh" >/dev/null; then
    fail 'fresh.sh overrides the default local-and-external mode'
fi

grep -F 'nvm install --lts' "$repo_dir/fresh.sh" >/dev/null ||
    fail 'fresh.sh does not provide npx on a clean machine'

bundle_line=$(grep -nF 'brew bundle --file ./Brewfile' "$repo_dir/fresh.sh" |
    cut -d: -f1)
skills_line=$(grep -nF 'scripts/sync-agent-skills.sh"' "$repo_dir/fresh.sh" |
    cut -d: -f1)
[ "$skills_line" -gt "$bundle_line" ] ||
    fail 'fresh.sh installs agent skills before its dependencies'

for hook in post-merge post-rewrite; do
    grep -F 'scripts/sync-agent-skills.sh"' "$repo_dir/git-hooks/$hook" >/dev/null ||
        fail "$hook does not sync portable skills"

    if grep -F -- '--external' "$repo_dir/git-hooks/$hook" >/dev/null; then
        fail "$hook unexpectedly updates external skills"
    fi

    grep -F -- '--offline' "$repo_dir/git-hooks/$hook" >/dev/null ||
        fail "$hook can contact the network"

    grep -F 'Could not refresh personal Agent Skills' "$repo_dir/git-hooks/$hook" >/dev/null ||
        fail "$hook can block git work when skill refresh fails"
done

mkdir -p "$test_dir/bin" "$test_dir/home"
cat > "$test_dir/bin/npx" <<'EOF'
#!/bin/sh
exit 1
EOF
chmod +x "$test_dir/bin/npx"

for hook in post-merge post-rewrite; do
    PATH="$test_dir/bin:$PATH" "$repo_dir/git-hooks/$hook" 2>/dev/null ||
        fail "$hook blocks git work when offline refresh fails"
done

[ ! -e "$repo_dir/claude/link-skills.sh" ] ||
    fail 'the legacy Claude-only skill wrapper still exists'

printf 'PASS: agent skill integration\n'
