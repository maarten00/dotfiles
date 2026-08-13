#!/bin/sh

echo "Setting up your Mac..."

# Check for Oh My Zsh and install if we don't have it
if test ! $(which omz); then
  /bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/HEAD/tools/install.sh)"
fi

# Check for Homebrew and install if we don't have it
if test ! $(which brew); then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> $HOME/.zprofile
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Removes .zshrc from $HOME (if it exists) and symlinks the .zshrc file from the .dotfiles
ln -sfn "$HOME/.dotfiles/.zshrc" "$HOME/.zshrc"

# Symlink the .zshenv file from the .dotfiles
ln -sfn "$HOME/.dotfiles/.zshenv" "$HOME/.zshenv"

# Symlink the Ghostty config from the .dotfiles
mkdir -p "$HOME/Library/Application Support/com.mitchellh.ghostty"
ln -sfn "$HOME/.dotfiles/ghostty/config" "$HOME/Library/Application Support/com.mitchellh.ghostty/config"

# Symlink the global Claude Code instructions from the .dotfiles
mkdir -p "$HOME/.claude"
ln -sfn "$HOME/.dotfiles/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"

# Symlink the Claude Code skills from the .dotfiles (leaves machine-local skills untouched)
sh "$HOME/.dotfiles/claude/link-skills.sh"

# Route this repo's git hooks to the tracked git-hooks directory, so pulling new
# skills re-links them automatically (see git-hooks/post-merge)
git -C "$HOME/.dotfiles" config core.hooksPath "$HOME/.dotfiles/git-hooks"

# Make the 1Password SSH agent socket available to GUI apps like JetBrains Toolbox
mkdir -p "$HOME/Library/LaunchAgents"
ln -sfn "$HOME/.dotfiles/macos/launch-agents/com.maarten.ssh-auth-sock.plist" "$HOME/Library/LaunchAgents/com.maarten.ssh-auth-sock.plist"
launchctl bootout "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.maarten.ssh-auth-sock.plist" >/dev/null 2>&1 || true
launchctl bootstrap "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.maarten.ssh-auth-sock.plist"
launchctl kickstart -k "gui/$(id -u)/com.maarten.ssh-auth-sock"

# Update Homebrew recipes
brew update

# Install all our dependencies with bundle (See Brewfile)
brew tap homebrew/bundle
brew bundle --file ./Brewfile

# Set macOS preferences - we will run this last because this will reload the shell
source ./.macos
