{ inputs, system, lib, callPackage, runCommand, writeShellApplication
, python311Packages }:
let
  mealie = {
    src = inputs.mealie;
    version = inputs.mealie.rev;
    meta = with lib; {
      homepage = "https://nightly.mealie.io/";
      license = licenses.agpl3Only;
    };
  };
  frontend = callPackage ./frontend.nix { inherit mealie; };
  backend = callPackage ./backend.nix {
    inherit mealie;
    # TODO: use inputs' instead...
    inherit (inputs.poetry2nix.legacyPackages.${system})
      mkPoetryApplication defaultPoetryOverrides;
  };
in runCommand "mealie-nightly" {
  inherit (mealie) version meta;
  passthru = { inherit frontend backend; };
} ''
  mkdir -p $out/spa
  cp -r ${backend.dependencyEnv}/* $out
  ln -s ${frontend} $out/spa/static
''
