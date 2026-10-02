#!/usr/bin/env bash
set -euo pipefail

# WeGoGen upstream sync
# origin   = your fork (whywhyel/MoneyPrinterTurbo)
# upstream = original project (harry0703/MoneyPrinterTurbo)

UPSTREAM_URL="https://github.com/harry0703/MoneyPrinterTurbo.git"
BRANCH="main"

cd "$(git rev-parse --show-toplevel)"

if [[ -n "$(git status --porcelain)" ]]; then
  echo "ERROR: Working tree is not clean."
  echo "Commit or stash your local changes before syncing upstream."
  exit 1
fi

if ! git remote get-url upstream >/dev/null 2>&1; then
  echo "Adding upstream remote..."
  git remote add upstream "$UPSTREAM_URL"
fi

echo "Fetching upstream..."
git fetch upstream "$BRANCH"

echo "Fetching your fork..."
git fetch origin "$BRANCH"

echo "Checking out $BRANCH..."
git checkout "$BRANCH"

# Bring local main up to date with commits already pushed to your fork.
git merge --ff-only "origin/$BRANCH"

# Create a recovery point before incorporating upstream changes.
BACKUP_BRANCH="wego-sync-backup-$(date +%Y%m%d-%H%M%S)"
git branch "$BACKUP_BRANCH"

if git merge-base --is-ancestor "upstream/$BRANCH" HEAD; then
  echo "Your branch already contains all upstream commits."
  echo "Nothing to merge."
  git push origin "$BRANCH"
  echo "Sync complete."
  exit 0
fi

echo "Merging upstream/$BRANCH into $BRANCH..."
if ! git merge --no-edit "upstream/$BRANCH"; then
  echo
  echo "UPSTREAM MERGE CONFLICT."
  echo "The merge has been stopped so you can resolve it safely."
  echo "Recovery branch: $BACKUP_BRANCH"
  echo
  echo "After resolving conflicts:"
  echo "  git add <resolved-files>"
  echo "  git commit"
  echo "  git push origin $BRANCH"
  echo
  echo "To abandon this merge instead:"
  echo "  git merge --abort"
  exit 2
fi

echo "Pushing updated WeGoGen fork..."
git push origin "$BRANCH"

echo
echo "========================================"
echo "WeGoGen upstream sync complete."
echo "Backup branch: $BACKUP_BRANCH"
echo "========================================"
