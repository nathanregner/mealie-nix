{ mealie, poetry2nix, python310Packages, fetchurl, ... }:
let inherit (poetry2nix) mkPoetryApplication defaultPoetryOverrides;
in mkPoetryApplication {
  inherit (mealie) version meta;
  projectDir = mealie.src;

  patches = [
    # patch alembic paths so DB migrations are runnable from the site-package installation
    ./alembic-migration-paths.patch
    # make sure we're including a working version of tesseract
    ./enable-ocr-unit-tests.patch
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
        version = "0.0.0";
        dontUnpack = true;
        doCheck = false;
        format = "other";
      };
    in {
      # these packages are not building properly... but they're not needed at runtime
      coveragepy-lcov = dummy; # test coverage
      mkdocs-material = dummy; # static doc generation
      ruff = dummy; # linter
      mypy = dummy; # type checker

      orjson = python310Packages.orjson;

      pyrdfa3 = super.pyrdfa3.overrideAttrs (old: {
        # this package is dead
        # steal nixpkgs patches that fix the build
        inherit (python310Packages.pyrdfa3) patches postPatch;
      });

      pytesseract = super.pytesseract.overrideAttrs (old: {
        # steal nixpkgs patches that include the tesseract package
        inherit (python310Packages.pytesseract) patches;
        buildInputs = old.buildInputs
          ++ python310Packages.pytesseract.buildInputs;
      });
    }) // (let
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
        beautifulsoup4 = [ "hatchling" ];
      };
    in builtins.mapAttrs (package: build-requirements:
      (builtins.getAttr package super).overridePythonAttrs (old: {
        buildInputs = (old.buildInputs or [ ]) ++ (builtins.map (pkg:
          if builtins.isString pkg then builtins.getAttr pkg super else pkg)
          build-requirements);
      })) pypkgs-build-requirements));
}

