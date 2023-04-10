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

## bootstrap

1. Install k3s (or any other k8s installation)
   - In case of k3s, do not forget to disable default traefik installation, otherwise traefik pod will not be able to bind to port 80, 443
2. Install ArgoCD
   - `kubectl create ns argocd`
   - `kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.6.7/manifests/install.yaml`
     - refer to `./argocd/kustomization.yaml` for the current version
   - `kubectl port-forward svc/argocd-server -n argocd 8080:443`
3. Access localhost:8080
   - Get admin password from ` kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode && echo`
4. Add initial `applications` application
   - Add known hosts and connect repository
   - Add application (path: `applications`)
   - Sync applications
5. Access `cd.toki317.dev` and more
