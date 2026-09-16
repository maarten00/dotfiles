#!/bin/sh

set -eu

usage()
{
    printf 'Usage: %s [--local|--offline]\n' "$(basename -- "$0")" >&2
}

[ "$#" -le 1 ] || {
    usage
    exit 2
}

case ${1-} in
    '')
        include_external=true
        offline=false
        ;;
    --local)
        include_external=false
        offline=false
        ;;
    --offline)
        include_external=false
        offline=true
        ;;
    -h|--help)
        usage
        exit 0
        ;;
    *)
        usage
        exit 2
        ;;
esac

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
agents=${AGENT_SKILLS_AGENTS:-'claude-code codex'}
sources_file=${AGENT_SKILLS_SOURCES_FILE:-"$repo_dir/agent-skills.sources"}
agent_skills_home=${AGENT_SKILLS_HOME:-"$HOME"}
manifest_file=${AGENT_SKILLS_MANIFEST_FILE:-"$agent_skills_home/.agents/.dotfiles-skills"}

command -v npx >/dev/null 2>&1 || {
    printf 'npx is required to install agent skills.\n' >&2
    exit 1
}

for agent in $agents; do
    case $agent in
        ''|-*|*[!abcdefghijklmnopqrstuvwxyz0123456789-]*)
            printf 'Invalid agent name: %s\n' "$agent" >&2
            exit 1
            ;;
    esac
done

install_source()
{
    source=$1
    unattended=$2

    case $source in
        ''|-*|*[!abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._~:/@+-]*)
            printf 'Invalid agent skill source: %s\n' "$source" >&2
            exit 1
            ;;
    esac

    if [ "$offline" = true ]; then
        set -- npx --offline --yes skills@1.5.26 add "$source" \
            --global --skill '*'
    else
        set -- npx --yes skills@1.5.26 add "$source" --global --skill '*'
    fi

    if [ "$unattended" = true ]; then
        set -- "$@" --yes
    fi

    for agent in $agents; do
        set -- "$@" --agent "$agent"
    done

    "$@"
}

personal_skills()
{
    for skill_file in "$repo_dir"/skills/*/SKILL.md; do
        [ -f "$skill_file" ] || continue

        basename -- "$(dirname -- "$skill_file")"
    done
}

# Removes one skill this repo installed earlier but no longer ships. Names come
# from the manifest we wrote ourselves, never from a directory listing, so an
# external pack's skill can never be pruned by accident.
remove_installed_skill()
{
    name=$1

    case $name in
        ''|.|..|*/*|*[!abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-]*)
            printf 'Refusing to prune invalid skill name: %s\n' "$name" >&2
            return 0
            ;;
    esac

    universal_dir="$agent_skills_home/.agents/skills/$name"
    [ ! -d "$universal_dir" ] || rm -rf "$universal_dir"

    claude_link="$agent_skills_home/.claude/skills/$name"

    if [ -L "$claude_link" ]; then
        case $(readlink "$claude_link") in
            */.agents/skills/"$name") rm -- "$claude_link" ;;
        esac
    elif [ -e "$claude_link" ]; then
        printf 'Left %s in place: not a link into the shared skills directory.\n' \
            "$claude_link" >&2
    fi

    printf 'Pruned removed personal skill: %s\n' "$name"
}

# Skills recorded on the previous run but gone from skills/ are uninstalled, so
# deleting a personal skill propagates to every machine that pulls.
prune_removed_skills()
{
    [ -f "$manifest_file" ] || return 0

    current=$(personal_skills)

    while IFS= read -r name || [ -n "$name" ]; do
        [ -n "$name" ] || continue

        if printf '%s\n' "$current" | grep -Fxq -- "$name"; then
            continue
        fi

        remove_installed_skill "$name"
    done < "$manifest_file"
}

install_source "$repo_dir" true
prune_removed_skills

mkdir -p "$(dirname -- "$manifest_file")"
personal_skills > "$manifest_file"

if [ "$include_external" = true ]; then
    [ -f "$sources_file" ] || {
        printf 'Agent skill sources file not found: %s\n' "$sources_file" >&2
        exit 1
    }

    while IFS= read -r source || [ -n "$source" ]; do
        case $source in
            ''|'#'*) continue ;;
        esac

        install_source "$source" false
    done < "$sources_file"
fi
