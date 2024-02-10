{ mealie, mkYarnPackage, ... }:
mkYarnPackage {
  inherit (mealie) version meta;
  pname = "mealie-nightly-frontend";
  src = "${mealie.src}/frontend";

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
}
