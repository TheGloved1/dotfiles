#!/usr/bin/env bash
set -uo pipefail

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
	cat <<'EOF'
Usage: check-script-usage.sh

Scans $XDG_CONFIG_HOME (default ~/.config) for references to every script in
this directory. A script counts as "used" when:

	  1) any config/file outside this scripts dir (and not dormant) references
	     its basename, or
	  2) any *used* script calls it (transitively resolved to a fixpoint).

Scripts referenced nowhere are reported as orphan candidates, safe to delete.
Dormant config trees (e.g. waybar/, which is no longer autostarted) are excluded,
so a script referenced only from a dormant tree counts as an orphan.

No options.
EOF
	exit 0
fi

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"

# globs relative to CONFIG_DIR (applied via `cd`); skip backups, caches, IDEs,
# and dormant config trees whose references would otherwise mark dead scripts used.
EXCLUDE_GLOBS=(
	'--glob' '!hypr.bak/**'
	'--glob' '!hypr-backup*/**'
	'--glob' '!BraveSoftware/**'
	'--glob' '!ai.opencode.desktop/**'
	'--glob' '!Trae/**'
	'--glob' '!Devin/**'
	'--glob' '!opencode/**'
	'--glob' '!muse/**'
	'--glob' '!discord/**'
	'--glob' '!legcord/**'
	'--glob' '!node_modules/**'
	'--glob' '!*.dat'
	'--glob' '!waybar/**'
)

mapfile -t SCRIPTS < <(
	for f in "$SCRIPTS_DIR"/*; do
		[[ -f "$f" ]] || continue
		basename "$f"
	done
)
# drop the checker itself
for i in "${!SCRIPTS[@]}"; do
	[[ "${SCRIPTS[$i]}" == "$(basename "${BASH_SOURCE[0]}")" ]] && unset 'SCRIPTS[$i]'
done
SCRIPTS=("${SCRIPTS[@]}")

# references[name] = "consumer1 consumer2 ..." (CONFIG_DIR-relative, incl. scripts/)
declare -A refs=()

found() { # name -> true if *any* hit exists (excluding self)
	local name="$1" escaped pattern
	escaped="$(printf '%s' "$name" | sed 's/[.[\*^$()+?{|]/\\&/g')"
	pattern="\\b${escaped}\\b"
	local hits
	hits=$(
		cd "$CONFIG_DIR" || exit 1
		rg -l --hidden --no-ignore --follow \
			"${EXCLUDE_GLOBS[@]}" \
			-e "$pattern" \
			. 2>/dev/null || true
	)
	for h in $hits; do
		[[ "${h#./}" == "hypr/scripts/$name" ]] && continue # irrelevant self-hit
		return 0
	done
	return 1
}

for name in "${SCRIPTS[@]}"; do
	escaped="$(printf '%s' "$name" | sed 's/[.[\*^$()+?{|]/\\&/g')"
	pattern="\\b${escaped}\\b"
	while IFS= read -r h; do
		[[ -z "$h" ]] && continue
		h="${h#./}"
		[[ "$h" == "hypr/scripts/$name" ]] && continue
		refs["$name"]="${refs[$name]:-} $h"
	done < <(
		cd "$CONFIG_DIR" || exit 1
		rg -l --hidden --no-ignore --follow \
			"${EXCLUDE_GLOBS[@]}" \
			-e "$pattern" \
			. 2>/dev/null || true
	)
done

# transitive fixpoint: walk from externally-referenced scripts into scripts/
declare -A used=()
declare -A deps=() # caller -> callees it invokes (both inside this scripts dir)
for name in "${SCRIPTS[@]}"; do
	for h in ${refs[$name]:-}; do
		# h references $name; if h is inside this scripts dir it's a caller edge
		if [[ "$h" == hypr/scripts/* ]]; then
			caller="${h##*/}"
			[[ "$caller" == "$name" ]] && continue
			deps[$caller]+=" $name"
		else
			used[$name]=1 # externally referenced -> used
		fi
	done
done

changed=1
while ((changed)); do
	changed=0
	for name in "${!deps[@]}"; do
		((used[$name])) || continue
		for t in ${deps[$name]}; do
			if ((!used[$t])); then
				used[$t]=1
				changed=1
			fi
		done
	done
done

used_sorted=()
unused_sorted=()
for name in "${SCRIPTS[@]}"; do
	if ((used[$name])); then
		used_sorted+=("$name")
	else
		unused_sorted+=("$name")
	fi
done

bold=$'\033[1m'
green=$'\033[1;32m'
red=$'\033[1;31m'
reset=$'\033[0m'

printf '%sScripts referenced anywhere in %s:%s\n' "$bold" "$CONFIG_DIR" "$reset"
for name in "${used_sorted[@]}"; do
		printf '%s%-28s%s %s\n' "$green" "$name" "$reset" "${refs[$name]:-# }"
done

printf '\n%sOrphan candidates (no references anywhere):%s\n' "$bold" "$reset"
for name in "${unused_sorted[@]}"; do
	printf '  %s%s%s\n' "$red" "$name" "$reset"
done

printf '\n%s%3d / %3d scripts used%s\n' "$bold" "${#used_sorted[@]}" "${#SCRIPTS[@]}" "$reset"
printf 'Referenced: %d   Orphans: %d\n' "${#used_sorted[@]}" "${#unused_sorted[@]}"