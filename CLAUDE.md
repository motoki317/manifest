# TLS for routes

- Give a new IngressRoute `entryPoints: [websecure]` and no `tls` section. The `websecure` entrypoint turns TLS on and serves the shared `toki317.dev` + `*.toki317.dev` certificate, both set up in `traefik/`.
- Never add a per-host cert-manager Certificate. A per-host certificate publishes its hostname in public CT logs, while the shared one publishes only `*.toki317.dev`.
- Name each host one label under `toki317.dev`. The wildcard does not cover `foo.bar.toki317.dev`.
- The one exception: a route in `ns-apps` for a `*.ns.toki317.dev` host keeps the certificate that NeoShowcase (deployed by `ns-system/`) issues. Copy the `tls` section of `ns-apps/refactorhub.yaml`.
