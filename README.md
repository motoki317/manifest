# manifest

toki317.dev

## k3s installation

`/etc/systemd/system/k3s.service.env`
```
K3S_KUBECONFIG_MODE="644"
```

`/etc/rancher/k3s/config.yaml`
```yaml
# default
cluster-cidr: 10.42.0.0/16
# default
service-cidr: 10.43.0.0/16
disable:
  - traefik
kubelet-arg:
  - container-log-max-files=2
  - container-log-max-size=1Mi
```

https://k3s.io/
```sh
curl -sfL https://get.k3s.io | sh -
sudo systemctl enable k3s
```

## Secret management

Secret is encrypted with [sops](https://github.com/mozilla/sops#encrypting-using-age) using [age](https://github.com/FiloSottile/age).
This encrypted secret is then decrypted by ArgoCD by [ksops kustomize plugin](https://github.com/viaduct-ai/kustomize-sops#argo-cd-integration-).

### Setup

- Install age: https://github.com/FiloSottile/age#installation
- Install sops: https://github.com/mozilla/sops#1download

### Encrypting (no secret key required)

1. `./encrypt.sh filename`
   - File will be encrypted in-place.
2. Refer to encrypted file from `ksops.yaml` generator.

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

3. Add the following to `kustomization.yaml`.

```yaml
generators:
  - ksops.yaml
```

### Decrypting

`./decrypt.sh filename`

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
