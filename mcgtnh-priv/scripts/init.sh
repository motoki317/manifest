#!/usr/bin/env sh

set -eux

# Use mounted service account token for connecting local cluster
# ref: https://www.ibm.com/docs/en/cloud-private/3.2.x?topic=kubectl-using-service-account-tokens-connect-api-server
echo "Configuring kubectl to use service account token ..."
kubectl config set-cluster cfc --server=https://kubernetes.default --certificate-authority=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
kubectl config set-context cfc --cluster=cfc
kubectl config set-credentials user --token="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"
kubectl config set-context cfc --user=user
kubectl config use-context cfc

# Set default namespace
echo "Setting default namespace ..."
kubectl config set-context cfc --namespace=mcgtnh-priv
