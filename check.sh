#!/usr/bin/env bash

set -euxo pipefail

contains () {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

skip_dirs=("auth-template/")
for directory in */; do
  if ! contains "$directory" "${skip_dirs[@]}"; then
    kustomize build ./"$directory" --enable-alpha-plugins --enable-exec | kubectl apply --validate=strict --dry-run=server -f -
  fi
done
