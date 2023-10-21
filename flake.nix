{
  description = ''
    Nix flake packing the nightly build of Mealie, a self-hosted recipe manager.
    https://github.com/mealie-recipes/mealie/
  '';

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flakelight = {
      url = "github:accelbread/flakelight";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mealie = {
      url = "github:mealie-recipes/mealie?ref=mealie-next";
      flake = false;
    };

    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ flakelight, ... }:
    flakelight ./. {
      inherit inputs;

      packages = rec {
        mealie = import ./packages/mealie.nix;
        default = mealie;
      };

      # packages = rec {
      #   mealie-nightly = { callPackage }:
      #     callPackage ./pkgs { inherit inputs; };
      #   default = mealie-nightly;
      # };

      # nixosModules.default = args: ./modules/_default.nix;
    };
}
