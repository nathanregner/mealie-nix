# Mealie-Nix

This flake outputs a Nix package and NixOS module for [Mealie Nightly](https://nightly.mealie.io/)

# Usage

Add an input to your flake:

```nix
{
  inputs = {
    mealie = {
      url = "github:nathanregner/mealie-nix";
      # leave commented to utilize the binary cache
      # inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
```

Enable the service in your nixosConfiguration:

```nix
{ inputs, ... }: {
  imports = [ inputs.mealie.nixosModules.default ];

  services.mealie-nightly.enable = true;

  # overlay the `mealie` package:
  nixpkgs.overlays = [ inputs.mealie.overlays.default ];

  # alternatively, specify the package explicitly:
  # services.mealie-nightly.package = inputs.mealie.packages.mealie-nightly;
}
```

Optionally, enable use of the publicly available [Cachix binary
cache](https://app.cachix.org/cache/nathanregner-mealie-nix):

```nix
{ ... }: {
  nix = {
    settings = {
      substituters = [ "https://nathanregner-mealie-nix.cachix.org" ];

      trusted-public-keys = [
        "nathanregner-mealie-nix.cachix.org-1:Ir3Z9UXjCcKwULpHZ8BveGbg7Az7edKLs4RPlrM1USM="
      ];
    };
  };
}
```
