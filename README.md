## A Fresh macOS Setup

These instructions are for setting up new Mac devices. Instead, if you want to get started building your own dotfiles, you can [find those instructions below](#your-own-dotfiles).

### Backup your data

If you're migrating from an existing Mac, you should first make sure to backup all of your existing data. Go through the checklist below to make sure you didn't forget anything before you migrate.

- Did you commit and push any changes/branches to your git repositories?
- Did you remember to save all important documents from non-iCloud directories?
- Did you save all of your work from apps which aren't synced through iCloud?
- Did you remember to export important data from your local database?
- Did you update [mackup](https://github.com/lra/mackup) to the latest version and ran `mackup backup`?

### Setting up your Mac

After backing up your old Mac you may now follow these install instructions to setup a new one.

1. Update macOS to the latest version through system preferences
2. Setup an SSH key by using one of the two following methods  
   2.1. If you use 1Password, install it with the 1Password [SSH agent](https://developer.1password.com/docs/ssh/get-started/#step-3-turn-on-the-1password-ssh-agent) and sync your SSH keys locally.  
   2.2. Otherwise [generate a new public and private SSH key](https://docs.github.com/en/github/authenticating-to-github/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent) by running:

   ```zsh
   curl https://raw.githubusercontent.com/maarten00/dotfiles/HEAD/ssh.sh | sh -s "<your-email-address>"
   ```

3. Clone this repo to `~/.dotfiles` with:

    ```zsh
    git clone --recursive git@github.com:maarten00/dotfiles.git ~/.dotfiles
    ```

4. Run the installation with:

    ```zsh
    cd ~/.dotfiles && ./fresh.sh
    ```

   This will also symlink your tracked Ghostty config from [`ghostty/config`](./ghostty/config) to `~/Library/Application Support/com.mitchellh.ghostty/config`, link your global Claude Code instructions from [`claude/CLAUDE.md`](./claude/CLAUDE.md), and install your personal and declared external Agent Skills for Claude Code and Codex. When `npx` is not available yet, the setup installs the latest Node LTS release through `nvm` first.

5. Download the Iterm2 theme to your downloads folder. The color settings can be imported into iTerm2. Apply them in iTerm through iTerm → preferences → profiles → colors → load presets. You can create a different profile other than Default if you wish to do so.
6. Restart your computer to finalize the process

Your Mac is now ready to use!

> 💡 You can use a different location than `~/.dotfiles` if you want. Make sure you also update the references in the [`.zshrc`](./.zshrc#L2) and [`fresh.sh`](./fresh.sh#L20) files.

### Cleaning your old Mac (optionally)

After you've set up your new Mac you may want to wipe and clean install your old Mac. Follow [this article](https://support.apple.com/guide/mac-help/erase-and-reinstall-macos-mh27903/mac) to do that. Remember to [backup your data](#backup-your-data) first!

## Agent Skills

Personal skills use the open Agent Skills layout and live in
[`skills/`](./skills):

```text
skills/
  create-branch/SKILL.md
  design-first/SKILL.md
  pr-review/SKILL.md
  pull-request/SKILL.md
```

Edit these tracked source files rather than the installer-managed copies in an
agent's home directory. To add a personal skill, create
`skills/<skill-name>/SKILL.md` with `name` and `description` YAML frontmatter.

External whole-repository packs are declared one per line in
[`agent-skills.sources`](./agent-skills.sources). The current setup includes
[`addyosmani/agent-skills`](https://github.com/addyosmani/agent-skills) and
installs all 25 of its skills. The generic installer copies skill directories;
upstream repository-level supplementary references are only guaranteed by the
pack's native whole-repository integrations. The skills remain usable without
those optional checklists.

Run a local-only refresh after editing a personal skill:

```zsh
./scripts/sync-agent-skills.sh --local
```

By default, refresh personal skills and install or update all declared external
packs:

```zsh
./scripts/sync-agent-skills.sh
```

External installation stays interactive so the CLI can surface existing skills
before replacing a same-named entry.

The wrapper pins Vercel's `skills` CLI and targets Claude Code and Codex by
default. Override the target list for one run with a space-separated list of
[supported agent identifiers](https://github.com/vercel-labs/skills#supported-agents):

```zsh
AGENT_SKILLS_AGENTS='claude-code codex cursor gemini-cli' \
  ./scripts/sync-agent-skills.sh
```

`fresh.sh` installs both personal and external skills. The repository's
post-merge and post-rewrite hooks refresh personal skills only, avoiding network
access and implicit third-party updates during normal Git operations.
