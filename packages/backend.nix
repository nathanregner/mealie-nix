{ inputs, mealie, python3, pkgs, ... }:
let
  inherit (inputs.poetry2nix.lib.mkPoetry2Nix { inherit pkgs; })
    mkPoetryApplication defaultPoetryOverrides;
  pythonPkgs = python3.pkgs;

in mkPoetryApplication {
  inherit (mealie) version meta;
  projectDir = mealie.src;
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

  overrides = defaultPoetryOverrides.extend (self: super:
    (let
      dummy = super.buildPythonPackage {
        pname = "dummy";
        version = "0.2.1";
        dontUnpack = true;
        doCheck = false;
        format = "other";
      };
    in {
      # these packages are not building properly... but they're not needed at runtime
      coveragepy-lcov = dummy; # test coverage
      mkdocs-material = dummy; # static doc generation
      mypy = dummy; # type checker
      ruff = dummy; # linter

      # complains about mismatched cargoVendorHash... just use nixpkgs version for now
      inherit (pythonPkgs) orjson;

      inherit (pythonPkgs) lxml rapidfuzz;

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
    }) // (let
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
    in builtins.mapAttrs (package: build-requirements:
      (builtins.getAttr package super).overridePythonAttrs (old: {
        buildInputs = (old.buildInputs or [ ]) ++ (builtins.map (pkg:
          if builtins.isString pkg then builtins.getAttr pkg super else pkg)
          build-requirements);
      })) pypkgs-build-requirements));
}

