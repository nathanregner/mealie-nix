{
  description = ''
    Nix flake packing the nightly build of Mealie, a self-hosted recipe manager.
    https://github.com/mealie-recipes/mealie/
  '';

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
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

  outputs = inputs@{ flakelight, nixpkgs, ... }:
    flakelight ./. {
      inherit inputs;

      packages = rec {
        mealie = import ./packages/mealie.nix;
        default = mealie;
      };

      nixosModules.default = ./nixosModules;

      formatters = { "*.nix" = nixpkgs.lib.mkForce "nixfmt"; };

      devShells.default = { pkgs }:
        pkgs.mkShell { packages = with pkgs; [ nixfmt ]; };

      checks.vm = { inputs, inputs', outputs, outputs', pkgs, lib, ... }:
        let nixos-lib = import (inputs.nixpkgs + "/nixos/lib") { };
        in nixos-lib.runTest {
          imports = [ ./vm.nix ];
          hostPkgs = pkgs;
          node.specialArgs = { inherit outputs outputs'; };
        };
    };
}
