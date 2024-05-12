#!/usr/bin/env sh

set -eux

# Install commands for deploy scripts
apk add --no-cache git openssh curl npm

exec /work/dev-ops-bot "$@"
