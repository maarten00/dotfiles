#!/bin/sh
# Symlink all Claude Code skills from the dotfiles into ~/.claude/skills.
# Idempotent; leaves machine-local skills (not in the repo) untouched.

mkdir -p "$HOME/.claude/skills"

for skill in "$HOME/.dotfiles/claude/skills/"*.md; do
  [ -e "$skill" ] || continue  # no matches -> glob stays literal, skip it
  ln -sfn "$skill" "$HOME/.claude/skills/$(basename "$skill")"
done
