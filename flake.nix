{
  description = ''
    Nix flake packing the nightly build of Mealie, a self-hosted recipe manager.
    https://github.com/mealie-recipes/mealie/
  '';

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";

    mealie = {
      url = "github:mealie-recipes/mealie?ref=mealie-next";
      flake = false;
    };
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, ... }:
    let
      inherit (nixpkgs) lib;
      forAllSystems = lib.genAttrs [
        "aarch64-darwin"
        "aarch64-linux"
        "i686-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
      forAllSupportedSystems = lib.genAttrs [ "x86_64-linux" ];
    in {
      packages = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in rec {
          mealie-nightly =
            pkgs.callPackage ./packages/mealie.nix { inherit inputs; };
          default = mealie-nightly;
        });

      nixosModules.default = ./nixosModules;

      overlays.default = (final: prev: {
        mealie-nightly = self.packages.${final.system}.mealie-nightly;
      });

      devShells = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in {
          default = pkgs.mkShell {
            packages = [
              pkgs.nixfmt
              (pkgs.callPackage ./packages/shell/pin-github-action.nix { })
            ];
          };
        });

      checks = forAllSupportedSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ self.overlays.default ];
          };
        in {
          vm = pkgs.testers.runNixOSTest {
            name = "service-startup";

            nodes.machine = { ... }: {
              imports = [ self.outputs.nixosModules.default ];
              services.mealie-nightly.enable = true;
            };

            testScript = ''
              machine.start()

              machine.wait_for_unit("mealie-nightly.service")
              machine.wait_until_succeeds("curl http://localhost:9000/api/app/about", timeout=30)
            '';
          };
        });
    };
}
