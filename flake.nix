{
  description = ''
    Nix flake packing Mealie, a self-hosted recipe manager.
    Specifically, this flake targets the mealie-next branch.

    See https://github.com/mealie-recipes/mealie/
  '';

  inputs = {
    mealie = {
      url = "github:mealie-recipes/mealie?ref=mealie-next";
      flake = false;
    };

    poetry2nix.url = "github:nix-community/poetry2nix";
  };

  outputs = { self, nixpkgs, mealie, poetry2nix }: {

    packages.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.hello;

    packages.x86_64-linux.default = self.packages.x86_64-linux.hello;

    # TODO: multiple systems
    # https://github.com/nix-community/poetry2nix#how-to-guides
    packages.x86_64-linux.backend = let
      p2n = poetry2nix.legacyPackages.x86_64-linux;

      pypkgs-build-requirements = {
        coveragepy-lcov = [ "poetry" ];
        html-text = [ "setuptools" ];
        jstyleson = [ "setuptools" ];
        mf2py = [ "setuptools" ];
        pydantic-to-typescript = [ "setuptools" ];
        types-python-slugify = [ "setuptools" ];
        # ruff = [ "maturin" ];
      };

    in p2n.mkPoetryApplication {
      projectDir = mealie;

      # groups = [ "default" ];
      # extras = [ "default" ];
      # python = nixpkgs.python3;

      overrides = p2n.defaultPoetryOverrides.extend (self: super:
        builtins.mapAttrs (package: build-requirements:
          (builtins.getAttr package super).overridePythonAttrs (old: {
            buildInputs = (old.buildInputs or [ ]) ++ (builtins.map (pkg:
              if builtins.isString pkg then builtins.getAttr pkg super else pkg)
              build-requirements);
          })) pypkgs-build-requirements);
    };
  };
}
