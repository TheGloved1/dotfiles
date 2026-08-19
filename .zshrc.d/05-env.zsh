env() {
  local env_file="${1:-$HOME/.env}"

  if [[ -f "$env_file" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
      line="${line%%#*}"
      line="$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
      [[ -z "$line" ]] && continue
      [[ "$line" != *"="* ]] && continue

      local var="${line%%=*}"
      local val="${line#*=}"

      [[ -z "$var" ]] && continue
      [[ "$var" != [[:alpha:]_]* ]] && continue

      [[ "${(P)var}" == "" ]] && export "$var=$val"
    done < "$env_file"
  fi
}

if [[ -f "$HOME/.env" ]]; then
  env "$HOME/.env"
fi

eval "$(direnv hook zsh)"