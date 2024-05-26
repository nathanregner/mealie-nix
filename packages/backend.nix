{
  inputs,
  mealie-nightly,
  python3,
  pkgs,
  lib,
  ...
}:
let
  inherit (inputs.poetry2nix.lib.mkPoetry2Nix { inherit pkgs; })
    mkPoetryApplication
    defaultPoetryOverrides
    ;
  pythonPkgs = python3.pkgs;
in
mkPoetryApplication {
  inherit (mealie-nightly) version meta;
  # make projectSource a derivation to avoid infinite recursion in `findGitIgnores` on nix 2.20+
  # https://github.com/nix-community/poetry2nix/blob/master/default.nix#L370
  # https://github.com/NixOS/nix/issues/9672
  projectDir = pkgs.runCommand "mealie-source" { } ''
    cp -r ${mealie-nightly.src} $out
  '';
  inherit python3;

  patches = [
    # patch alembic paths so DB migrations are runnable from the site-package installation
    ./alembic-migration-paths.patch
  ];
  postPatch = ''
    cp -r ./alembic ./mealie
    cp ./alembic.ini ./mealie/alembic.ini
  '';

  checkPhase = ''
    pytest --verbose
  '';

  overrides = defaultPoetryOverrides.extend (
    self: super:
    (
      let
        dummy = super.buildPythonPackage {
          pname = "dummy";
          version = "0.2.1";
          dontUnpack = true;
          doCheck = false;
          format = "other";
        };

        patchCargoVendorHash =
          drv: version: hash:
          drv.overridePythonAttrs (
            old:
            assert lib.assertMsg (
              old.version == version
            ) "patchCargoVendorHash version mismatch: ${old.version} != ${version}";
            {
              cargoDeps = pkgs.rustPlatform.fetchCargoTarball {
                inherit (old) src;
                name = "${old.pname}-${old.version}";
                inherit hash;
              };
            }
          );
      in
      {
        cython_0 = null;

        # these packages are not building properly... but they're not needed at runtime
        coveragepy-lcov = dummy; # test coverage
        mkdocs-material = dummy; # static doc generation
        mypy = dummy; # type checker
        ruff = dummy; # linter

        # use nixpkgs version to work around error
        # pillow_heif/_pillow_heif.c:1316:21: error: incompatible types when assigning to type ‘struct heif_error’ from type ‘int’
        inherit (pythonPkgs) pillow pillow-heif;

        bcrypt =
          patchCargoVendorHash super.bcrypt "4.1.3"
            "sha256-Uag1pUuis5lpnus2p5UrMLa4HP7VQLhKxR5TEMfpK0s=";

        watchfiles =
          patchCargoVendorHash super.watchfiles "0.18.1"
            "sha256-IWONA3o+2emJ7cKEw5xYSMdWzGuUSwn1B70zUDzj7Cw=";

        pyrdfa3 = super.pyrdfa3.overrideAttrs (old: {
          # this package is dead
          # steal nixpkgs patches that fix the build
          inherit (pythonPkgs.pyrdfa3) patches postPatch;
        });

        pytesseract = super.pytesseract.overrideAttrs (old: {
          # steal nixpkgs patches that include the tesseract package
          inherit (pythonPkgs.pytesseract) patches;
          buildInputs = old.buildInputs ++ pythonPkgs.pytesseract.buildInputs;
        });
      }
    )
    // (
      let
        pypkgs-build-requirements = {
          apprise = [
            "babel" # fixes a timeout when running setuptools... why does this work?
          ];
          beautifulsoup4 = [ "hatchling" ];
          html-text = [ "setuptools" ];
          jstyleson = [ "setuptools" ];
          mf2py = [ "setuptools" ];
          paho-mqtt = [ "hatchling" ];
          pydantic-to-typescript = [ "setuptools" ];
          recipe-scrapers = [ "setuptools-scm" ];
          types-python-slugify = [ "setuptools" ];
        };
      in
      builtins.mapAttrs (
        package: build-requirements:
        (builtins.getAttr package super).overridePythonAttrs (old: {
          buildInputs =
            (old.buildInputs or [ ])
            ++ (builtins.map (
              pkg: if builtins.isString pkg then builtins.getAttr pkg super else pkg
            ) build-requirements);
        })
      ) pypkgs-build-requirements
    )
  );
}
