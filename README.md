# manifest

toki317.dev

## k3s installation

`/etc/rancher/k3s/config.yaml` (server)
```yaml
# default
cluster-cidr: 10.42.0.0/16
service-cidr: 10.43.0.0/16

disable:
  - traefik

kubelet-arg:
  - container-log-max-files=2
  - container-log-max-size=1Mi
  - config=/etc/rancher/k3s/kubelet-config.yaml

flannel-backend: wireguard-native

node-external-ip: <external ip>
# enable if multi-cloud cluster (i.e. nodes are accessible each other only from public ip)
# advertise-address: <external ip>
# flannel-external-ip: true

kube-controller-manager-arg:
  - node-cidr-mask-size-ipv4=22
```

`/etc/rancher/k3s/config.yaml` (agent)
```yaml
kubelet-arg:
  - container-log-max-files=2
  - container-log-max-size=1Mi
  - config=/etc/rancher/k3s/kubelet-config.yaml

node-external-ip: <external ip>
```

`/etc/rancher/k3s/kubelet-config.yaml` (server, agent)
```yaml
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration

maxPods: 250
```

https://k3s.io/
```sh
# Setup server
curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=latest sh -
# Setup agent
curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=latest K3S_URL=https://myserver:6443 K3S_TOKEN=mynodetoken sh -
```

## Secret management

Secret is encrypted with [sops](https://github.com/mozilla/sops#encrypting-using-age) using [age](https://github.com/FiloSottile/age).
This encrypted secret is then decrypted by ArgoCD by [ksops kustomize plugin](https://github.com/viaduct-ai/kustomize-sops#argo-cd-integration-).

### Setup

- Install age: https://github.com/FiloSottile/age#installation
- Install sops: https://github.com/mozilla/sops#1download

### Encrypting (no secret key required)

1. Write a secret.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-secret
  annotations:
    # Only add this annotation if secret name can be resolved by resources using kustomize nameReference
    # (no need to alter configuration if secret is only used by normal Deployments etc.)
    kustomize.config.k8s.io/needs-hash: "true"
stringData:
  my-secret-key: "my-super-secret-value"
```

2. Encrypt the secret: `./encrypt.sh secret.yaml`
   - File will be encrypted in-place.
3. Refer to encrypted file from `ksops.yaml` file.

```yaml
apiVersion: viaduct.ai/v1
kind: ksops
metadata:
  name: ksops
  annotations:
    config.kubernetes.io/function: |
      exec:
        path: ksops

# Refer to encrypted files here
files:
  - ./secrets/secret.yaml
```

4. Add the following to `kustomization.yaml`.

```yaml
generators:
  - ksops.yaml
```

### Decrypting / Editing

`./edit.sh filename`

### Adding / removing keys

1. Update `.sops.yaml`
2. Run `./updatekeys.sh filename`
   - Or `find . -type f -path '*/secrets/*' | xargs -n 1 ./updatekeys.sh` to update all

## bootstrap

1. Install k3s (or any other k8s installation)
   - In case of k3s, do not forget to disable default traefik installation, otherwise traefik pod will not be able to bind to port 80, 443
2. Install ArgoCD
   - `kubectl create ns argocd`
   - `kubectl apply -n argocd -f {{ latest version install.yaml URL referred to in ./argocd }}`
     - refer to `./argocd/kustomization.yaml` for the current version
3. Set up secret management
   - `age-keygen -o key.txt`
   - Set public key to `.sops.yaml`
   - `kubectl -n argocd create secret generic age-key --from-file=./key.txt`
   - `rm key.txt`
4. Access ArgoCD via port forwarding
   - `kubectl port-forward svc/argocd-server -n argocd 8124:443`
   - Get admin password from ` kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode && echo`
5. Add initial `applications` application
   - Add known hosts and connect repository
   - Add application (path: `applications`)
   - Sync applications
6. Access `cd.toki317.dev` and more
   - If for some reason accessing fails, port-forward with `kubectl port-forward svc/argocd-server -n argocd 8124:80`
