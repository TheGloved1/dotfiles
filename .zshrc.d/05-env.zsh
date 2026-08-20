env() {
  local env_file="${1:-$HOME/.env}"

  if [[ -f "$env_file" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
      line="${line%%#*}"
      line="${line#"${line%%[![:space:]]*}"}"
      line="${line%"${line##*[![:space:]]}"}"
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

_env_auto_load() {
  local dir="$PWD"
  while [[ "$dir" != "$HOME" && -n "$dir" ]]; do
    if [[ -f "$dir/.env" ]]; then
      env "$dir/.env"
    fi
    dir="${dir%/*}"
  done
  env "$HOME/.env"
}

chpwd_functions+=(_env_auto_load)
_env_auto_load