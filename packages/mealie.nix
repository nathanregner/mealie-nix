{ inputs, system, lib, callPackage, runCommand }:
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
    inherit (inputs.poetry2nix.legacyPackages.${system})
      mkPoetryApplication defaultPoetryOverrides;
  };
in runCommand "mealie-nightly" {
  inherit (mealie) version meta;
  passthru = { inherit frontend backend; };
} ''
  mkdir -p $out
  cp -r ${backend.dependencyEnv}/* $out

  mkdir -p $out/spa
  ln -s ${frontend} $out/spa/static
''
