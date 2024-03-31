{ inputs, lib, callPackage, writeShellApplication, }:
let
  mealie-nightly = rec {
    src = inputs.mealie;
    version = src.rev;
    meta = with lib; {
      homepage = "https://nightly.mealie.io/";
      license = licenses.agpl3Only;
    };
  };
  frontend = callPackage ./frontend.nix { inherit mealie-nightly; };
  backend = callPackage ./backend.nix { inherit inputs mealie-nightly; };
in (writeShellApplication {
  name = "start";

  runtimeInputs = [ backend.dependencyEnv ];

  text = ''
    python -m mealie.db.init_db

    STATIC_FILES="${frontend}" \
    uvicorn mealie.app:app "$@"
  '';
}) // {
  passthru = { inherit frontend backend; };
}

