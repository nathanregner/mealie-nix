# Mealie-Nix

This flake outputs a Nix package and NixOS module for [Mealie Nightly](https://nightly.mealie.io/)

# Usage

Add an input to your flake:

```nix
{
  inputs = {
    mealie = {
      url = "github:nathanregner/mealie-nix";
      # inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
```

Enable the service in your nixosConfiguration:

```nix
{ inputs, ... }: {
  imports = [ inputs.mealie.nixosModules.default ];

  services.mealie.enable = true;

  # overlay the `mealie` package:
  nixpkgs.overlays = [ inputs.mealie.overlays.default ];

  # alternatively, specify the package explicitly:
  # services.mealie.package = inputs.mealie.packages.default;
}
```
