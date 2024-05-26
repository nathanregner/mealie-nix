{
  description = ''
    Nix flake packing the nightly build of Mealie, a self-hosted recipe manager.
    https://github.com/mealie-recipes/mealie/
  '';

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
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

  outputs =
    inputs@{ self, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-linux"
        "x86_64-linux"
        "aarch64-darwin"
      ];
      imports = [ inputs.treefmt-nix.flakeModule ];

      perSystem =
        {
          config,
          system,
          inputs',
          pkgs,
          ...
        }:
        {
          packages = rec {
            mealie-nightly = pkgs.callPackage ./packages/mealie.nix { inherit inputs; };
            default = mealie-nightly;
          };

          devShells = {
            default = pkgs.mkShell {
              packages = [
                pkgs.nixfmt
                config.treefmt.build.wrapper
              ];
            };
          };

          treefmt = import ./treefmt.nix { inherit pkgs; };

          checks = {
            vm = pkgs.testers.runNixOSTest {
              name = "service-startup";

              nodes.machine =
                { ... }:
                {
                  imports = [ self.outputs.nixosModules.default ];
                  services.mealie-nightly.enable = true;
                };

              testScript = ''
                machine.start()

                machine.wait_for_unit("mealie-nightly.service")
                machine.wait_until_succeeds("curl http://localhost:9000/api/app/about", timeout=30)
              '';
            };
          };
        };
      flake = {
        nixosModules.default = import ./nixosModules self.outputs;

        overlays.default = (final: prev: { inherit (self.packages.${final.system}) mealie-nightly; });
      };
    };
}
