# Add directories to the PATH and prevent to add the same directory multiple times upon shell reload.
add_to_path() {
  if [[ -d "$1" ]] && [[ ":$PATH:" != *":$1:"* ]]; then
    export PATH="$1:$PATH"
  fi
}

# Load dotfiles binaries
add_to_path "$DOTFILES/bin"

# Load global Composer tools
add_to_path "$HOME/.composer/vendor/bin"

# Load global Node installed binaries
add_to_path "$HOME/.node/bin"

# Use project specific binaries before global ones
add_to_path "vendor/bin"
add_to_path "node_modules/.bin"

if [[ $USER == "maarten" ]]; then
    export NVM_DIR="$HOME/.nvm"
    # Load nvm (Node Version Manager)
    [ -s "$(brew --prefix nvm)/nvm.sh" ] && \. "$(brew --prefix nvm)/nvm.sh"
    [ -s "$(brew --prefix nvm)/etc/bash_completion.d/nvm" ] && \. "$(brew --prefix nvm)/etc/bash_completion.d/nvm"
    export PHP_IDE_CONFIG="serverName=localhost"
    export PATH="/opt/homebrew/opt/mysql-client/bin:$PATH"
fi

# opencode
add_to_path "$HOME/.opencode/bin"
add_to_path "$HOME/.local/bin"