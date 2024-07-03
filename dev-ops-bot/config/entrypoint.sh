#!/usr/bin/env sh

set -eux

# Install commands for deploy scripts
echo "Installing misc deploy scripts ..."
apk add --no-cache git openssh curl npm

# Install kubectl
echo "Installing kubectl ..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/arm64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client

exec /work/dev-ops-bot "$@"
