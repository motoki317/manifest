# manifest

(Based on [manifest-template](https://github.com/gmo-media/manifest-template))

A GitOps manifest repository with ArgoCD and validation on GitHub Actions.

See also: [infra-template](https://github.com/gmo-media/infra-template), [toki317.dev](https://github.com/motoki317/toki317.dev)

## Directory structure

ArgoCD's "root" Application loads `./dev/.applications` directory.
ApplicationSet discovers applications in `./dev/*`, where directory names
correspond to application name and namespace name.

```plaintext
manifest
├── dev
│   ├── .applications
│   │   ├── application-set.yaml
│   │   └── kustomization.yaml
│   └── my-app
│       ├── resource-1.yaml
│       ├── resource-2.yaml
│       └── kustomization.yaml
└── prod
    ├── .applications
    │   ├── application-set.yaml
    │   └── kustomization.yaml
    └── my-app
        ├── resource-1.yaml
        ├── resource-2.yaml
        └── kustomization.yaml
```

## Setup

### Setup k8s cluster

This repository assumes that you already own a Kubernetes cluster.
See [infra-template](https://github.com/gmo-media/infra-template) to get started.
Make sure you can run `kubectl apply` to deploy initial resources.

### Setup sops / age

1. Install [sops](https://github.com/getsops/sops) and [age](https://github.com/FiloSottile/age) locally.
2. Run `age-keygen -o key.txt` to generate a key pair.
    - `key.txt` is the private key, so you want to keep this secret.
    - Public key is printed to stdout. Set this to `.sops.yaml`.
3. Create a Secret named `age-key` in `argocd` namespace.
   `kubectl create secret generic age-key -n argocd --from-file=key.txt`
    - This is referenced from `./dev/argocd` manifest.
4. Place `key.txt` somewhere safe, or delete if you don't need it.
    - macOS recommended location: `$HOME/Library/Application Support/sops/age/keys.txt`
    - https://github.com/getsops/sops?tab=readme-ov-file#23encrypting-using-age

### Encrypting secrets

See `scripts/secret-*.sh` for various utility scripts to manipulate sops-encrypted files.

Most basic ones:
- `scripts/secret-encrypt.sh`: Encrypt a file.
- `scripts/secret-set-key.sh`: Set a key-value pair in an encrypted file.
- `scripts/secret-set-key-base64.sh`: Use this instead if your value has special characters.

You will NOT likely need to use `secret-decrypt.sh` or `secret-edit.sh` NOR need the private key locally,
given the fact that age encryption is asymmetric.
You could even commit encrypted files to a public repository.

After encrypting a file with `scripts/secret-encrypt.sh` (usually placed at `./dev/*/secrets/*.yaml`),
reference them via [ksops](https://github.com/viaduct-ai/kustomize-sops) file (usually placed at `./dev/*/ksops.yaml`).

```yaml
apiVersion: viaduct.ai/v1
kind: ksops
metadata:
  name: ksops
  annotations:
    config.kubernetes.io/function: |
      exec:
        path: ksops

files:
  # Comment these lines out if you don't need them yet
  - ./secrets/argocd-secret.yaml
  - ./secrets/notifications.yaml
```

For starters, you will likely need to set secret values in `./dev/argocd/secrets/argocd-secret.yaml`
and run `scripts/secret-encrypt.sh ./dev/argocd/secrets/argocd-secret.yaml` to encrypt the file.
Update `./dev/argocd/ksops.yaml` as needed.

### Install ArgoCD

See `./dev/argocd/values.yaml` to configure values.
You will likely need to change:
- `global.domain`: Your ArgoCD host.
- `configs.cm."oidc.config"`: OIDC configuration.
- `configs.rbac`: RBAC configuration.

Then:
1. Create `argocd` namespace: `kubectl create namespace argocd`
2. Apply the manifests: `scripts/build.sh ./dev/argocd | kubectl apply -f -`
3. Get `admin` password: `kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode && echo`
4. Port-forward to access temporarily at `localhost:8080`: `kubectl port-forward -n argocd svc/argocd-server 8080:8080`

### Connect the manifest repository

1. Create a GitHub App.
    - Minimal permission required: `Contents: Read-Only`
        - If you want to discover Applications based on PRs, you will also need `Pull-Requests: Read-Only`
    - Then, install this app into your manifest repository.
    - Take note of: GitHub App ID, installation ID (check the URL in your browser after installation!), and private key.
2. [Add repository from ArgoCD UI](https://argo-cd.readthedocs.io/en/stable/user-guide/private-repositories/#github-app-credential).
3. Create a "root" Application.
    - Replace `<your-org>/<your-repo>` in `application-set.yaml` with your actual repository names.
    - To prevent accidental deletion of all applications, `.syncPolicy.preserveResourcesOnDeletion` is set to `true` in
      `./dev/.applications/application-set.yaml`.
      To properly delete Application resources, you must first empty the Application directory - that is, set
      `resources: []` in `kustomization.yaml`.
      https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Application-Deletion/
4. Configure webhook on push from GitHub to `https://<your-argocd-url>/api/webhook`.
    - Set webhook "Content Type" to `application/json`.
    - https://argo-cd.readthedocs.io/en/stable/operator-manual/webhook/

### Setup ArgoCD notifications (Slack)

https://argo-cd.readthedocs.io/en/stable/operator-manual/notifications/services/slack/

1. Create a Slack App
    - Example app manifest:

        ```yaml
        display_information:
          name: ArgoCD (dev)
          description: ArgoCD (dev) notifications
          background_color: "#a36d00"
        features:
          bot_user:
            display_name: ArgoCD (dev)
            always_online: false
        oauth_config:
          scopes:
            bot:
              - chat:write
              - chat:write.customize
        settings:
          org_deploy_enabled: false
          socket_mode_enabled: false
          token_rotation_enabled: false
        ```

2. Obtain an OAuth Token (`xoxp-...`) and set it to `argocd-notifications-secret` (`./dev/argocd/secrets/notifications.yaml`).

    ```yaml
    apiVersion: v1
    kind: Secret
    metadata:
      name: argocd-notifications-secret
    
    stringData:
      slack-token: "replace-me-with-actual-token"
    ```

3. Run `scripts/secret-encrypt.sh ./dev/argocd/secrets/notifications.yaml` to encrypt the secret.
   Reference it from `./dev/argocd/ksops.yaml` accordingly.

## Best practices

### Use repository-local helm chart

When you need to share a set of manifest definitions between environments / applications,
place a helm chart under `./base` (or somewhere else).
`./base/traefik-forward-auth` is one such example.

Creating repository-local helm chart and simply rendering from `kustomization.yaml`
is *much* simpler and easier to maintain than using traditional "overlays" and "patches" using kustomize.

At first, kustomize patch seems to be simpler than Helm's template engine to patch a few locations - but
as your manifests grow, the patch set quickly blows up and it becomes almost impossible for newcomers
to understand what's going on.

Helm template engine gives you much more control and flexibility for managing common manifest definitions.
`values.yaml` is the "interface" between the common definition and your actual use-case.
Try to "design" these `values.yaml` to be as agnostic as possible to your actual use-cases.
There is no need to make *every* value configurable via `values.yaml` - this chart is only used locally after all -
try to keep `values.yaml` as simple as possible.

### Use third-party helm charts whenever possible

Similarly, you will likely want to rely on third-party helm charts as much as possible.

At first, you might want to reference a resource URL (e.g. `https://raw.githubusercontent.com/argoproj/argo-cd/refs/heads/master/manifests/install.yaml`)
from `kustomization.yaml` and maintain a few kustomize patches along, but for similar reasons as above,
kustomize patches and extra resources quickly become unmaintainable.

Try to rely on well-maintained helm charts whenever possible, so you write less code and get more work done.

Examples:
- ArgoCD: https://github.com/argoproj/argo-helm/blob/main/charts/argo-cd
- victoria-metrics-k8s-stack (all-in-one monitoring solution): https://github.com/VictoriaMetrics/helm-charts/tree/master/charts/victoria-metrics-k8s-stack
- Self-host Sentry (in case you prefer self-hosting): https://github.com/sentry-kubernetes/charts
- OpenCost (for tracking resource costs): https://github.com/opencost/opencost-helm-chart/tree/main/charts/opencost

### Do not hesitate to push to `main` frequently

This repository is intended to be used with ArgoCD with GitOps principles.
Create a PR, wait for CI to pass, merge, and repeat quickly.
Even if you break something, just do `git revert && git push` and you're all good (for most cases).

When you have a commit history and this GitOps repository as the "single source of truth" for your infrastructure,
rollbacks and post-mortem investigations become *much* easier.

### Do not use `kubectl` to manipulate cluster states

For similar reasons as well - keep this repository as the "single source of truth" for your infrastructure.

Use `kubectl` or [k9s](https://k9scli.io/) only for inspecting cluster states.
`alias k9s-ro='k9s --readonly'` is one good alias to use.
When you need to make changes to the cluster, always make changes via this repository.

### Use centralized SSO (single-sign-on)

`./dev/auth` and `./dev/traefik` gives you centralized SSO and allow apps to use header authentication
via [traefik ForwardAuth middlewares](https://doc.traefik.io/traefik/middlewares/http/forwardauth/).

[traPtitech/traefik-forward-auth](https://github.com/traPtitech/traefik-forward-auth) gives you a simple, yet powerful
SSO and header authentication solution via OAuth2 or OIDC.
This assumes you already have an identity provider (IdP).
We recommend using Google's OAuth2 App for starters.

Configure "groups" in `./base/traefik-forward-auth/values.yaml`.
(see the actual templates for more details for how this is done)

```yaml
groups:
  admin:
    - admin@example.com
```

This will generate `auth-group-${group_name}` middlewares for each group,
so reference them in your IngressRoute definitions.

```yaml
    - kind: Rule
      match: Host(`traefik.example.com`)
      middlewares:
        - name: auth-group-admin
          namespace: auth
      services:
        - kind: TraefikService
          name: dashboard@internal
```

This will also pass `X-Forwarded-User` and `X-Forwarded-Sub` headers to your application.
If your application supports header authentication (a.k.a "proxy authentication"), configure them accordingly.

For example, [Grafana supports proxy authentication](https://grafana.com/docs/grafana/latest/setup-grafana/configure-security/configure-authentication/auth-proxy/).
