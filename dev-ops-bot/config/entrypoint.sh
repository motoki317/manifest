#!/usr/bin/env sh

# Install commands for deploy scripts
apk add --no-cache git openssh curl npm

exec /work/dev-ops-bot "$@"
