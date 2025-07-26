#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")"/..

if [ "$#" -ne 1 ] && [ "$#" -ne 2 ]; then
  echo "masterと現在の状態のdiffをローカルで取る便利スクリプト（手元で実行することを想定）"
  echo "Usage: $0 [directory]"
  echo "Example: $0 traq"
  exit 1
fi

TARGET=""
if [ "$#" -ge 1 ]; then
  TARGET=$1
fi

# Create a unique worktree directory in tmp
WORKTREE_DIR=$(mktemp -d /tmp/manifest-master.XXXXXX)

# Cleanup function to remove worktree on exit or failure
cleanup() {
  if [ -d "$WORKTREE_DIR" ]; then
    git worktree remove --force "$WORKTREE_DIR" 2>/dev/null || true
    rm -rf "$WORKTREE_DIR"
  fi
}

# Set trap to cleanup on exit
trap cleanup EXIT

echo "==> Creating git worktree for master branch..."
git worktree add -f "$WORKTREE_DIR" master

echo "==> Building at master ..."
# Run build.sh in the worktree directory
(cd "$WORKTREE_DIR" && ./build.sh "$@")
rm -rf .built.master
mv "$WORKTREE_DIR"/.built .built.master

echo "==> Building at current ..."
./build.sh "$@"

echo "==> Calculating diff ..."
./diff.sh .built.master .built --omit-header
