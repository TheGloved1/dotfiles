#!/bin/bash
# Purge current git repo to before first commit, keep working tree files, remove tags
# Requires confirmation with preview

set -euo pipefail

# Check if we are in a git repo
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "Error: Not a git repository." >&2
  exit 1
fi

current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "HEAD")
upstream_ref=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || true)

echo "=== PURGE PREVIEW ==="
echo ""
echo "Current branch: $current_branch"
echo ""
echo "Remotes:"
git remote -v || echo "(none)"
echo ""
echo "BEFORE PURGE"
echo "Current commit history (last 10):"
git log --oneline -n 10 2>/dev/null || echo "(no commits)"
echo ""
echo "Current tags:"
git tag --list || echo "(none)"
echo ""
echo "Tracked files in working tree:"
git ls-files | head -n 200
echo ""
echo "Untracked files:"
git ls-files --others --exclude-standard | head -n 200
echo ""
echo "=== AFTER PURGE PREVIEW ==="
echo "Branch: $current_branch"
echo "Remotes: unchanged"
echo ""
echo "git log --oneline will be:"
echo "  <new-sha> initial"
echo ""
echo "git tag --list will be:"
echo "  (none)"
echo ""
echo "Files that will be in the new 'initial' commit:"
git ls-files | head -n 200
echo ""
echo "Working tree files will remain unchanged."
echo ""
echo "Commits to be removed: $(git rev-list --count HEAD 2>/dev/null || echo 0)"
echo "Tags to be removed: $(git tag --list | wc -l | tr -d ' ')"
echo ""
echo "Note: remote URLs are preserved. Push will require --force due to rewritten history."
echo ""
read -rp "Proceed with purge? [y/N] " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

echo "Purging..."

# Remove all tags locally
git tag -l | xargs -r git tag -d

# Expire reflogs
git reflog expire --expire=now --all

# Remove backup refs
git for-each-ref --format='%(refname)' refs/original/ 2>/dev/null | xargs -n1 git update-ref -d 2>/dev/null || true

# Create orphan branch and commit current working tree
temp_branch="_purge_temp_$$"
git checkout --orphan "$temp_branch"

# Stage all files (keep working tree)
git add -A

# Commit as initial
git commit -m "initial" || git commit --allow-empty -m "initial"

# Delete old branch refs except protected ones
# Remove all branches
for b in $(git branch --format='%(refname:short)'); do
  if [ "$b" != "$temp_branch" ]; then
    git branch -D "$b" 2>/dev/null || true
  fi
done

# Rename temp to original branch name
git branch -m "$temp_branch" "$current_branch"

# Restore upstream tracking if it existed
if [ -n "$upstream_ref" ]; then
  # upstream_ref is like origin/main
  git branch --set-upstream-to="$upstream_ref" "$current_branch" 2>/dev/null || true
fi

# Cleanup
git reflog expire --expire=now --all
git gc --prune=now --aggressive

echo "Git repo purged. All history and tags removed. New initial commit created on $current_branch."
echo "Remotes preserved. Push will require --force due to rewritten history."