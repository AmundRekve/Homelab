#!/usr/bin/env bash
# Installs the repo's git hooks into .git/hooks (which git does not track).
# Safe to re-run: overwrites in place.
set -euo pipefail
root=$(git rev-parse --show-toplevel)
dest="$root/.git/hooks/pre-commit"
cat "$root/scripts/pre-commit" > "$dest"
chmod +x "$dest"
echo "Installed pre-commit hook -> .git/hooks/pre-commit"
if ! command -v gitleaks >/dev/null 2>&1; then
  echo "Tip: install gitleaks for deeper scanning (https://github.com/gitleaks/gitleaks)"
fi
