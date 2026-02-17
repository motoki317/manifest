{
  description = "Kubernetes用manifest定義";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixpkgs-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    ksops-dry-run = {
      url = "github:motoki317/ksops-dry-run";
      flake = false;
    };
  };

  outputs =
    { flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];

      perSystem =
        {
          config,
          pkgs,
          system,
          ...
        }:
        let
          ksops = pkgs.buildGoModule {
            pname = "ksops";
            version = "0.4.0";
            src = inputs.ksops-dry-run;
            vendorHash = "sha256-Y9fKh08gIfRpuJDYwJpzex8oQdFdlmV8vz2RK7eKXvk=";
            proxyVendor = true;
            postInstall = ''
              mv $out/bin/ksops-dry-run $out/bin/ksops
            '';
          };
        in
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
          };

          devShells.default =
            pkgs.mkShell {
              packages =
                [
                  ksops
                ]
                ++ (with pkgs; [
                  age
                  curl
                  dyff
                  gh
                  gnugrep
                  gnused
                  just
                  k9s
                  kubeconform
                  kubernetes-helm
                  kustomize
                  python313
                  python313Packages.pyyaml
                  sops
                  yq-go
                ]);
            };
        };
    };
}
