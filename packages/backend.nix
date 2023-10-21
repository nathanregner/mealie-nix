{ mealie, mkPoetryApplication, defaultPoetryOverrides, python310Packages, ... }:
mkPoetryApplication {
  inherit (mealie) version meta;
  projectDir = mealie.src;

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

      pyrdfa3 = super.pyrdfa3.overrideAttrs (old: {
        # this package is dead
        # steal nixpkgs patches that fix the build
        inherit (python310Packages.pyrdfa3) patches postPatch;
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
      };
    in builtins.mapAttrs (package: build-requirements:
      (builtins.getAttr package super).overridePythonAttrs (old: {
        buildInputs = (old.buildInputs or [ ]) ++ (builtins.map (pkg:
          if builtins.isString pkg then builtins.getAttr pkg super else pkg)
          build-requirements);
      })) pypkgs-build-requirements));
}
