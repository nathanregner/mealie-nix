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
      # inputs.nixpkgs.follows = "nixpkgs";
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

      # TODO: multiple systems
      # https://github.com/nix-community/poetry2nix#how-to-guides
      backend = let
        pypkgs-build-requirements = {
          html-text = [ "setuptools" ];
          jstyleson = [ "setuptools" ];
          mf2py = [ "setuptools" ];
          pydantic-to-typescript = [ "setuptools" ];
          recipe-scrapers = [ "setuptools-scm" ];
          types-python-slugify = [ "setuptools" ];
        };
      in (p2n.mkPoetryApplication {
        projectDir = mealie;
        python = pkgs.python311;
        # groups = [ ];
        # extras = [ ];
        installPhase = ''
          echo 'hello';
        '';
        overrides = p2n.defaultPoetryOverrides.extend (self: super:
          {
            inherit (pkgs.python311Packages)
            # #   apprise extruct mkdocs-material recipe-scrapers requests fastapi
            #   apprise 
              mkdocs-material mypy extruct recipes-scrapers
              #
              isodate urllib3;

            pyyaml = pkgs.python311Packages.pyyaml.overridePythonAttrs
              (prev: rec {
                version = "6.0.1";

                src = pkgs.fetchFromGitHub {
                  owner = "yaml";
                  repo = "pyyaml";
                  rev = version;
                  hash = "sha256-YjWMyMVDByLsN5vEecaYjHpR1sbBey1L/khn4oH9SPA=";
                };
              });

            # alias problematic packages that we're not going to use during build anyway
            # TODO: Find a way to exclude these
            ruff = pkgs.python311Packages.apprise; # linter
            coveragepy-lcov = pkgs.python311Packages.apprise;
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
