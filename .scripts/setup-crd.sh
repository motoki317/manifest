#!/usr/bin/env bash

mkdir -p .crd
cd .crd || exit

# renovate:github-url
wget https://raw.githubusercontent.com/yannh/kubeconform/v0.7.0/scripts/openapi2jsonschema.py
export FILENAME_FORMAT='{fullgroup}-{kind}-{version}'

# renovate:github-url
python3 openapi2jsonschema.py https://raw.githubusercontent.com/argoproj/argo-cd/v3.1.8/manifests/install.yaml

# renovate:github-url
python3 openapi2jsonschema.py https://github.com/argoproj/argo-rollouts/releases/download/v1.8.3/install.yaml

# NOTE: In Argo Workflows, install.yaml contains only minimal CRDs; use full CRDs for validation:
# https://github.com/argoproj/argo-workflows/issues/11266
# renovate:github-url
kustomize build https://github.com/argoproj/argo-workflows//manifests/base/crds/full?ref=v3.7.2 > crd.yaml
python3 openapi2jsonschema.py crd.yaml && rm crd.yaml

# renovate:github-url
python3 openapi2jsonschema.py https://raw.githubusercontent.com/traefik/traefik/v3.5.3/docs/content/reference/dynamic-configuration/kubernetes-crd-definition-v1.yml

# renovate:github-url
python3 openapi2jsonschema.py https://github.com/cert-manager/cert-manager/releases/download/v1.19.0/cert-manager.yaml

# renovate:github-url
python3 openapi2jsonschema.py https://github.com/rancher/system-upgrade-controller/releases/download/v0.16.3/crd.yaml

# renovate:general datasource=helm depName=prometheus-operator-crds registryUrl=https://prometheus-community.github.io/helm-charts
helm template --include-crds --repo https://prometheus-community.github.io/helm-charts --set settings.clusterName=test prometheus-operator-crds --version "23.0.0" > crd.yaml
python3 openapi2jsonschema.py crd.yaml && rm crd.yaml

# renovate:general datasource=helm depName=victoria-metrics-k8s-stack registryUrl=https://victoriametrics.github.io/helm-charts/
helm template --include-crds --repo https://victoriametrics.github.io/helm-charts/ --set settings.clusterName=test victoria-metrics-k8s-stack --version "0.60.1" > crd.yaml
python3 openapi2jsonschema.py crd.yaml && rm crd.yaml
