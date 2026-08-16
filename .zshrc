# Modular zsh configuration.
# This file only loads the snippets in ~/.zshrc.d/ in lexical order.
# Add/remove/rename files there to enable or disable parts independently.

for _zshrc_file in ~/.zshrc.d/*.zsh(.N); do
  if [[ -r "$_zshrc_file" ]]; then
    source "$_zshrc_file" ||
      echo "zshrc: failed to load $_zshrc_file" >&2
  fi
done
unset _zshrc_file