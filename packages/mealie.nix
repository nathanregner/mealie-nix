{ inputs, lib, callPackage, writeShellApplication, }:
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
  backend = callPackage ./backend.nix { inherit mealie; };
in (writeShellApplication {
  name = "start";

  runtimeInputs = [ backend.dependencyEnv ];

  text = ''
    python -m mealie.db.init_db

    STATIC_FILES="${frontend}" \
    uvicorn mealie.app:app "$@"
  '';
}).overrideAttrs { passthru = { inherit frontend backend; }; }

