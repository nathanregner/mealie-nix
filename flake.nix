{
  description = ''
    Nix flake packing Mealie, a self-hosted recipe manager.
    Specifically, this flake targets the mealie-next branch.

    See https://github.com/mealie-recipes/mealie/
  '';

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";

    mealie = {
      url = "github:mealie-recipes/mealie?ref=mealie-next";
      flake = false;
    };
    maturin = {
      url = "github:PyO3/maturin";
      flake = false;
    };

    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, mealie, maturin, poetry2nix }: {

    # packages.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.hello;
    # packages.x86_64-linux.default = self.packages.x86_64-linux.hello;

    packages.x86_64-linux = let
      p2n = poetry2nix.legacyPackages.x86_64-linux;
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in {

      # maturin = pkgs.python311Packages.buildPythonPackage {
      #   pname = "maturin";
      #   version = maturin.rev;
      #   src = maturin;
      #   doCheck = false;
      #   propagatedBuildInputs = with pkgs.python311Packages; [
      #     tomli
      #     setuptools-rust
      #     # Specify dependencies
      #     # pkgs.python3Packages.numpy
      #   ];
      # };

      frontend = pkgs.yarn2nix-moretea.mkYarnPackage rec {
        pname = "mealie-frontned";
        version = mealie.rev;
        src = "${mealie}/frontend";

        configurePhase = ''
          runHook preConfigure

          # create a mutable copy of node_modules so .cache can be written to
          cp -r $node_modules node_modules
          chmod +w node_modules

          runHook postConfigure
        '';

        buildPhase = ''
          runHook preBuild

          # disable interactive nuxt telemetry prompt
          export NUXT_TELEMETRY_DISABLED=1

          export HOME=$(mktemp -d)
          yarn --offline generate

          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall

          mv dist $out

          runHook postInstall
        '';

        doDist = false;
        dontFixup = true;
      };

      backend-manual = pkgs.python3Packages.buildPythonPackage rec {
        pname = "pyFFTW";
        version = "0.9.2";
        format = "setuptools";

        src = mealie;

        buildInputs = [ pkgs.fftw pkgs.fftwFloat pkgs.fftwLongDouble ];

        propagatedBuildInputs = with pkgs.python3Packages; [ numpy scipy ];

        # Tests cannot import pyfftw. pyfftw works fine though.
        doCheck = false;
      };

      # TODO: multiple systems
      # https://github.com/nix-community/poetry2nix#how-to-guides
      backend = let
        pypkgs-build-requirements = {
          apprise = [
            "babel" # fixes a timeout when running setuptools... why does this work?
          ];
          html-text = [ "setuptools" ];
          jstyleson = [ "setuptools" ];
          mf2py = [ "setuptools" ];
          pydantic-to-typescript = [ "setuptools" ];
          recipe-scrapers = [ "setuptools-scm" ];
          types-python-slugify = [ "setuptools" ];
        };
      in (p2n.mkPoetryApplication {
        projectDir = mealie;
        # installPhase = ''
        #   echo 'hello';
        # '';
        overrides = p2n.defaultPoetryOverrides.extend (self: super:
          let
            dummy = super.buildPythonPackage rec {
              pname = "dummy";
              version = "0.0.0";
              dontUnpack = true;
              doCheck = false;
              format = "other";
            };
          in {
            # exclude problematic dev-only dependencies
            coveragepy-lcov = dummy; # test coverage
            mkdocs-material = dummy; # static doc generation
            ruff = dummy; # linter

            pyrdfa3 = super.pyrdfa3.overrideAttrs (old: {
              # this package is dead
              # steal nixpkgs patches that fix the build
              inherit (pkgs.python310Packages.pyrdfa3) patches postPatch;
            });
          } // builtins.mapAttrs (package: build-requirements:
            (builtins.getAttr package super).overridePythonAttrs (old: {
              buildInputs = (old.buildInputs or [ ]) ++ (builtins.map (pkg:
                if builtins.isString pkg then
                  builtins.getAttr pkg super
                else
                  pkg) build-requirements);
            })) pypkgs-build-requirements);
      });
    };
  };
}
