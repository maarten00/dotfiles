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

install_source "$repo_dir" true

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
