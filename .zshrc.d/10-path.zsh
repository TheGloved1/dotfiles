# PATH setup
# Add ~/.local/bin to PATH (for oh-my-posh and other local binaries)
export PATH="$HOME/.local/bin:$PATH"
export PATH=$PATH:/usr/local/bin

# env: idempotently prepends ~/.local/bin if missing
. "$HOME/.local/share/../bin/env"